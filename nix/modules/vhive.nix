{ pkgs, ... }:
{
  systemd.services.vhive = let
    preStart = ''
      rm -rf /etc/firecracker-containerd/fccd-cri.sock
      ip --json link | jq -r '.[] | select(.ifname | test(".*_tap$|br0|br1")) | .ifname' | xargs -r -n1 ip link del
    '';
  in {
    wantedBy = ["multi-user.target"];
    path = [
      pkgs.nettools pkgs.kubectl pkgs.iptables pkgs.jq pkgs.iproute2 pkgs.sudo
    ];
    # bridges are not cleaned up some time
    inherit preStart;
    postStop = preStart;
    serviceConfig ={
      Environment = "KUBECONFIG=/etc/rancher/k3s/k3s.yaml";
      ExecStart = "${pkgs.vhive}/bin/vhive -dbg";
    };
  };
}
