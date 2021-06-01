{ pkgs, ... }:
{
  systemd.services.vhive = let
    preStart = ''
      rm -rf /etc/firecracker-containerd/fccd-cri.sock
      ip --json link | jq -r '.[] | select(.ifname | test(".*_tap$|br0|br1")) | .ifname' | xargs -r -n1 ip link del
    '';
  in {
    wantedBy = ["multi-user.target"];
    path = [ pkgs.nettools pkgs.kubectl pkgs.iptables pkgs.jq pkgs.iproute2 ];
    inherit preStart;
    postStop = preStart;
    serviceConfig ={
      # bridges are not cleaned up some time
      ExecStart = "${pkgs.vhive}/bin/vhive";
    };
  };
}
