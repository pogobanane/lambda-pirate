{ stdenv, buildLinux, fetchurl, firecracker, linux_4_14 }:
# `buildLinux` is way to fucking complex, let's just write it from scratch
stdenv.mkDerivation rec {
  # this version seems to be what firecracker is currently using:
  # https://github.com/firecracker-microvm/firecracker/blob/81cd08af07e91deca20acf0f576ca3e84ce8b2a9/src/vmm/src/utilities/mock_resources/make_noisy_kernel.sh#L15
  inherit (linux_4_14)
    name src version buildInputs nativeBuildInputs depsBuildBuild;

  postPatch = ''
    patchShebangs .
    substituteInPlace Makefile --replace '/bin/pwd' 'pwd'
    substituteInPlace tools/scripts/Makefile.include --replace '/bin/pwd' 'pwd'
  '';

  enableParallelBuilding = true;

  postConfigure = ''
    # TODO fix upstream config
    #cp ${firecracker.src}/resources/microvm-kernel-x86_64.config .config
    cp ${./firecracker-kernel-config} .config
    set +o pipefail
    yes \n | make oldconfig
    set -o pipefail
  '';

  installPhase = ''
    install -D vmlinux $out/vmlinux
    # sometimes handy for debugging
    install -D .config $out/kernel-config
  '';

  hardeningDisable = [ "bindnow" "format" "fortify" "stackprotector" "pic" "pie" ];
}
