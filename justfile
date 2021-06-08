sign-drone:
  DRONE_SERVER=https://drone.thalheim.io \
  DRONE_TOKEN=$(cat $HOME/.secret/drone-token) \
    nix shell --inputs-from .# 'nixpkgs#drone-cli' -c drone sign pogobanane/lambda-pirate --save
