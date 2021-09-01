{ vhive, buildGoModule, kn, lib, makeWrapper }:
buildGoModule {
  name = "vhive-examples";
  subPackages = [
    "examples/invoker"
    "examples/deployer"
    "examples/registry"
  ];

  postPatch = ''
    substituteInPlace ./examples/deployer/client.go \
      --replace "./examples/deployer/functions.json" "$out/share/vhive-examples/examples/deployer/functions.json" \
      --replace "./configs/knative_workloads" "$out/share/vhive-examples/configs/knative_workloads"
    install -D ./examples/deployer/functions.json $out/share/vhive-examples/examples/deployer/functions.json
    cp -r ./configs $out/share/vhive-examples/configs
    install -D ./examples/registry/images.txt $out/share/vhive-examples/examples/registry/images.txt
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
  deleteVendor = true;
  vendorSha256 = "sha256-BDL+2MKOLALy3aRUy/FTZ3nutOIMUFMtVJA+AJMBfdU=";
}
