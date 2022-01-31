{ pkgs, ... }:
{
  virtualisation.docker.enable = true;

  systemd.tmpfiles.rules = [
    "D /etc/firecracker-containerd 0755 root root - -"
  ];

  # required for skopeo (image cache)
  virtualisation.containers.enable = true;
  virtualisation.containers.policy = {
    default = [{ type = "insecureAcceptAnything"; }];
    transports.docker-daemon."" = [{ type = "insecureAcceptAnything"; }];
  };

  systemd.services.vhive = let
    preStart = ''
      rm -rf /etc/firecracker-containerd/fccd-cri.sock
       # bridges/tap interfaces are not cleaned up some time
      ip --json link | jq -r '.[] | select(.ifname | test(".*_tap$|br0|br1")) | .ifname' | xargs -r -n1 ip link del
    '';
  in {
    wantedBy = ["multi-user.target"];
    after = [ "firecracker-containerd.service" "containerd.service" ];
    wants = [ "firecracker-containerd.service" "containerd.service" ];
    path = [
      pkgs.nettools pkgs.kubectl pkgs.iptables pkgs.jq pkgs.iproute2 pkgs.sudo
    ];
    inherit preStart;
    postStop = preStart;
    serviceConfig ={
      Environment = "KUBECONFIG=/etc/rancher/k3s/k3s.yaml";
      Restart = "on-failure";
      ExecStart = "${pkgs.vhive}/bin/vhive -dbg";
      #ExecStart = "/home/peter/go/bin/vhive -dbg -snapshots";
    };
  };
}
