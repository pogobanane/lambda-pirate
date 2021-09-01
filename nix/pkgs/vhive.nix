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
    rev = "8ca309b856e47448907292955f32af6ecad148c6";
    sha256 = null;
    #sha256 = "sha256-4WGmW+HiRfvnNqiGndBGucyDPY3W3XDDPuadtNa6gOM=";
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
    # # available in next release
    # (fetchpatch {
    #   url = "https://github.com/ease-lab/vhive/commit/db5cac4a1a25f17229bd26af84503ec235a14707.patch";
    #   sha256 = "sha256-Wqc6DKhDPK+1JmuWEiq0bxFJxWScoj247aaNPDLOA4Q=";
    # })
    # https://github.com/ease-lab/vhive/pull/265
    #(fetchpatch {
      #url = "https://github.com/ease-lab/vhive/commit/c71594795c5cccd0d1c432ff6819048dab966c86.patch";
      #sha256 = "sha256-a1Q81zcI5+6/nHTznUxVGabX6dCFNDzofrV2ijiVmoY=";
    #})

    #./0001-increase-vm-start-timeout.patch
    ##./0001-set-upper-limit-for-autoscaling.patch
    ##./0001-enable-autoscaling-limits.patch
    #./0001-limit-autoscaling-for-workloads.patch
    #./0001-limit-autoscaling-min.patch
    #./0001-debug-print-guest-IPs.patch
  ];

  patchPhase = ''
    # we now use vendored/peter which is already vendored
    #go mod vendor
  '';

  vendorSha256 = null;
  #vendorSha256 = "sha256-zDXhO7uDbPLdr6RYFiGJp3AZXGj7B8nIXCrdWRJVQkM=";
}
