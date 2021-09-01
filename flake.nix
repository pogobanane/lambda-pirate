{
  description = "A very basic flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, fenix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ]
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
          deployPkgs = [
            pkgs.kubectl
            pkgs.coreutils
            pkgs.nettools
            pkgs.envsubst
            pkgs.openssl
            pkgs.gnused
            pkgs.curl
            ownPkgs.istioctl
            pkgs.curl
          ];
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
            runc-static = pkgs.callPackage ./nix/pkgs/runc-static.nix { };
            vhive = pkgs.callPackage ./nix/pkgs/vhive.nix { };
            istioctl = pkgs.callPackage ./nix/pkgs/istioctl.nix { };
            kn = pkgs.callPackage ./nix/pkgs/kn.nix { };
            vhive-examples = pkgs.callPackage ./nix/pkgs/vhive-examples.nix {
              inherit vhive kn;
            };
            deploy-knative = pkgs.writeShellScriptBin "deploy-knative" ''
              export PATH=${pkgs.lib.makeBinPath deployPkgs}
              exec ${pkgs.gnumake}/bin/make -C ${./knative} deploy
            '';
          };
          devShell = pkgs.mkShell {
            buildInputs = deployPkgs ++ [
              pkgs.skopeo
              pkgs.just
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
      nixosConfigurations = {
        example-host = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.knative
            self.nixosModules.vhive
            { boot.isContainer = true; }
          ];
        };
      };
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
        knative = { ... }: {
          imports = [
            {
              nixpkgs.config.packageOverrides = pkgs: {
                inherit (self.packages.${pkgs.system}) deploy-knative;
              };
            }
            self.nixosModules.k3s
            ./nix/modules/knative.nix
          ];
        };
        k3s = { ... }: {
          imports = [
            self.nixosModules.firecracker-containerd
            ./nix/modules/k3s.nix
          ];
        };
        vhive = { ... }: {
          imports = [
            ({ ... }: {
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
