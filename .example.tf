terraform {
  required_version = ">= 1.0.1"
  backend "local" {}
  required_providers {
    fortios = {
      source  = "poroping/fortios"
      version = ">= 3.1.4"
    }
  }
}

provider "fortios" {
  alias    = "hub1"
  hostname = "192.168.1.99"
  token    = "supertokens"
  vdom     = "root"
  insecure = "true"
}

## Hub Info

data "fortios_system_interface" "hub1_1" {
  provider = fortios.hub1

  name = "port1"
}

data "fortios_system_interface" "hub1_2" {
  provider = fortios.hub1

  name = "port1"
}

locals {
  hub1_interfaces = [
    {
      interface_name = data.fortios_system_interface.hub1_1.name
      interface_id   = 1
      local_gw       = null
      cost           = null
      nat_ip         = null
      tunnel_subnet  = "169.254.101.0/24"
    },
    {
      interface_name = data.fortios_system_interface.hub1_2.name
      interface_id   = 2
      local_gw       = null
      cost           = null
      nat_ip         = null
      tunnel_subnet  = "169.254.102.0/24"
    }
  ]
  hub1_bgp_as = 64420
}

# BGP pre-reqs

resource "fortios_router_bgp" "hub1" {
  provider = fortios.hub1

  vdomparam = "root"

  as                     = local.hub1_bgp_as
  router_id              = "1.1.1.1"
  ibgp_multipath         = "enable"
  additional_path        = "enable"
  additional_path_select = 4

  # ignore subtables
  lifecycle {
    ignore_changes = [
      aggregate_address,
      aggregate_address6,
      network,
      network6,
      neighbor,
      neighbor_group,
      neighbor_range,
      neighbor_range6,
      admin_distance
    ]
  }
}

module "advpnhub1" {
  providers = {
    fortios = fortios.hub1
  }
  source  = "poroping/advpn-sdwan-hub/fortios"
  version = "~> 0.0.15"

  bgp_as          = local.hub1_bgp_as
  interfaces      = local.hub1_interfaces
  hub_id          = 1
  vdom            = "root"
  sla_loopback_ip = "169.254.255.1/32"
}

# Make sure hub networks are advertised towards spokes example:

resource "fortios_routerbgp_network" "hub1_nets" {
  provider = fortios.hub1
  for_each = toset(["192.168.1.0/24"])

  vdomparam = "root"

  prefix = each.key

  depends_on = [
    fortios_router_bgp.hub1
  ]
}

# Basic any-any policies to bring up tunnel

resource "fortios_firewall_policy" "in1" {
  provider = fortios.hub1

  action   = "accept"
  schedule = "always"

  dstaddr {
    name = "all"
  }

  dstintf {
    name = "port2"
  }

  service {
    name = "ALL"
  }

  srcaddr {
    name = "all"
  }

  srcintf {
    name = "sdwan-hub1"
  }

  depends_on = [
    module.advpnhub1
  ]
}

resource "fortios_firewall_policy" "out1" {
  provider = fortios.hub1

  action   = "accept"
  schedule = "always"

  dstaddr {
    name = "all"
  }

  dstintf {
    name = "sdwan-hub1"
  }

  service {
    name = "ALL"
  }

  srcaddr {
    name = "all"
  }

  srcintf {
    name = "port2"
  }

  depends_on = [
    module.advpnhub1
  ]
}
