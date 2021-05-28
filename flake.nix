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
        in
        {
          packages = rec {
            firecracker = pkgs.callPackage ./nix/pkgs/firecracker.nix {
              inherit rustPlatform;
            };
            firecracker-kernel = pkgs.callPackage ./nix/pkgs/firecracker-kernel.nix {
              inherit firecracker;
            };
            firecracker-containerd = pkgs.callPackage ./nix/pkgs/firecracker-containerd.nix { };
            firecracker-ctr = pkgs.callPackage ./nix/pkgs/firecracker-ctr.nix { };
            firecracker-rootfs = pkgs.callPackage ./nix/pkgs/firecracker-rootfs.nix {
              inherit firecracker-containerd;
            };
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
        firecracker-containerd = { ... }: {
          imports = [
            self.nixosModules.firecracker-pkgs
            ./nix/modules/firecracker-containerd.nix
          ];
        };
      };
    };
}
