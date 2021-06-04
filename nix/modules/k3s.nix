{ pkgs, lib, config, ... }:
let
  flannel = builtins.toJSON {
    name = "cbr0";
    cniVersion = "0.3.1";
    plugins = [
      {
        type = "flannel";
        delegate = {
          hairpinMode = true;
          forceAddress = true;
          isDefaultGateway = true;
        };
      }
      {
        type = "portmap";
        capabilities = {
          portMappings = true;
        };
      }
    ];
  };
in
{
  config = {
    environment.systemPackages = [
      (pkgs.runCommand "wrap-kubectl"
        {
          nativeBuildInputs = [ pkgs.makeWrapper ];
        } ''
        mkdir -p $out/bin
        makeWrapper ${pkgs.kubernetes}/bin/kubectl $out/bin/kubectl \
          --set KUBECONFIG "/etc/kubernetes/cluster-admin.kubeconfig"
      '')
    ];

    services.k3s.enable = true;
    services.k3s.docker = false;

    # for some reasons our firewall, breaks caligo... no body got time to debug this...
    networking.firewall.enable = false;

    virtualisation.containerd.enable = true;

    virtualisation.containerd.settings = {
      plugins.cri.cni.conf_dir = "${pkgs.writeTextDir "net.d/10-flannel.conflist" flannel}/net.d";
    };

    systemd.services.containerd.serviceConfig = lib.mkIf config.boot.zfs.enabled {
      ExecStartPre = "-${pkgs.zfs}/bin/zfs create -o mountpoint=/var/lib/containerd/io.containerd.snapshotter.v1.zfs zroot/containerd";
    };

    systemd.services.k3s = {
      after = [ "vhive.service" ];
      wants = [ "vhive.service" ];
    };

    services.k3s.role = "server";
    services.k3s.extraFlags = toString [
      "--disable traefik"
      "--disable servicelb"
      "--flannel-backend=host-gw"
      "--container-runtime-endpoint unix:///etc/firecracker-containerd/fccd-cri.sock"
    ];
  };
}
