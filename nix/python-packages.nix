# Generated by pip2nix 0.8.0.dev1
# See https://github.com/nix-community/pip2nix

{ pkgs, fetchurl, fetchgit, fetchhg }:

self: super: {
  "logfmt" = super.buildPythonPackage rec {
    pname = "logfmt";
    version = "0.4";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/f5/fc/143f15b9347c2e42a5c726a04defed086c543ddd541419c31baef01c6a17/logfmt-0.4-py2.py3-none-any.whl";
      sha256 = "0hfw41k2wn79q21ihb5yj4pk4nj7ykz819mqdqg88pg7jg5bf509";
    };
    format = "wheel";
    doCheck = false;
    buildInputs = [];
    checkInputs = [];
    nativeBuildInputs = [];
    propagatedBuildInputs = [];
  };
}
