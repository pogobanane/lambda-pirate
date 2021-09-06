vhive_dir := `echo "$(dirname $(which deployer))/../share/vhive-examples"`
vhive_bin := ""
#vhive_dir := invocation_directory() + "/../vhive"
#vhive_bin := "~/go/bin/"

# print this help
help: 
    just -l

# when the autoscaler overloads your system again
killvms:
    sudo pkill -SIGTERM firecracker

lambda-pirate:
  nix build github:Mic92/vmsh#vmsh -o vmsh/vmsh
  nix build github:Mic92/vmsh#busybox-image -o vmsh/busybox.ext4
  [[ -f vmsh/busybox.rw.ext4 ]] || cp vmsh/busybox.ext4 vmsh/busybox.rw.ext4
  sudo -E IN_CAPSH=1 \
      capsh \
      --caps="cap_sys_ptrace,cap_dac_override,cap_sys_admin,cap_sys_resource+epi cap_setpcap,cap_setuid,cap_setgid+ep" \
      --keep=1 \
      --groups=$(id -G | sed -e 's/ /,/g') \
      --gid=$(id -g) \
      --uid=$(id -u) \
      --addamb=cap_sys_resource \
      --addamb=cap_sys_admin \
      --addamb=cap_sys_ptrace \
      --addamb=cap_dac_override \
      -- -c 'export USER=$(id -un); python3 lambda-pirate.py'

reset: 
    just make-incinerate
    just vhive-registry
    just make-deploy
    while [[ 24 -gt $(sudo -E kubectl get pod --all-namespaces | grep "Running" | wc -l) ]]; do sleep 1; done
    sleep 5
    just vhive-deployer

reset-notify:
    #!/bin/sh
    just reset
    sendtelegram "vhive resetted $?"

nixos-rebuild: 
    sudo nixos-rebuild switch --impure --override-input lambda-pirate ./.

make-incinerate:
    sudo -E make -C knative burn-down-cluster

make-deploy:
    CONFIG_ACCESSOR=cat VHIVE_CONFIG={{vhive_dir}}/configs sudo -E make -C knative deploy -j$(nproc)

vhive-deployer:
    sudo -E {{vhive_bin}}deployer -jsonFile {{vhive_dir}}/examples/deployer/functions.json -funcPath {{vhive_dir}}/configs/knative_workloads --endpointsFile /tmp/endpoints.json

vhive-deploy-local:
    sudo -E kn service apply helloworldlocal -f {{vhive_dir}}/configs/knative_workloads/helloworld_local.yaml

vhive-invoker-slow:
    {{vhive_bin}}invoker -time 20 --endpointsFile /tmp/endpoints.json

vhive-invoker-fast:
    {{vhive_bin}}invoker -rps 20 -time 20 --endpointsFile /tmp/endpoints.json

vhive-registry:
    #CONFIG_ACCESSOR=cat VHIVE_CONFIG=/home/peter/vhive/configs sudo -E make -C knative registry
    sudo {{vhive_bin}}registry -imageFile {{vhive_dir}}/examples/registry/images.txt -source docker://docker.io 
    #-destination docker://docker-registry.registry.svc.cluster.local.10.43.225.186.nip.io:5000

watch-pods-all:
    watch sudo -E kubectl get pod --all-namespaces

watch-pods:
    watch -n 0.5 sudo -E kubectl get pod

fcctr: 
    echo "image to container id mapping"
    sudo firecracker-ctr -n firecracker-containerd containers list
    echo "containerid/task to pid mapping: not host pid"
    sudo firecracker-ctr -n firecracker-containerd tasks ls

fcctr-delete:
    for i in {0..200}; do sudo firecracker-ctr -n firecracker-containerd containers delete $i; done

# proxy to remove all security from rest api
kube-proxy:
    sudo -E kubectl proxy &

# works
# curl -k "http://localhost:8001/apis/autoscaling/v1/horizontalpodautoscalers" | vim -

# didnt work
# curl -k "http://localhost:8001/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers/minio-deployment-877b8596f-4x9nc"

sign-drone:
  DRONE_SERVER=https://drone.thalheim.io \
  DRONE_TOKEN=$(cat $HOME/.secret/drone-token) \
    nix shell --inputs-from .# 'nixpkgs#drone-cli' -c drone sign pogobanane/lambda-pirate --save
