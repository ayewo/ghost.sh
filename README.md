# ⚡️ ghost.sh
[![Twitter Follow](https://img.shields.io/twitter/follow/ayewo_?style=social)](https://twitter.com/ayewo_)
[![GitHub Repo stars](https://img.shields.io/github/stars/ayewo/ghost.sh?style=social)](https://github.com/ayewo/ghost.sh)

`ghost.sh` is a 1-Click solution that makes it a breeze ⚡️ to self-host Ghost on [Ubuntu Linux](https://ghost.org/docs/install/ubuntu/). 

## Still a WIP!
> [!IMPORTANT]
> **Targeting a v1.0 release but not there yet because I've not had time to finish up the TODOs I left in the code.**


## Why?
Ghost offers an easy-to-use [1-Click App](https://marketplace.digitalocean.com/apps/ghost) on the DigitalOcean Marketplace but the 1-Click App is not available on other cloud providers. `ghost.sh` plans to fix that by being a 1-Click solution for installing Ghost on any cloud provider, starting with AWS. 

You can read more about what motivated me to start this project on my blog: [ghost.sh](https://ayewo.com/ghost-sh/).

## Dependencies
You will need to have to following CLI tools installed:
- Terraform (tested on v1.5.2+)

Install [Terraform](https://www.terraform.io) on your machine.

* On macOS use [`brew`](https://formulae.brew.sh/formula/terraform#default):
    
  ```bash
  brew tap hashicorp/tap
  brew install hashicorp/tap/terraform
  
  terraform --version
  Terraform v1.5.2
  on darwin_amd64
  ```
    
* On Ubuntu use [`snap`](https://snapcraft.io/terraform):
    
  ```bash
  sudo snap install terraform --classic
  
  terraform -version
  Terraform v1.5.3
  on linux_amd64
  ```



## Getting Started
1. **Clone this repo** to the path `~/ghost.sh/` on your machine:
   
    ```bash
    mkdir ~/ghost.sh && cd ~/ghost.sh
    git clone https://github.com/ayewo/ghost.sh .
    ```

2. **Create SSH keys** for administering the instance that will be created by Terraform:
   
    ```bash
    mkdir -p ~/ghost.sh_ssh/
    ssh-keygen -t ed25519 -C "ghost-mgr@ghost.sh" -f ~/ghost.sh_ssh/ghost_admin_ssh_key
    ```
    
    Alternatively, if you have existing SSH keys, you can specify them in `terraform.tfvars` inside the `~/ghost.sh/` folder:
    ```bash
    cat << EOF > terraform.tfvars
    ghost_admin_email           = "admin@example.com"
    ghost_admin_ssh_public_key  = "path/to/ssh/key.pub"
    ghost_admin_ssh_private_key = "path/to/ssh/key"%
    EOF
    ```

3. **Specify your AWS `credentials`**[^iam-note] inside `~/.aws/credentials`: 

    ```bash
    mkdir -p ~/.aws && cat << EOF > ~/.aws/credentials
    # iam-user-with-admin-privileges
    [default]
    aws_access_key_id=AKIAIOSFODNN7EXAMPLE
    aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    EOF
    ```
    
    Alternatively, you can use environment variables:
    ```bash
    export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
    export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    ```

4. **Run the code**:
    ```bash
    terraform init
    terraform apply -auto-approve
    ```



## SSL certificates
Ghost-CLI provisions certificates from Let's Encrypt using [acme.sh](https://github.com/acmesh-official/acme.sh). `ghost.sh` requests one automatically when **both** are true:

1. you set `ghost_blog_domain`, and
2. one of that domain's DNS `A` records already points at the server.

Otherwise the blog falls back to a [nip.io](https://nip.io) domain derived from the server's IP and is served over plain HTTP. That fallback is deliberate: Let's Encrypt applies its rate limits per registered domain, and `nip.io` is not on the [Public Suffix List](https://publicsuffix.org/), so every `nip.io` user shares a single quota. Requesting a certificate there fails often, and the failure would take the rest of `ghost setup` down with it.

Two variables adjust this:

| Variable | Default | Effect |
|---|---|---|
| `ghost_ssl_staging` | `false` | Issue from Let's Encrypt's staging CA. The certificate is untrusted by browsers, but rehearsing a deploy this way does not spend the production rate limit. |
| `ghost_ssl_force` | `false` | Request a certificate even on the `nip.io` fallback domain. |

To add a certificate later, point your DNS at the server and then run:

```bash
ssh -i ~/ghost.sh_ssh/ghost_admin_ssh_key ghost-mgr@<server-ip>
cd /var/www/ghost
ghost config --url https://your-domain.com
ghost setup ssl --sslemail you@example.com
```


## What got installed
Provisioning writes a manifest of every version it installed to `/etc/ghost.sh/versions.json`, alongside `/etc/ghost.sh/install.env` recording the URL and SSL mode the blog was set up with. `terraform apply` prints both at the end of its run.

```bash
$ cat /etc/ghost.sh/versions.json
{
  "generated_at": "<UTC timestamp of the run>",
  "blog":     { "url": ..., "ssl": "letsencrypt | letsencrypt-staging | none" },
  "os":       { "name": ..., "version": ..., "kernel": ... },
  "versions": { "nginx": ..., "mysql": ..., "node": ..., "npm": ...,
                "ghost-cli": ..., "ghost": ..., "acme.sh": ... }
}
```

A version reads as `""` when that tool is not present, so the manifest is also how you tell that a piece of the stack failed to install.

Re-run `sudo ghost.sh-versions` on the server to refresh it after a `ghost update`.


## Trivia
The name `ghost.sh` can be expanded to mean "Ghost **S**elf **H**osting".


## License
Licensed under the [MIT License](LICENSE).

Ghost is a trademark of The Ghost Foundation. *This project is not affiliated with The Ghost Foundation.*

[^iam-note]: ☂️ Please use an IAM user with the ability to create resources in your AWS organization, otherwise you will receive the dreaded `"UnauthorizedOperation: You are not authorized to perform this operation"` error and the deploymnent will fail.
