{ buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  pname = "kn";
  version = "0.23.0";

  src = fetchFromGitHub {
    owner = "knative";
    repo = "client";
    rev = "v${version}";
    sha256 = "sha256-BhS41pKiXfgia1bZ5xiK5rnF2KXcYU7o2dbKrvcxUv8=";
  };

  subPackages = [ "cmd/kn" ];

  vendorSha256 = null;
}
