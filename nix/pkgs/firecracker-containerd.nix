{ buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  pname = "firecracker-containerd";
  version = "0.24";
  src = fetchFromGitHub {
    owner = "ease-lab";
    repo = "firecracker-containerd";
    # this is the actual branch, but no tags: "v${version}_user_page_faults"
    rev = "aabd117cc2ec9c24a64c0cb5143d353e80d45f74";
    sha256 = "sha256-cncQPPtGv1cu0G+EwaAI0v4PGuaKF39W3E1Tie1uxfc=";
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
    pushd ./_submodules/runc
    CGO_ENABLED=0 buildGoDir install ./.
    popd
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
  vendorSha256 = "sha256-5jUxz8AwAX09x9HGNTMZ8Gt9OEo+4rZgo5Uk3fdZ2BY=";
}
