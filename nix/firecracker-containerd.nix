{ buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  pname = "firecracker-containerd";
  version = "0.24";
  src = fetchFromGitHub {
    owner = "ease-lab";
    repo = "firecracker-containerd";
    rev = "v${version}_user_page_faults";
    sha256 = "sha256-54x2h+/Br8mJqVe8o2WJais28h8Bc5kI6ltKRW+75nY=";
  };
  subPackages = [
    "firecracker-control/cmd/containerd"
    "agent"
    "runtime"
  ];

  # we want to this to be statically linked since it runs within the VM.
  postBuild = ''
    CGO_ENABLED=0 buildGoDir install ./agent
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
