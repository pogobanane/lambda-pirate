# λ🏴‍☠️ lambda-pirate
using [vmsh](https://github.com/Mic92/vmsh) in the [vhive](https://github.com/ease-lab/vhive/) lambda environment

Vhive makes available web-endpoints by managing lambda-functions deployed with
[firecracker-containerd](https://github.com/firecracker-microvm/firecracker-containerd)
micro-VMs. Lambda-pirate listens for errors in those lambda-functions and then
spawns a debug container with shell access into it. The debug container is
attached by vmsh which supports multiple hypervisors and guest linux kernel
versions. Furthermore vmsh is agnostic towards the micro-VMs userspace like
networking and its running services (specifically ssh) which gives developers
freedom to change their hypervisor and boot images in a race to the fastest and
most lightweight micro-VM.

Supported OS: NixOS

Status: experimental

**To reproduce the usecase as presented in the VMSH paper, follow this [guide](EVALUATION.md)**

## Getting Started

### 1. Clone lambda-pirate

```console
$ git clone https://github.com/pogobanane/lambda-pirate.git
$ cd lambda-pirate
```

### 2. Nix Flake Setup

We use [nix](https://nixos.org/download.html) with [nix flakes](https://nixos.wiki/wiki/Flakes) to build
modules.

To list all defined components use:

``` console
$ nix flake show
```

Packages can be built into `result/` with `nix build .#$pkgname` i.e.:

``` console
$ nix build .#vhive
```

Enter the development shell to load and make available all command line dependencies and variables:

```console 
$ nix develop
```

### 3. NixOS setup

If you are working on evaluation machines provided by us, please skip this step as it is already completed.

In NixOS one can include the nixos modules in their configuration to deploy a
single-node [k3s](https://k3s.io),
[firecracker-containerd](https://github.com/firecracker-microvm/firecracker-containerd),
[containerd](https://containerd.io/), [knative](https://knative.dev) and
[vhive](https://github.com/ease-lab/vhive). 

To do so include the following configuration in your flake.nix

```nix
{
    description = "NixOS configuration";
    inputs.lambda-pirate.url = "github:pogobanane/lambda-pirate";
    outputs = { nixpkgs, lambda-pirate }: {
      bernie = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # replace with your arch
        modules = [
          ./configuration.nix # or whatever configuration you use...
          lambda-pirate.nixosModules.knative
          lambda-pirate.nixosModules.vhive
          ({ config, ... }: {
            # for lambda pirate
            services.vhive.dockerRegistryIp = 1.1.1.1; # the ipv4 of this machine
          })
        ];
      };
    };
}
```

Checkout the nixos modules in [nix/modules](./nix/modules) for further details. Finally apply the changes and start the services 

``` console
$ nixos-rebuild switch
```

###  4. Deploy knative

After adding the nixos modules, the kubernetes manifests have to be deployed:

```console
$ just reset
$ sudo -E kubectl get pod --all-namespaces
NAMESPACE          NAME                                              READY   STATUS      RESTARTS   AGE
kube-system        metrics-server-86cbb8457f-89hls                   1/1     Running     0          5m49s
kube-system        local-path-provisioner-5ff76fc89d-k6qlg           1/1     Running     0          5m49s
kube-system        coredns-7448499f4d-v67ps                          1/1     Running     0          5m49s
metallb-system     controller-8687cdc65-jk4bl                        1/1     Running     0          5m45s
metallb-system     speaker-q5vbb                                     1/1     Running     0          5m45s
kube-system        calico-kube-controllers-8654f74bf8-rnw98          1/1     Running     0          5m44s
default            minio-deployment-877b8596f-b8j29                  1/1     Running     0          5m45s
istio-system       istiod-796c467-grbsl                              1/1     Running     0          5m39s
istio-system       cluster-local-gateway-949654c8d-wn6fw             1/1     Running     0          3m41s
istio-system       istio-ingressgateway-59c64f5f9c-hgk2z             1/1     Running     0          3m41s
knative-serving    istio-webhook-56748b47-p9wbb                      1/1     Running     0          3m9s
knative-eventing   eventing-controller-55b6f79c99-6bfdg              1/1     Running     0          3m10s
knative-eventing   eventing-webhook-67877858b4-llt8g                 1/1     Running     0          3m10s
knative-eventing   imc-controller-5f4bdf86cf-z54tl                   1/1     Running     0          3m7s
knative-eventing   mt-broker-ingress-546d6868c9-p2qn5                1/1     Running     0          3m7s
knative-eventing   mt-broker-filter-685f7f46d8-bcf54                 1/1     Running     0          3m7s
knative-serving    networking-istio-5db557d5c4-zn2vw                 1/1     Running     0          3m9s
knative-eventing   imc-dispatcher-6c664678f9-9nzgt                   1/1     Running     0          3m7s
knative-eventing   mt-broker-controller-cffcc449c-v594x              1/1     Running     0          3m7s
knative-serving    default-domain-zcr5v                              0/1     Error       0          3m8s
knative-serving    default-domain-9wztl                              0/1     Error       0          91s
knative-serving    webhook-89656b4c5-2m9h7                           1/1     Running     0          3m12s
knative-serving    autoscaler-569cfb8b96-8mlvn                       1/1     Running     0          3m12s
knative-serving    controller-74f8f6ccb8-b5q7k                       1/1     Running     0          3m12s
knative-serving    activator-6d7f96d7fc-6jlk8                        1/1     Running     0          3m12s
knative-serving    default-domain-t75n7                              0/1     Completed   0          81s
kube-system        canal-59rld                                       1/2     Running     0          5m44s
default            hellooopsie-0-00001-deployment-94c4d9c74-2q4zf    2/2     Running     0          19s
```

### 5. Pirate your lambda

The vhive deployer has now started a hellooopsie lambda which produces an error
every 15 seconds. Start lambda-pirate (`just lambda-pirate`) and wait until an
error is detected and vmsh is attached to the micro VM.


## Development

To use your locally checked out lambda-pirate, replace `inputs.lambda-pirate.url` with a string/path to it.

To use your own local vhive build, check the commented paths in:

- justfile
- nix/modules/vhive.nix

To clean deploy after you made your changes (deletes k3s/containerd completely everything!)

```console
$ nixos-rebuild switch
$ just reset
```

