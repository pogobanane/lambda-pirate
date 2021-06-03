{ pkgs, ... }:
{

  systemd.tmpfiles.rules = [
    "D /etc/firecracker-containerd 0755 root root - -"
  ];

  systemd.services.vhive = let
    preStart = ''
      rm -rf /etc/firecracker-containerd/fccd-cri.sock
       # bridges/tap interfaces are not cleaned up some time
      ip --json link | jq -r '.[] | select(.ifname | test(".*_tap$|br0|br1")) | .ifname' | xargs -r -n1 ip link del
    '';
  in {
    wantedBy = ["multi-user.target"];
    path = [
      pkgs.nettools pkgs.kubectl pkgs.iptables pkgs.jq pkgs.iproute2 pkgs.sudo
    ];
    inherit preStart;
    postStop = preStart;
    serviceConfig ={
      Environment = "KUBECONFIG=/etc/rancher/k3s/k3s.yaml";
      Restart = "on-failure";
      ExecStart = "${pkgs.vhive}/bin/vhive -dbg";
    };
  };
}
