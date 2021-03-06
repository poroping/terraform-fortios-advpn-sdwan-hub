/**
 * # terraform-fortios-advpn-sdwan-hub
 * 
 * Uses forked version of fortios provider
 *
 * Requires FortiOS >= 6.4.5
 *
 * Uses sub-table resources in BGP and SDWAN parent tables. Do not mix and match here.
 * 
 */

terraform {
  required_providers {
    fortios = {
      source  = "poroping/fortios"
      version = ">= 3.1.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}

locals {
  interfaces = { for i in var.interfaces : "${i.interface_name}-${i.interface_id}" => {
    interface_name  = i.interface_name
    interface_id    = i.interface_id
    interface_uid   = "${i.interface_name}-${i.interface_id}"
    local_gw        = i.local_gw == null ? null : i.local_gw
    nat_ip          = i.nat_ip == null ? null : i.nat_ip
    advpn_name      = join("-", [tostring(var.hub_id), tostring(i.interface_id)])
    advpn_longname  = "hub:${tostring(var.hub_id)}-interface:${tostring(i.interface_id)}"
    advpn_id        = join("", [tostring(var.hub_id), tostring(i.interface_id)])
    hub_id          = var.hub_id
    tunnel_subnet   = i.tunnel_subnet
    vpn_name_prefix = var.vpn_name_prefix
  } }
}

resource "random_id" "psk" {
  count = var.ipsec_psk == null ? 1 : 0

  byte_length = 32
}

resource "fortios_vpnipsec_phase1interface" "phase1" {
  for_each = { for i in local.interfaces : i.interface_uid => i }

  vdomparam = var.vdom

  name            = "${each.value.vpn_name_prefix}${each.value.advpn_name}"
  local_gw        = each.value.local_gw
  type            = "dynamic"
  interface       = each.value.interface_name
  ike_version     = 2
  peertype        = "any"
  nattraversal    = each.value.nat_ip == null ? "disable" : "forced"
  network_overlay = "enable"
  network_id      = tonumber(each.value.advpn_id)
  net_device      = "disable"
  proposal        = var.ipsec_proposal
  add_route       = "disable"
  # dpd                   = "on-demand"
  # dpd_retryinterval     = "2 500"
  # dpd_retrycount        = 3
  auto_discovery_sender = "enable"
  tunnel_search         = "nexthop" # removed in 7.0.x+
  psksecret             = var.ipsec_psk == null ? random_id.psk[0].b64_url : var.ipsec_psk
  # dpd_retryinterval     = 5
  mode_cfg      = "enable"
  ipv4_start_ip = cidrhost(each.value.tunnel_subnet, 2)
  ipv4_end_ip   = cidrhost(each.value.tunnel_subnet, -2)
  ipv4_netmask  = cidrnetmask(each.value.tunnel_subnet)
}

resource "fortios_vpnipsec_phase2interface" "phase2" {
  for_each = { for i in local.interfaces : i.interface_uid => i }

  vdomparam = var.vdom

  name       = fortios_vpnipsec_phase1interface.phase1[each.key].name
  phase1name = fortios_vpnipsec_phase1interface.phase1[each.key].name
  proposal   = fortios_vpnipsec_phase1interface.phase1[each.key].proposal
  pfs        = "enable"
  dhgrp      = var.ipsec_dhgrp
}

resource "fortios_system_interface" "vpn_interface" {
  for_each = { for i in local.interfaces : i.interface_uid => i }

  allow_append = true

  description = "Managed by Terraform."
  ip          = "${cidrhost(each.value.tunnel_subnet, 1)}/32"
  name        = fortios_vpnipsec_phase1interface.phase1[each.key].name
  remote_ip   = "${cidrhost(each.value.tunnel_subnet, -2)}/${split("/", each.value.tunnel_subnet)[1]}"
  allowaccess = "ping"
  vdom        = var.vdom
}

resource "fortios_routerbgp_neighbor_group" "group" {
  for_each = { for i in local.interfaces : i.interface_uid => i }

  vdomparam = var.vdom

  name                        = "${each.value.vpn_name_prefix}${each.value.advpn_name}"
  interface                   = fortios_vpnipsec_phase1interface.phase1[each.key].name
  remote_as                   = var.bgp_as
  route_reflector_client      = "enable"
  link_down_failover          = "enable"
  additional_path             = "both"
  adv_additional_path         = 4
  capability_graceful_restart = "enable"
  capability_route_refresh    = "enable"
  soft_reconfiguration        = "enable"
  next_hop_self               = "enable"
  next_hop_self_rr            = "disable"
  keep_alive_timer            = 7
  holdtime_timer              = 21
  advertisement_interval      = 5

  lifecycle {
    create_before_destroy = true
  }
}

resource "fortios_routerbgp_neighbor_range" "range" {
  for_each = { for i in local.interfaces : i.interface_uid => i }

  vdomparam = var.vdom

  neighbor_group = fortios_routerbgp_neighbor_group.group[each.key].name
  prefix         = each.value.tunnel_subnet
}

resource "fortios_routerbgp_network" "networks" {
  for_each = var.networks

  vdomparam = var.vdom

  prefix = each.key
}

# advertise dial_up_vpn_subnets
resource "fortios_routerbgp_network" "dial_up_vpn_subnets" {
  for_each = { for i in local.interfaces : i.interface_uid => i }

  vdomparam = var.vdom

  prefix = each.value.tunnel_subnet
}

resource "fortios_system_interface" "sla_loop" {
  allow_append = true

  type        = "loopback"
  name        = "${var.vpn_name_prefix}SLA"
  ip          = var.sla_loopback_ip
  allowaccess = "ping"
  vdom        = var.vdom

  lifecycle {
    create_before_destroy = true
  }
}

# advertise sla loopback
resource "fortios_routerbgp_network" "sla_loop" {
  vdomparam = var.vdom

  prefix = fortios_system_interface.sla_loop.ip
}

# resource "fortios_system_sdwan" "sdwan" {
#   vdomparam = var.vdom

#   status = "enable"

#   lifecycle {
#     ignore_changes = [
#       duplication,
#       health_check,
#       members,
#       neighbor,
#       service,
#       zone
#     ]
#   }
# }

resource "fortios_system_sdwan_zone" "zone" {
  vdomparam = var.vdom

  name = "sdwan-hub${tostring(var.hub_id)}"
}

resource "fortios_system_sdwan_members" "hub" {
  for_each = { for i in local.interfaces : i.interface_uid => i }

  vdomparam = var.vdom

  seq_num   = tonumber(each.value.advpn_id)
  interface = fortios_vpnipsec_phase1interface.phase1[each.key].name
  zone      = fortios_system_sdwan_zone.zone.name
}

resource "fortios_system_sdwan_service" "hub" {
  for_each = { for i in local.interfaces : i.interface_uid => i }

  vdomparam = var.vdom

  name = "${each.value.advpn_longname}-all"

  input_device {
    name = fortios_vpnipsec_phase1interface.phase1[each.key].name
  }

  dst {
    name = "all"
  }

  src {
    name = "all"
  }

  priority_members {
    seq_num = fortios_system_sdwan_members.hub[each.key].seq_num
  }

  dynamic "priority_members" {
    for_each = setsubtract([for int in local.interfaces : int.advpn_id], [fortios_system_sdwan_members.hub[each.key].seq_num])

    content {
      seq_num = priority_members.value
    }
  }

}

resource "fortios_firewall_policy" "sla_loop" {
  vdomparam = var.vdom

  action   = "accept"
  name     = "ADVPN to SLA LOOPBACK"
  schedule = "always"

  dstaddr {
    name = "all"
  }

  dstintf {
    name = fortios_system_interface.sla_loop.name
  }

  service {
    name = "PING"
  }

  srcaddr {
    name = "all"
  }

  srcintf {
    name = fortios_system_sdwan_zone.zone.name
  }
}

data "fortios_router_bgp" "bgp" {

}

data "fortios_system_interface" "parent_interfaces" {
  for_each = { for i in local.interfaces : i.interface_uid => i }

  name = each.value.interface_name
}

locals {
  hub_links = [for i in local.interfaces : {
    advpn_id   = fortios_vpnipsec_phase1interface.phase1[i.interface_uid].network_id
    advpn_name = fortios_vpnipsec_phase1interface.phase1[i.interface_uid].name
    remote_gw  = i.nat_ip != null ? i.nat_ip : i.local_gw != null ? i.local_gw : try(split(" ", data.fortios_system_interface.parent_interfaces[i.interface_uid].ip)[0], null)
    tunnel_ip  = split("/", fortios_system_interface.vpn_interface[i.interface_uid].ip)[0]
  }]
  hub_info = {
    bgp_as              = data.fortios_router_bgp.bgp.as
    hub_id              = var.hub_id
    hub_loopback        = fortios_system_interface.sla_loop.ip
    links               = local.hub_links
    dial_up_vpn_subnets = [for subnet in fortios_routerbgp_network.dial_up_vpn_subnets : subnet.prefix]
  }

}

output "hub" {
  description = "Hub information."
  value       = local.hub_info
}

output "psk" {
  description = "Outputs PSK if auto generated. Null if provided."
  value       = var.ipsec_psk == null ? random_id.psk[0].b64_url : null
}
