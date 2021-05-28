{ runc, fetchFromGitHub, glibc }:
runc.overrideAttrs  (old: rec {
  buildInputs = [
    glibc.static
  ];

  buildPhase = ''
    runHook preBuild
    cd go/src/${runc.goPackagePath}
    patchShebangs .
    make static man COMMIT=${runc.version} VERSION=${runc.version} BUILDTAGS=
    runHook postBuild
  '';

  # static linking
  CGO_ENABLED = 0;
  preInstall = ''
    # don't wrap the binary with a shell script
    wrapProgram() {
      :
    }
  '';
})
