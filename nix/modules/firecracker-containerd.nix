{ config, lib, pkgs, ... }:

let
  cfg = config.services.firecracker-containerd;
  configFile = (pkgs.formats.toml { }).generate "config.toml" cfg.extraConfig;
  runtimeFile = (pkgs.formats.json { }).generate "config.json" cfg.extraRuntimeConfig;
  devmapperDir = "/var/lib/firecracker-containerd/snapshotter/devmapper";
  # that way we can support running container
  poolName = "fc-dev-thinpool-${config.networking.hostName}";
in
{
  options.services.firecracker-containerd = {
    extraConfig = lib.mkOption {
      default = { };
      description = "Extra configuration options for /etc/firecracker-containerd/config.toml";
    };
    extraRuntimeConfig = lib.mkOption {
      default = { };
      description = "Extra configuration options for /etc/firecracker-containerd/firecracker-runtime.json";
    };
  };

  config = {
    environment.etc."firecracker-containerd/config.yml".source = configFile;
    environment.etc."firecracker-containerd/firecracker-runtime.json".source = runtimeFile;
    services.firecracker-containerd.extraConfig = {
      disabled_plugins = [ "cri" ];
      root = "/var/lib/firecracker-containerd/containerd";
      state = "/run/firecracker-containerd";
      grpc.address = "/run/firecracker-containerd/containerd.sock";
      plugins.devmapper = {
        pool_name = poolName;
        base_image_size = "10GB";
        root_path = devmapperDir;
      };

      debug.level = "debug";
    };
    services.firecracker-containerd.extraRuntimeConfig = {
      firecracker_binary_path = "${pkgs.firecracker}";
      kernel_image_path = "${pkgs.firecracker}/vmlinux";
      kernel_args = ''
        console=ttyS0 noapic reboot=k panic=1 pci=off nomodules ro systemd.journald.forward_to_console systemd.unit=firecracker.target init=/sbin/overlay-init
      '';
      root_drive = pkgs.firecracker-default-rootfs;
      cpu_template = "T2";
      log_levels = [ "info" ];
    };

    systemd.services.firecracker-containerd = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      path = [ pkgs.bc pkgs.util-linux pkgs.firecracker pkgs.lvm2 ];
      preStart = ''
        set -eux -o pipefail
        mkdir -p ${devmapperDir}
        if [[ ! -f ${devmapperDir}/data ]]; then
          touch "${devmapperDir}/data"
          truncate -s 100G "${devmapperDir}/data"
        fi
        if [[ ! -f ${devmapperDir}/metadata ]]; then
          touch "${devmapperDir}/metadata"
          truncate -s 2G "${devmapperDir}/metadata"
        fi
        DATADEV="$(losetup --output NAME --noheadings --associated ${devmapperDir}/data)"
        if [[ -z "$DATADEV" ]]; then
            DATADEV="$(losetup --find --show ${devmapperDir}/data)"
        fi

        METADEV="$(losetup --output NAME --noheadings --associated ${devmapperDir}/metadata)"
        if [[ -z "$METADEV" ]]; then
            METADEV="$(losetup --find --show ${devmapperDir}/metadata)"
        fi

        SECTORSIZE=512
        DATASIZE="$(blockdev --getsize64 -q $DATADEV)"
        LENGTH_SECTORS=$(bc <<< "$DATASIZE/$SECTORSIZE")
        DATA_BLOCK_SIZE=128
        LOW_WATER_MARK=32768
        THINP_TABLE="0 $LENGTH_SECTORS thin-pool $METADEV $DATADEV $DATA_BLOCK_SIZE $LOW_WATER_MARK 1 skip_block_zeroing"
        echo "$THINP_TABLE"

        if ! $(dmsetup reload "${poolName}" --table "$THINP_TABLE"); then
            dmsetup create "${poolName}" --table "$THINP_TABLE"
        fi
      '';
      serviceConfig.ExecStart = "${pkgs.firecracker}/bin/firecracker";
    };
  };
}
