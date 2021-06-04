{
  description = "A very basic flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, fenix }:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          fenixPkgs = fenix.packages.${system};
          rustToolchain = with fenixPkgs; combine [
            stable.cargo
            stable.rustc
            stable.rust-std
            targets.x86_64-unknown-linux-musl.stable.rust-std
          ];
          rustPlatform = pkgs.makeRustPlatform {
            cargo = rustToolchain;
            rustc = rustToolchain;
          };
          ownPkgs = self.packages.${pkgs.system};
        in
        {
          packages = rec {
            firecracker = pkgs.callPackage ./nix/pkgs/firecracker.nix {
              inherit rustPlatform;
            };
            firecracker-kernel = pkgs.callPackage ./nix/pkgs/firecracker-kernel.nix {
              inherit firecracker;
            };
            firecracker-containerd = pkgs.callPackage ./nix/pkgs/firecracker-containerd { };
            firecracker-ctr = pkgs.callPackage ./nix/pkgs/firecracker-ctr.nix { };
            firecracker-rootfs = pkgs.callPackage ./nix/pkgs/firecracker-rootfs {
              inherit firecracker-containerd runc-static;
            };
            runc-static = pkgs.callPackage ./nix/pkgs/runc-static.nix {};
            vhive = pkgs.callPackage ./nix/pkgs/vhive.nix {};
            istioctl = pkgs.callPackage ./nix/pkgs/istioctl.nix {};
            kn = pkgs.callPackage ./nix/pkgs/kn.nix {};
            vhive-examples = pkgs.callPackage ./nix/pkgs/vhive-examples.nix {
              inherit vhive kn;
            };
          };
          devShell = pkgs.mkShell {
            buildInputs = [
              pkgs.kubectl
              pkgs.envsubst
              pkgs.openssl
              pkgs.skopeo
              ownPkgs.istioctl
              ownPkgs.kn
            ];
            shellHook = ''
              if [ -n $KUBECONFIG ]; then
                export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
              fi
            '';
          };
        }) // {
      nixosModules = {
        firecracker-pkgs = { ... }: {
          nixpkgs.config.packageOverrides = pkgs:
            let
              firecrackerPackages = self.packages.${pkgs.system};
            in
            {
              inherit (firecrackerPackages)
                firecracker-kernel
                firecracker-containerd
                firecracker-rootfs
                firecracker-ctr;
            };
        };
        k3s = { ... }: {
          imports = [
            self.nixosModules.firecracker-containerd
            ./nix/modules/k3s.nix
          ];
        };
        vhive = { ... }: {
          imports = [
            ({...}: {
              nixpkgs.config.packageOverrides = pkgs: {
                inherit (self.packages.${pkgs.system}) vhive;
              };
            })
            ./nix/modules/vhive.nix
          ];
        };
        firecracker-containerd = { ... }: {
          imports = [
            self.nixosModules.firecracker-pkgs
            ./nix/modules/firecracker-containerd.nix
          ];
        };
      };
    };
}
