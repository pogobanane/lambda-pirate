{ buildGoModule, go-bindata, fetchFromGitHub }:

buildGoModule rec {
  pname = "istioctl";
  # latest version still fails
  version = "1.7.1";
  nativeBuildInputs = [ go-bindata ];

  src = fetchFromGitHub {
    owner = "istio";
    repo = "istio";
    rev = version;
    sha256 = "sha256-CvYqYxb19lSc61SrvGcf/kG9e9zosHz4JbByA+bN600=";
  };

  # Bundle charts
  preBuild = ''
    patchShebangs operator/scripts
    operator/scripts/create_assets_gen.sh
  '';

  subPackages = [ "istioctl/cmd/istioctl" ];
  doCheck = false;
  vendorSha256 = "sha256-4Z4Fgv9zmAwp3tEvHj8yLOWkFY/zFz5VfehSWCuIUcI=";
}
