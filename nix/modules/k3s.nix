{ pkgs, lib, config, ... }:
let
  #pinned-cni-plugins = pkgs.callPackage ../pkgs/cni-plugins.nix { };
  #pinned-containerd = pkgs.callPackage ../pkgs/containerd.nix { };
in
{
  options = {
    services.vhive.dockerRegistryIp = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        IP of the host reachable from the cluster, where the registry is running
      '';
    };
  };

  config = {
    nixpkgs.overlays = [
      #(self: super: {
      #  # theres an required plugin missing in 1.0.0 so we pin it to 0.9.1
      #  cni-plugins = pinned-cni-plugins;
      #  containerd = pinned-containerd;
      #})
    ];

    environment.systemPackages = [
      (pkgs.runCommand "wrap-kubectl"
        {
          nativeBuildInputs = [ pkgs.makeWrapper ];
        } ''
        mkdir -p $out/bin
        makeWrapper ${pkgs.kubernetes}/bin/kubectl $out/bin/kubectl \
          --set KUBECONFIG "/etc/kubernetes/cluster-admin.kubeconfig"
      '')
      # having iptables in path is still useful for debugging
      pkgs.iptables
    ];

    services.k3s.enable = true;
    services.k3s.docker = false;
    services.dockerRegistry.enable = true;
    services.dockerRegistry.listenAddress = "0.0.0.0";

    # update firewall whitelist for use if it is enabled
    networking.firewall.allowedTCPPorts = [ 
      6443 # kube api server
      8001 # proxy exposing 6441 insecurely
      5000 # docker registry
    ];
    networking.firewall.checkReversePath = false;

    # IP under which this host is reachable in the local network. TODO needs config
    networking.hosts = { ${config.services.vhive.dockerRegistryIp} = [ "docker-registry.registry.svc.cluster.local" ]; };

    virtualisation.containerd.enable = true;

    virtualisation.containerd.settings = {
      version = 2;
      # this leads to /var/lib/cni being created...
      plugins."io.containerd.grpc.v1.cri" = {
        cni.conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d/";
        cni.bin_dir = "${pkgs.runCommand "cni-bin-dir" {} ''
          mkdir -p $out
          ln -sf ${pkgs.cni-plugins}/bin/* ${pkgs.cni-plugin-flannel}/bin/* $out
        ''}";
      };
    };

    systemd.services.containerd.serviceConfig = lib.mkIf config.boot.zfs.enabled {
      ExecStartPre = [
        "-${pkgs.zfs}/bin/zfs create -o mountpoint=/var/lib/containerd/io.containerd.snapshotter.v1.zfs zroot/containerd"
        "-${pkgs.zfs}/bin/zfs mount zroot/containerd"
      ];
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
