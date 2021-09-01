{ rustPlatform, fetchFromGitHub, llvmPackages_latest, linuxHeaders, pkgsMusl, rust, stdenv }:
let
  hostTarget = rust.toRustTargetSpec stdenv.hostPlatform;
  muslTarget = rust.toRustTargetSpec pkgsMusl.stdenv.hostPlatform;
in
rustPlatform.buildRustPackage rec {
  pname = "firecracker";
  version = "0.24";
  src = fetchFromGitHub {
    owner = "ease-lab";
    repo = "firecracker";
    rev = "v${version}_user_page_faults";
    sha256 = "sha256-kef1p4jsqGU2kiovTFCfu6GzK88bS6ZqV+d8BIfUqTE=";
  };
  buildInputs = [
    linuxHeaders
  ];
  LIBCLANG_PATH = "${llvmPackages_latest.libclang.lib}/lib";
  patches = [
    ./0001-disable-seccomp-by-default.patch
  ];
  buildPhase = ''
    runHook preBuild
    export BINDGEN_EXTRA_CLANG_ARGS=$NIX_CFLAGS_COMPILE
    cargo build --frozen --release --target=${muslTarget} --target-dir=target
    cargo build -p jailer --frozen --release --target=${muslTarget} --target-dir=target
    mv target/${muslTarget} target/${hostTarget}
    runHook postBuild
  '';
  shellHook = ''
    export BINDGEN_EXTRA_CLANG_ARGS=$NIX_CFLAGS_COMPILE
  '';
  cargoSha256 = "sha256-NqXwrfmT7gxqbjpwB+F9lz2M6aOuU0t8fwjifTdfe9M=";
}
