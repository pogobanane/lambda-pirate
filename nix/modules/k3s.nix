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
  settingsFormat = pkgs.formats.toml {};
  hasZfs = lib.any (fs: fs == "zfs") config.boot.supportedFilesystems;
in
{
  options.virtualisation.containerd.settings = lib.mkOption {
    type = settingsFormat.type;
    default = "";
    description = ''
      Verbatim lines to add to containerd.toml
    '';
  };
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

    networking.firewall.allowedTCPPorts = [ 8443 ];
    services.k3s.enable = true;
    services.k3s.docker = false;

    # Upstream this?
    virtualisation.containerd.configFile = settingsFormat.generate "containerd.toml"
      config.virtualisation.containerd.settings;

    virtualisation.containerd.enable = true;

    virtualisation.containerd.settings = {
      # Upstream this?
      plugins.cri.containerd.snapshotter = lib.mkIf hasZfs "zfs";
      plugins.cri.cni = {
        bin_dir = "${pkgs.cni-plugins}/bin";
        conf_dir = "${pkgs.writeTextDir "net.d/10-flannel.conflist" flannel}/net.d";
      };
    };

    systemd.services.containerd.serviceConfig = lib.mkIf hasZfs {
      ExecStartPre = "-${pkgs.zfs}/bin/zfs create -o mountpoint=/var/lib/containerd/io.containerd.snapshotter.v1.zfs zroot/containerd";
    };

    # Upstream this?
    systemd.services.containerd.path = lib.mkIf hasZfs [ pkgs.zfs ];

    services.k3s.role = "server";
    services.k3s.extraFlags = toString [
      "--no-deploy traefik"
      "--flannel-backend=host-gw"
      "--kubelet-arg=cgroup-driver=systemd"
      "--container-runtime-endpoint unix:///etc/firecracker-containerd/fccd-cri.sock"
    ];
  };
}
