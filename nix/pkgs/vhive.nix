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
    # https://github.com/ease-lab/vhive/pull/265
    (fetchpatch {
      url = "https://github.com/ease-lab/vhive/commit/c71594795c5cccd0d1c432ff6819048dab966c86.patch";
      sha256 = "sha256-a1Q81zcI5+6/nHTznUxVGabX6dCFNDzofrV2ijiVmoY=";
    })

    ./0001-increase-vm-start-timeout.patch
  ];

  vendorSha256 = "sha256-iuNbO1z6pygnRf9sczj7VPi2Fz0kQorWSIb8+DXtXnU=";
}
