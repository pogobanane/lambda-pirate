{ pkgs, ... }:
{
  systemd.services.deploy-knative = {
    wantedBy = [ "multi-user.target" ];
    after = [ "k3s.service" ];
    wants = [ "k3s.service" ];
    serviceConfig ={
      Restart = "on-failure";
      ExecStart = "${pkgs.deploy-knative}/bin/deploy-knative";
    };
  };
}
