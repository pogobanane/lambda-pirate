{ pkgs, buildGoModule, fetchgit, fetchpatch }:

buildGoModule rec {
  pname = "vhive";
  #version = "v" + "1.2";
  #rev = "v${version}";
  version = "pogobanane-fork";
  #ldflags = "-w";

  # not fetchFromGitHub to skip git-lfs assets
  src = fetchgit {
    url = "https://github.com/pogobanane/vhive";
    rev = "e67a475bbf643dbbcb361bac66b5bb010750f28e";
    sha256 = "sha256-1btY2Ze6hq3F/r8OjkySPmlYwcNhSts4m5hphKJkLfc=";
  };
  # The following src is quite useless, because:
  # - it only works with --impure
  # - it is not a cleanbuild because the user has to run go mod vendor before
  # - go mod vendor does not work in preBuild = ''foo'';
  # => one must run go mod vendor before using this vhive.nix
  # => don't use this vhive.nix for local dev builds
  # src = /home/peter/vhive;

  subPackages = [ "." ];

  # does not work in sandbox
  doCheck = false;
  
  nativeBuildInputs = [
    pkgs.just
    pkgs.go-langserver
    pkgs.delve
    pkgs.skopeo
  ];

  deleteVendor = true;
  vendorSha256 = "sha256-BDL+2MKOLALy3aRUy/FTZ3nutOIMUFMtVJA+AJMBfdU=";
}
