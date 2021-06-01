{ pkgs, ... }:
{
  systemd.services.vhive = {
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      path = [ pkgs.nettools pkgs.kubectl pkgs.iptables ];
      # bridges are not cleaned up some time
      ExecStartPre = [
        "-${pkgs.iproute2}/bin/ip l d br0"
        "-${pkgs.iproute2}/bin/ip l d br1"
        "${pkgs.coreutils}/bin/rm -rf /etc/firecracker-containerd/fccd-cri.sock"
      ];
      ExecStart = "${pkgs.vhive}/bin/vhive";
    };
  };
}
