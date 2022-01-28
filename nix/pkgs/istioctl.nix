{ buildGoModule, go-bindata, fetchFromGitHub }:

buildGoModule rec {
  pname = "istioctl";
  # latest version still fails
  version = "1.12.2";
  nativeBuildInputs = [ go-bindata ];

  src = fetchFromGitHub {
    owner = "istio";
    repo = "istio";
    rev = version;
    sha256 = "sha256-6eVFyGVvOUr5RA5jeavKcLJedv4jOGXAg3aa4N3cNx8=";
  };

  # Bundle charts
  #preBuild = ''
  #  patchShebangs operator/scripts
  #  bin/update_crds.sh
  #  operator/scripts/create_assets_gen.sh
  #'';

  subPackages = [ "istioctl/cmd/istioctl" ];
  doCheck = false;
  vendorSha256 = "sha256-4Z4Fgv9zmAwp3tEvHj8yLOWkFY/zFz5VfehSWCuIU0I=";
}
