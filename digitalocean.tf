# ----------------------------------------------------------------------------
# DigitalOcean: created when cloud_provider = "digitalocean"
# ----------------------------------------------------------------------------

# A droplet created without any ssh_keys gets a root password mailed out and
# password authentication left on, so the key is registered even though
# cloud-init installs it for ghost-mgr as well. If this public key is already on
# your DigitalOcean account, the create will be refused as a duplicate -- either
# remove it there or `terraform import` it here.
resource "digitalocean_ssh_key" "ghost_admin" {
  count = local.on_digitalocean ? 1 : 0

  name       = "${var.prefix}_${var.ghost_admin}"
  public_key = data.local_file.ghost_admin_ssh_public_key.content
}

# Reserved before the droplet so its address can be templated into the
# cloud-config; digitalocean_reserved_ip_assignment attaches it afterwards.
resource "digitalocean_reserved_ip" "eip" {
  count = local.on_digitalocean ? 1 : 0

  region = var.do_region
}

resource "digitalocean_reserved_ip_assignment" "reserved_ip_assignment" {
  count = local.on_digitalocean ? 1 : 0

  ip_address = digitalocean_reserved_ip.eip[0].ip_address
  droplet_id = digitalocean_droplet.web_server[0].id
}

resource "digitalocean_droplet" "web_server" {
  count = local.on_digitalocean ? 1 : 0

  image     = var.do_image
  name      = local.instance_name
  region    = var.do_region
  size      = var.do_droplet_size
  ssh_keys  = [digitalocean_ssh_key.ghost_admin[0].fingerprint]
  user_data = local.cloud_config

  # Free, and the only way to see memory pressure on a 1 GB droplet.
  monitoring = true

  tags = [replace("${var.prefix}_${var.instance_name}", ".", "-")]

  # The provisioning checks run from terraform_data.provisioning_checks in
  # main.tf, so that the reserved IP is assigned before cloud-init needs it.
  provisioner "local-exec" {
    command    = "echo The droplet IP address is ${self.ipv4_address}."
    on_failure = continue
  }

  provisioner "local-exec" {
    command    = "echo The droplet [Reserved] IP address is ${digitalocean_reserved_ip.eip[0].ip_address} and is about to be assigned."
    on_failure = continue
  }
}

resource "digitalocean_firewall" "ghost_firewall" {
  count = local.on_digitalocean ? 1 : 0

  name        = "${var.prefix}_firewall"
  droplet_ids = [digitalocean_droplet.web_server[0].id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Egress has to stay open: the install pulls from apt, npm and Let's Encrypt.
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # DNS resolution and Let's Encrypt's HTTP-01 challenge both need ICMP to be
  # unblocked for reliable path-MTU discovery.
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
