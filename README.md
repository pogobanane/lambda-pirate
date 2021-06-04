# λ🏴‍☠️ lambda-pirate
using vmsh in a lambda environment

## To deploy knative (after setting up k3s + vhive nixos module)

``` sh
sudo make -C knative deploy -j$(nproc)
```

## Clean deploy (deletes k3s/containerd completly everyting!)

``` sh
sudo make -C knative burn-down-cluster && sudo make -C knative deploy -j$(nproc)
```

