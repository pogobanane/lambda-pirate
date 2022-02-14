{ buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  pname = "kn";
  version = "0.23.0";

  src = fetchFromGitHub {
    owner = "knative";
    repo = "client";
    #rev = "v${version}";
    rev = "3cc608f9b1ddc0a3634711444878c0207396f06b";
    sha256 = "sha256-2So38RTJpznJGWvk2p97PWl8etDVWG3ra7WBM0EivDQ=";
  };

  subPackages = [ "cmd/kn" ];

  vendorSha256 = null;
}
