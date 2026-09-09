# ⚡️ ghost.sh
[![Twitter Follow](https://img.shields.io/twitter/follow/ayewo_?style=social)](https://twitter.com/ayewo_)
[![GitHub Repo stars](https://img.shields.io/github/stars/ayewo/ghost.sh?style=social)](https://github.com/ayewo/ghost.sh)

`ghost.sh` is a 1-Click solution that makes it a breeze ⚡️ to self-host Ghost on [Ubuntu Linux](https://ghost.org/docs/install/ubuntu/). 

## Still a WIP!
> [!IMPORTANT]
> **Targeting a v1.0 release but not there yet because I've not had time to finish up the TODOs I left in the code.**


## Why?
Ghost offers an easy-to-use [1-Click App](https://marketplace.digitalocean.com/apps/ghost) on the DigitalOcean Marketplace but the 1-Click App is not available on other cloud providers. `ghost.sh` plans to fix that by being a 1-Click solution for installing Ghost on any cloud provider. **AWS** and **DigitalOcean** are supported today; pick one with `cloud_provider`.

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

3. **Choose a cloud** in `terraform.tfvars`. `aws` is the default, so this step is only needed for DigitalOcean:

    ```bash
    echo 'cloud_provider = "digitalocean"' >> terraform.tfvars
    ```

4. **Specify your cloud credentials.**

    <details open>
    <summary><strong>DigitalOcean</strong></summary>

    A [personal access token](https://cloud.digitalocean.com/account/api/tokens) with write scope, kept in the environment rather than in `terraform.tfvars`:

    ```bash
    export DIGITALOCEAN_TOKEN=dop_v1_<64 hex>
    ```
    </details>

    <details>
    <summary><strong>AWS</strong></summary>

    Your `credentials`[^iam-note] inside `~/.aws/credentials`: 

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
    </details>

    You only need credentials for the cloud you picked. Every resource for the other one is `count = 0`, and Terraform does not ask a provider for credentials it has no resources to manage.

5. **Run the code**:
    ```bash
    terraform init
    terraform apply -auto-approve
    ```



## Choosing a cloud
`cloud_provider` selects the target; everything else about the blog is identical either way.

| | `aws` (default) | `digitalocean` |
|---|---|---|
| Server | `aws_instance`, `t3.small` | `digitalocean_droplet`, `s-1vcpu-1gb` |
| Size variable | `instance_type` | `do_droplet_size` |
| Region | `region`, default `eu-west-2` | `do_region`, default `lon1` |
| Image | newest Ubuntu 24.04 LTS AMI, or `ami_id` | `do_image`, default `ubuntu-24-04-x64` |
| Static address | `aws_eip` | `digitalocean_reserved_ip` |
| Firewall | `aws_security_group` | `digitalocean_firewall` |
| Credentials | `~/.aws/credentials` or `AWS_*` | `DIGITALOCEAN_TOKEN` or `do_token` |

`s-1vcpu-1gb` is Ghost's stated 1 GB minimum rather than a comfortable amount. Two things make it work: the 2 GB swapfile, and a MySQL drop-in at `/etc/mysql/mysql.conf.d/zz-ghost.sh-low-memory.cnf` that turns `performance_schema` off and caps the buffer pool and connection count. Step up to `s-1vcpu-2gb` if you plan to run much beyond a blog.

Outputs are named for the cloud that produced them — `instance_*` on AWS, `droplet_*` on DigitalOcean — and the ones belonging to the cloud you did not pick read `null`. The provider-neutral values are `server_public_ip`, `server_ssh_command` and `server_blog_url`.


## What you get
| Component | Version | Notes |
|---|---|---|
| Ubuntu | 24.04 LTS (Noble) | Looked up from Canonical's AMI catalogue at plan time, so you always get the newest patched image. Override with `ami_id`. |
| Ghost | `6.63.0` | Pinned via `ghost_version`. |
| Ghost-CLI | `1.32.4` | Pinned via `ghost_cli_version`. Ghost 6.63.0 requires `^1.29.1`. |
| Node.js | 22.x | Ghost 6 declares `^22.23.1 \|\| ^24.20.0`; 22 is what Ghost's own install guide uses. |
| MySQL | 8.0 | The only database Ghost supports in production. |
| NGINX + acme.sh | distro / latest | See [SSL certificates](#ssl-certificates). |

Both versions are pinned on purpose: rebuilding the stack six months from now gives you the blog you tested, not whatever is newest that day. Bump them deliberately.

A 2 GB swapfile is provisioned before Ghost installs, because the `npm install` is the memory peak and Ghost's upgrade guide asks for the headroom.


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
| `ghost_ssl_ip_wait` | `300` | Seconds to wait for the reserved address to reach the server before asking for a certificate. |

That last one exists because of an ordering problem worth knowing about. Let's Encrypt validates a certificate against whatever answers on the address your DNS points at, and that is the reserved address — which the cloud can only attach once the server exists. So cloud-init waits for the address to arrive before requesting anything. If it never does, the blog is served over HTTP rather than the build hanging or failing, and the log tells you the one command needed to finish the job later.

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
  "generated_at": "2026-09-09T14:31:07Z",
  "blog": {
    "url": "https://your-domain.com",
    "ssl": "letsencrypt"
  },
  "os": {
    "name": "Ubuntu",
    "version": "24.04.3 LTS (Noble Numbat)",
    "kernel": "6.8.0-79-generic"
  },
  "versions": {
    "nginx": "1.24.0",
    "mysql": "8.0.43",
    "node": "22.23.2",
    "npm": "10.9.4",
    "ghost-cli": "1.32.4",
    "ghost": "6.63.0",
    "acme.sh": "3.1.1"
  }
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
