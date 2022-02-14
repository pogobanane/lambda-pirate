# Evaluation guide

This guide assumes that your evaluation machine has already set up kubernetes with [vhive](https://github.com/ease-lab/vhive) on a NixOS machine as described in the [README](README.md).

Lambda-pirate can be downloaded like that:

```
[reviewer@mickey:~]$ git clone https://github.com/pogobanane/lambda-pirate.git
```

After changing to the lambda-pirate

```
[reviewer@mickey:~]$ cd lambda-pirate/
```

run

```
[reviewer@mickey:~]$ nix develop 
```

to open a shell that has all dependencies loaded for the further steps.


After this reset the vhive cluster state like this:

```
[reviewer@mickey:~/lambda-pirate]$ just reset
just make-incinerate
#...
serviceaccount/mt-broker-ingress created
clusterrolebinding.rbac.authorization.k8s.io/eventing-mt-channel-broker-controller created
clusterrolebinding.rbac.authorization.k8s.io/knative-eventing-mt-broker-filter created
clusterrolebinding.rbac.authorization.k8s.io/knative-eventing-mt-broker-ingress created
deployment.apps/mt-broker-filter created
service/broker-filter created
deployment.apps/mt-broker-ingress created
service/broker-ingress created
deployment.apps/mt-broker-controller created
horizontalpodautoscaler.autoscaling/broker-ingress-hpa created
horizontalpodautoscaler.autoscaling/broker-filter-hpa created
kubectl --namespace istio-system get service istio-ingressgateway
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   10.43.17.245   192.168.1.240   15021:32135/TCP,80:30189/TCP,443:30643/TCP   27s
make: Leaving directory '/scratch/reviewer/lambda-pirate/knative'
while [[ 24 -gt $(sudo -E kubectl get pod --all-namespaces | grep "Running" | wc -l) ]]; do sleep 1; done
sleep 5
just vhive-deployer
# we just accept that it won't deploy completely and kill after some time
sudo -E deployer -jsonFile knative/functions.json -funcPath /nix/store/pv5x7mbh3kbk5qw1v4w17dib0cvvr2lv-vhive-examples/bin/../share/vhive-examples/configs/knative_workloads --endpointsFile /tmp/endpoints.json &
sleep 30
sudo kill $(ps aux | awk '{print $2"\t"$11}' | grep $(echo deployer) | awk '{print $1}')
wait
```

The vhive deployer has now started a hellooopsie lambda which produces an error
every 15 seconds. Start lambda-pirate (`just lambda-pirate`) and wait until an
error is detected and vmsh is attached to the micro VM like in this example:

```
[reviewer@mickey:~/lambda-pirate]$ just lambda-pirate
sudo modprobe kheaders
nix build github:Mic92/vmsh#vmsh -o vmsh/vmsh
nix build github:Mic92/vmsh#busybox-image -o vmsh/busybox.ext4
[[ -f vmsh/busybox.rw.ext4 ]] || cp vmsh/busybox.ext4 vmsh/busybox.rw.ext4
sudo -E IN_CAPSH=1 capsh --caps="cap_sys_ptrace,cap_dac_override,cap_sys_admin,cap_sys_resource+epi cap_setpcap,cap_setuid,cap_setgid+ep" --keep=1 --groups=$(id -G | sed -e 's/ /,/g') --gid=$(id -g) --uid=$(id -u) --addamb=cap_sys_resource --addamb=cap_sys_admin --addamb=cap_sys_ptrace --addamb=cap_dac_override -- -c 'export USER=$(id -un); python3 lambda-pirate.py'
lambda-pirate deamon for vhive
Waiting for errors in vhive workloads.
[VM 2 error] ERROR: some periodic error
attaching vmsh to VM 2
--pts /dev/pts/3
[INFO  vmsh::attach] attaching
[INFO  vmsh::kvm::hypervisor::hypervisor] vcpu 0 fd 42
[INFO  vmsh::kvm::hypervisor::hypervisor] irqfd 6, interupt gsi/nr 6
[INFO  vmsh::kvm::hypervisor::ioeventfd] ioeventfd 7, guest phys addr 0x3ffffffff050
[INFO  vmsh::kvm::hypervisor::hypervisor] irqfd 8, interupt gsi/nr 6
[INFO  vmsh::devices::virtio::console::device] pts is Some("/dev/pts/3")
[INFO  vmsh::kvm::hypervisor::ioeventfd] ioeventfd 9, guest phys addr 0x3fffffffe050
[INFO  vmsh::kernel] found linux kernel at 0xffffffff81000000-0xffffffffa0027000
[INFO  vmsh::kernel] found ksymtab_string at physical 0x1dbea80:0x1de1063 with 7233 strings
[INFO  vmsh::kernel] found ksymtab 30304 bytes before ksymtab_strings at 0xffffffff81db7420
[INFO  vmsh::kernel] found 7576 kernel symbols
[INFO  vmsh::page_table] allocate page table at 0x3fffffff9000
[INFO  vmsh::page_table] allocate page table at 0x3fffffffa000
[INFO  vmsh::stage1] spawn stage1 in vm at ip 0xffffffff80001daa
[INFO  vmsh::devices::threads] mmio dev attached
[INFO  vmsh::devices::threads] device ready!
[INFO  vmsh::attach] blkdev queue ready.
sh: can't access tty; job control turned off
/ # [INFO  vmsh::stage1] stage1 driver started
```

This gives a shell inside the virtual machine running the failing hellooopsie application.
You can run some command as shown below and quit `lambda-pirate` using `Ctrl-C`:

```
/ # ls -la
ls -la
total 20
drwxr-xr-x   10 root     root          1024 Feb 14 13:01 .
drwxr-xr-x   10 root     root          1024 Feb 14 13:01 ..
-rw-------    1 root     root             7 Feb 14 13:01 .ash_history
lrwxrwxrwx    1 root     root            95 Jan 30 03:00 bin -> /nix/store/fa2qg8brx46p8n2qlylgd3xp6x8bmymf-busybox-static-x86_64-unknown-linux-musl-1.34.1/bin
drwxr-xr-x   11 root     root          2500 Feb 14 12:57 dev
drwxr-xr-x    2 root     root          1024 Feb 14 12:57 etc
drwx------    2 root     root         12288 Jan 30 03:00 lost+found
drwxr-xr-x    3 root     root          1024 Jan 30 03:00 nix
dr-xr-xr-x  105 root     root             0 Feb 14 12:56 proc
dr-xr-xr-x   12 root     root             0 Feb 14 12:56 sys
drwxr-xr-x    2 root     root          1024 Jan 30 03:00 tmp
drwxr-xr-x    3 root     root          1024 Feb 14 12:57 var
/ # exit
exit
process finished with exit status: 0
```
