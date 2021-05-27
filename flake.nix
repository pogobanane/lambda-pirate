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
    flake-utils.lib.eachDefaultSystem (system: let
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
    in {
      packages = rec {
        firecracker = pkgs.callPackage ./nix/firecracker.nix {
          inherit rustPlatform;
        };
        firecracker-kernel = pkgs.callPackage ./nix/firecracker-kernel.nix {
          inherit firecracker;
        };
        firecracker-containerd = pkgs.callPackage ./nix/firecracker-containerd.nix {};
        firecracker-ctr = pkgs.callPackage ./nix/firecracker-ctr.nix {};
        firecracker-default-rootfs = pkgs.callPackage ./nix/firecracker-default-rootfs.nix {
          inherit firecracker-containerd;
        };
      };
    });
}
