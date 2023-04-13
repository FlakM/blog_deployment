# blog_deployment


```bash
git clone git@github.com:FlakM/blog_deployment.git
cd blog_deployment
direnv allow

aws sso login --profile AdministratorAccess-757031708232

# check if env variables are setup in current shell without passing them to history
eval "$(cat ./setup.sh)"


# unset if you've made a mistake
unset CLOUDFLARE_API_TOKEN TF_VAR_ZONE_ID

terraform init
terraform plan

```


Once the `terraform apply` is done there should be a ssh key in the directory that enables us to connect to the machine:

```bash
# there will be a public dns entry in the output
ssh -v root@flakm.com
```

Since the ami image is pretty old the system versions are also not so fresh:

```bash
> nix-channel --list
nixos https://nixos.org/channels/nixos-20.09
> nix --version
nix (Nix) 2.11.1
```

One might upgrade the versions to something more current using [the official instructions](https://nixos.org/manual/nix/stable/installation/upgrading.html) or build own ami.



export CLOUDFLARE_API_TOKEN="$(read -sr VAR_VALUE)"


echo "Please enter the value for CLOUDFLARE_API_TOKEN:"; read -sr VAR_VALUE && export CLOUDFLARE_API_TOKEN="$VAR_VALUE"

# use gpg-agent
export NIX_SSHOPTS="-o IdentityAgent=$SSH_AUTH_SOCK"
nixos-rebuild --flake .#blog \
  --target-host root@blog.flakm.com  \
  switch





