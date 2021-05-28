{ vmTools, fetchurl, qemu_kvm, runCommand, firecracker-containerd
, squashfsTools
, util-linux }:

let
  qcow = vmTools.makeImageFromDebDist {
    name = "debian-10.9-buster-amd64";
    fullName = "Debian 10.9 Buster (amd64)";
    packagesList = fetchurl {
      url = "https://snapshot.debian.org/archive/debian/20210526T143040Z/dists/buster/main/binary-amd64/Packages.xz";
      sha256 = "sha256-k13toY1b3CX7GBPQ7Jm24OMqCEsgPlGK8M99x57o69o=";
    };
    urlPrefix = "mirror://debian";
    packages = [
      "base-passwd"
      "dpkg"
      "libc6-dev"
      "perl"
      "bash"
      "dash"
      "gzip"
      "bzip2"
      "tar"
      "grep"
      "mawk"
      "sed"
      "diff"
      "findutils"
      "locales"
      "coreutils"
      "util-linux"
      # Needed because it provides /etc/login.defs, whose absence causes
      # the "passwd" post-installs script to fail.
      "login"
      "passwd"

      # from https://github.com/firecracker-microvm/firecracker-containerd/blob/7cf94848ae2e587f7469d42037e54607a461ff34/tools/image-builder/Makefile#L58
      "udev"
      "systemd"
      "systemd-sysv"
      "procps"
      "libseccomp2"
      "haveged"
    ];

    # We create the rootfs first in tmpfs before creating the squashfs,
    # this needs a bit more RAM but is quite fast otherwise
    memSize = "1G";

    # the default function would create an ext4 image here and mount it to /mnt
    createRootFS = ''
      mkdir -p /mnt/proc /mnt/dev /mnt/sys
      touch /mnt/.debug

      # fake mount, that buildCommand can unmount
      ${util-linux}/bin/mount --bind /mnt /mnt
    '';

    QEMU_OPTS = " -smp $(nproc)";

    postInstall = ''
      cp -rv ${firecracker-containerd.src}/tools/image-builder/files_debootstrap/* /mnt
      install -D ${firecracker-containerd}/bin/agent /mnt/usr/local/bin/agent
      install -D ${firecracker-containerd}/bin/runc /mnt/usr/local/bin/runc
      # https://github.com/firecracker-microvm/firecracker-containerd/blob/7cf94848ae2e587f7469d42037e54607a461ff34/tools/image-builder/Makefile#L17
      dirs=$(grep -m 1 IMAGE_DIRS ${firecracker-containerd.src}//tools/image-builder/Makefile | sed 's/^.*= //g')
      for d in $dirs; do
        mkdir -p /mnt/$d
      done
      # overlay-init wants this
      ln -s /lib/systemd/systemd /mnt/usr/sbin/init
      ln -sf dash /mnt/bin/sh

      # now we create the actual filesystem
      ${squashfsTools}/bin/mksquashfs /mnt /dev/vda -noappend -e /mnt/proc -e /mnt/inst
    '';
  };
in
runCommand "default-rootfs.img" { } ''
  ${qemu_kvm}/bin/qemu-img convert ${qcow}/disk-image.qcow2 $out
''
