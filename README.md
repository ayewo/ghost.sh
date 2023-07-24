# ghost.sh
[![Twitter Follow](https://img.shields.io/twitter/follow/ayewo_?style=social)](https://twitter.com/ayewo_)
[![GitHub Repo stars](https://img.shields.io/github/stars/ayewo/ghost.sh?style=social)](https://github.com/ayewo/ghost.sh)

`ghost.sh` is a 1-Click solution for self-hosting Ghost on [Ubuntu Linux](https://ghost.org/docs/install/ubuntu/). 

Ghost offers an easy-to-use [1-Click App](https://marketplace.digitalocean.com/apps/ghost) on the DigitalOcean Marketplace but the 1-Click App is not available on other cloud providers. `ghost.sh` plans to fix that by being a 1-Click solution for installing Ghost on any cloud provider, starting with AWS. 

## Dependencies
You will need to have to following CLI tools installed:
- Terraform (tested on v1.5.2+)

## Getting Started
1. Install [Terraform](https://www.terraform.io) on your machine.

On macOS use [`brew`](https://formulae.brew.sh/formula/terraform#default):
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

terraform --version
Terraform v1.5.2
on darwin_amd64
```
On Ubuntu use [`snap`](https://snapcraft.io/terraform):
```bash
sudo snap install terraform --classic

terraform -version
Terraform v1.5.3
on linux_amd64
```

2. Clone this repo.
```bash
mkdir ~/ghost.sh && cd ~/ghost.sh
git clone https://github.com/ayewo/ghost.sh .
```

3. Create an SSH for administering the instance that will be created by Terraform. 
```bash
mkdir -p ~/ghost.sh_ssh/
ssh-keygen -t ed25519 -C "ghost-mgr@ghost.sh" -f ~/ghost.sh_ssh/ghost_admin_ssh_key
```
Alternatively, if you have an existing SSH key, you can specify it inside `terraform.tfvars`. Please create your `terraform.tfvars` inside the `~/ghost.sh` folder:
```bash
cat << EOF > terraform.tfvars
ghost_admin_email           = "admin@example.com"
ghost_admin_ssh_public_key  = "path/to/ssh/key.pub"
ghost_admin_ssh_private_key = "path/to/ssh/key"%
EOF
```

4. Create an AWS `credentials` file with valid keys. Please use an IAM user with the ability to create resources in your AWS organization otherwise you will receive the 
dreaded *"UnauthorizedOperation: You are not authorized to perform this operation"* error and the deploymnent will fail.
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

5. Next run Terraform:
```bash
terraform init
terraform apply -auto-approve
```



## Trivia
The name `ghost.sh` can be expanded to mean "Ghost **S**elf **H**osting".


## License
[MIT License](LICENSE)

Ghost is a trademark of The Ghost Foundation. *This project is not affiliated with The Ghost Foundation.*
