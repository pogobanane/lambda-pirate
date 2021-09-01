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
  pinned-cni-plugins = pkgs.callPackage ../pkgs/cni-plugins.nix { };
in
{
  config = {
    nixpkgs.overlays = [
      (self: super: {
        # theres an required plugin missing in 1.0.0 so we pin it to 0.9.1
        cni-plugins = pinned-cni-plugins;
      })
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
    networking.hosts = { "192.168.178.79" = [ "docker-registry.registry.svc.cluster.local" ]; };

    virtualisation.containerd.enable = true;

    virtualisation.containerd.settings = {
      # this leads to /var/lib/cni being created...
      plugins.cri.cni.conf_dir = "${pkgs.writeTextDir "net.d/10-flannel.conflist" flannel}/net.d";
      # ...whereas i replaced it with the following because of some package update
      #plugins."io.containerd.grpc.v1.cri".cni.conf_dir = "${pkgs.writeTextDir "net.d/10-flannel.conflist" flannel}/net.d";
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
