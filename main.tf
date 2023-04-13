terraform {
  cloud {
    organization = "flakm_mega_corp"

    workspaces {
      name = "blog"
    }
  }
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

# this is working with aws sso 
# https://discuss.hashicorp.com/t/using-credential-created-by-aws-sso-for-terraform/23075/5
provider "aws" {
    profile = "blog"
    region = "eu-north-1"
}

module "nixos_image" {
    # the url is different since the tutorial one is old and has not been updated
    source  = "git::https://github.com/antoinerg/terraform-nixos.git//aws_image_nixos?ref=bcbddcb246f8d5b2ae879bf101154b74a78b6bc4"
    release = "22.11"
}

resource "aws_security_group" "ssh_and_egress" {
    # ssh
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
   
    # TLS for nginx
    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    # port 80 is required for ACMA challenge
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}


resource "aws_key_pair" "existing_key" {
  key_name   = "yubikey"
  public_key = file("~/.ssh/id_rsa_yubikey.pub")
}

resource "aws_instance" "machine" {
    ami             = module.nixos_image.ami
    instance_type   = "t3.micro"
    security_groups = [ aws_security_group.ssh_and_egress.name ]
    key_name        = aws_key_pair.existing_key.key_name

    root_block_device {
        volume_size = 50 # GiB
    }
}

output "public_ip" {
    value = aws_instance.machine.public_ip
}


provider "cloudflare" {
  # this is taken from CLOUDFLARE_API_TOKEN env 
}

variable "ZONE_ID" {
}

variable "domain" {
  default = "flakm.com"
}


resource "cloudflare_record" "blog_nginx" {
  zone_id = var.ZONE_ID
  name    = "blog.flakm.com"
  value   = aws_instance.machine.public_ip
  type    = "A"
  proxied = false
}



resource "cloudflare_record" "blog" {
  zone_id = var.ZONE_ID
  name    = "@"
  value   = "blog.flakm.com"
  type    = "CNAME"
  proxied = true
}



resource "cloudflare_zone_settings_override" "flakm-com-settings" {
  zone_id = var.ZONE_ID

  settings {
    tls_1_3                  = "on"
    automatic_https_rewrites = "on"
    ssl                      = "strict"
    cache_level              = "aggressive"  # This can be set to "simplified", "aggressive", or "basic" depending on your caching requirements
  }
}
