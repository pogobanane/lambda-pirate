
# print this help
help: 
    just -l

# when the autoscaler overloads your system again
killvms:
    sudo pkill -SIGTERM firecracker

nixos-rebuild: 
    sudo nixos-rebuild switch --impure --override-input lambda-pirate ./.

make-incinerate:
    sudo -E make -C knative burn-down-cluster

make-deploy:
    sudo -E make -C knative deploy -j$(nproc)

# after cd ~/vhive && go install ./... you can run the deployer via:
vhive-deployer:
    sudo -E ~/go/bin/deployer -jsonFile ~/vhive/examples/deployer/functions.json -funcPath ~/vhive/configs/knative_workloads

vhive-invoker-slow:
    ~/go/bin/invoker -time 20

vhive-invoker-fast:
    ~/go/bin/invoker -rps 20 -time 20

watch-pods-all:
    watch sudo -E kubectl get pod --all-namespaces

watch-pods:
    watch -n 0.5 sudo -E kubectl get pod

fcctr: 
    echo "image to container id mapping"
    sudo firecracker-ctr -n firecracker-containerd containers list
    echo "containerid/task to pid mapping: not host pid"
    sudo firecracker-ctr -n firecracker-containerd tasks ls

# proxy to remove all security from rest api
kube-proxy:
    sudo -E kubectl proxy &

# works
# curl -k "http://localhost:8001/apis/autoscaling/v1/horizontalpodautoscalers" | vim -

# didnt work
# curl -k "http://localhost:8001/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers/minio-deployment-877b8596f-4x9nc"

