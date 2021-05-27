{ runCommand, containerd }:
runCommand "fircracker-ctr" {} ''
  mkdir -p $out/bin
  ln -s ${containerd}/bin/ctr $out/bin/firecracker-ctr
''
