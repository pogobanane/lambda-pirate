{ pkgs, buildGoModule, fetchgit, fetchpatch }:

buildGoModule rec {
  pname = "vhive";
  #version = "v" + "1.2";
  #rev = "v${version}";
  #rev = "fb7971ce539dd6ce8dd81a42d70dc5a53833c858";
  version = "pogobanane-fork";
  #ldflags = "-w";

  # not fetchFromGitHub to skip git-lfs assets
  src = fetchgit {
    url = "https://github.com/pogobanane/vhive";
    rev = "6621a95c41c28125127b540d3d275aeeca581e06";
    sha256 = "sha256-42GbbZr8pVwZvr0I699sIu7S9CH77yjIRWgbyFyh320=";
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

  patches = [
    #./0001-increase-vm-start-timeout.patch
    ##./0001-set-upper-limit-for-autoscaling.patch
    ##./0001-enable-autoscaling-limits.patch
    #./0001-limit-autoscaling-for-workloads.patch
    #./0001-limit-autoscaling-min.patch
    #./0001-debug-print-guest-IPs.patch
  ];

  deleteVendor = true;
  #vendorSha256 = null;
  vendorSha256 = "sha256-BDL+2MKOLALy3aRUy/FTZ3nutOIMUFMtVJA+AJMBfdU=";
}
