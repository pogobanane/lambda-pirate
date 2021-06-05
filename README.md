# λ🏴‍☠️ lambda-pirate
using vmsh in a lambda environment

## Build single packages

We use [nix](https://nixos.org/download.html) with [nix flakes](https://nixos.wiki/wiki/Flakes) to build
modules.

To list all defined components use:

``` console
$ nix flake show
```

Packages can be build with `nix build .#$pkgname` i.e.:

``` console
$ nix build .#packages.vhive
```

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
        ];
      };
    };
}
```

Checkout the nixos modules in [nix/modules](./nix/modules) for further details.
If you do changes to the checked out lambda-pirate repository you can also apply
those to NixOS using `--override-input` for `nixos-rebuild`:

``` console
$ nixos-rebuild switch --override-input lambda-pirate ./.
```


## To deploy knative (after setting up k3s + vhive nixos module)

After adding the nixos modules the kubernetes manifests will be deployed.
One can manually run them like that:

```console
$ sudo make -C knative deploy -j$(nproc)
$ sudo -E kubectl get pod --all-namespaces
NAMESPACE          NAME                                       READY   STATUS      RESTARTS   AGE
kube-system        metrics-server-86cbb8457f-lzqng            1/1     Running     0          8m15s
kube-system        calico-kube-controllers-8654f74bf8-nk4s4   1/1     Running     0          8m15s
kube-system        local-path-provisioner-5ff76fc89d-pzn2w    1/1     Running     0          8m15s
kube-system        coredns-7448499f4d-9g5tj                   1/1     Running     0          8m15s
default            minio-deployment-877b8596f-8pt6h           1/1     Running     0          8m15s
metallb-system     controller-8687cdc65-8k6b7                 1/1     Running     0          8m15s
metallb-system     speaker-gxls8                              1/1     Running     0          8m16s
istio-system       istiod-796c467-5krx4                       1/1     Running     0          8m15s
kube-system        canal-jpm7l                                2/2     Running     0          8m16s
istio-system       istio-ingressgateway-59c64f5f9c-rnwm8      1/1     Running     0          6m39s
istio-system       cluster-local-gateway-949654c8d-2kw8n      1/1     Running     0          6m39s
knative-serving    controller-78db6b6d75-xr8db                1/1     Running     0          5m52s
knative-serving    autoscaler-589958b7b6-h7ktt                1/1     Running     0          5m52s
knative-serving    webhook-6cf55b5bbd-rhsql                   1/1     Running     0          5m52s
knative-serving    activator-5c4c8476d5-jmpdq                 1/1     Running     0          5m53s
knative-eventing   eventing-controller-55b6f79c99-xdvfx       1/1     Running     0          5m44s
knative-serving    networking-istio-5db557d5c4-p6nsm          1/1     Running     0          5m25s
knative-serving    istio-webhook-56748b47-8j5fn               1/1     Running     0          5m25s
knative-eventing   eventing-webhook-67877858b4-snw64          1/1     Running     0          5m42s
knative-eventing   imc-controller-5f4bdf86cf-f6v68            1/1     Running     0          5m11s
knative-eventing   mt-broker-filter-685f7f46d8-hwjph          1/1     Running     0          4m59s
knative-eventing   imc-dispatcher-6c664678f9-j2l74            1/1     Running     0          5m11s
knative-eventing   mt-broker-controller-cffcc449c-lm6jc       1/1     Running     0          4m55s
knative-eventing   mt-broker-ingress-546d6868c9-nbbtf         1/1     Running     0          4m57s
knative-serving    default-domain-97lz6                       0/1     Completed   0          5m20s
knative-eventing   eventing-webhook-67877858b4-zwstl          1/1     Running     0          3m37s

```

## Clean deploy (deletes k3s/containerd completly everyting!)

```console
$ sudo make -C knative burn-down-cluster && sudo make -C knative deploy -j$(nproc)
```

