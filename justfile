
# print this help
help: 
    just -l

# when the autoscaler overloads your system again
killvms:
    sudo pkill -SIGTERM firecracker

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
