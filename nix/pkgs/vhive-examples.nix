{ vhive, buildGoModule, kn, lib, makeWrapper }:
buildGoModule {
  name = "vhive-examples";
  subPackages = [
    "examples/invoker"
    "examples/deployer"
  ];

  postPatch = ''
    substituteInPlace ./examples/deployer/client.go \
      --replace "./examples/deployer/functions.json" "$out/share/vhive-examples/functions.json" \
      --replace "./configs/knative_workloads" "$out/share/vhive-examples/knative_workloads"
     install -D ./examples/deployer/functions.json $out/share/vhive-examples/functions.json
     cp -r ./configs/knative_workloads $out/share/vhive-examples
  '';

  postBuild = ''
    mkdir -p $out/bin
    # no idea why subPackages does not work here.
    for i in $subPackages; do
      pushd $i
      go build -o $out/bin/$(basename $i) ./.
      popd
    done
    wrapProgram $out/bin/deployer \
      --prefix PATH : ${lib.makeBinPath [ kn ]}
  '';

  nativeBuildInputs = [
    makeWrapper
  ];

  # example:
  # $ KUBECONFIG=/etc/rancher/k3s/k3s.yaml ./result/bin/deployer
  inherit (vhive) src patches;
  vendorSha256 = "sha256-iuNbO1z6pygnRf9sczj7VPi2Fz0kQorWSIb8+DXtXnU=";
}
