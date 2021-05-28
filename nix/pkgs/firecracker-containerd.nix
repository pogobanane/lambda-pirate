{ buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  pname = "firecracker-containerd";
  version = "0.24";
  src = fetchFromGitHub {
    owner = "ease-lab";
    repo = "firecracker-containerd";
    # this branch seems not to work: https://github.com/ease-lab/firecracker-containerd/commits/v0.24_user_page_faults
    rev = "10cc33c3c603d9ac8025fd243826cb3b1edbdead";
    sha256 = "sha256-HSA4TmeD+sUpy5S+wOXyUzTARSJCHQEjzRDlRiryUyk=";
    fetchSubmodules = true;
  };
  subPackages = [
    "firecracker-control/cmd/containerd"
    "agent"
    "runtime"
  ];

  # we want to this to be statically linked since it runs within the VM.
  postBuild = ''
    set -x
    CGO_ENABLED=0 buildGoDir install ./agent
    set +x
  '';

  preBuild = ''
    export buildFlagsArray=(
      "-ldflags=-s -w -X main.revision=${version}"
    )
  '';

  postInstall = ''
    mv $out/bin/{runtime,containerd-shim-aws-firecracker}
  '';

  doCheck = false; # does not work in sandbox
  vendorSha256 = "sha256-wtVfLkKLy7mkUltRWuIoOzALE3zl8CND820GUF5FGvQ=";
}
