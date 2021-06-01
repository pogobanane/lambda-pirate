{ buildGoModule, fetchgit, fetchpatch }:

buildGoModule rec {
  pname = "vhive";
  version = "1.2";

  # not fetchFromGitHub to skip git-lfs assets
  src = fetchgit {
    url = "https://github.com/ease-lab/vhive";
    rev = "v${version}";
    sha256 = "sha256-cTSXOkDD7nvwhCabfUdmdTUoDr2+q7fk3JrGzifHyto=";
  };

  subPackages = [ "." ];

  # does not work in sandbox
  doCheck = false;

  patches = [
    # available in next release
    (fetchpatch {
      url = "https://github.com/ease-lab/vhive/commit/db5cac4a1a25f17229bd26af84503ec235a14707.patch";
      sha256 = "sha256-Wqc6DKhDPK+1JmuWEiq0bxFJxWScoj247aaNPDLOA4Q=";
    })
    ./0001-increase-vm-start-timeout.patch
  ];

  vendorSha256 = "sha256-LsXL2jS/w5fES8lX9n2rbQtgVjuleNwQjVNd+Xjp5TI=";
}
