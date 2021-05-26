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
  vendorSha256 = "sha256-NqXwrfmT7gxqbjpwB+F9lz2M6aOuU0t8fwjifTd0e90=";
}
