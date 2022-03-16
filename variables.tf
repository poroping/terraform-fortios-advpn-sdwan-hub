variable "interfaces" {
  type = set(object({
    interface_id   = number
    interface_name = string
    local_gw       = string
    nat_ip         = string
    tunnel_subnet  = string
    }
  ))
  validation {
    condition = alltrue([
      for hub in var.interfaces : hub.interface_id >= 0 && hub.interface_id <= 99
    ], )
    error_message = "Value of interface_id must be between 0 and 99 inclusive."
  }
  description = "Set of interface objects.\ninterface_id is significant to hub.\ninterface_name is name of parent interface to bind tunnel to.\nlocal_gw is local gateway for phase1-interface.\nnat_ip is ext IP if hub behind NAT.\ntunnel_subnet is subnet used for dial-in tunnels. "
}

variable "networks" {
  type        = set(string)
  description = "Networks to add to BGP networks."
  default     = []
}

variable "bgp_as" {
  type        = number
  description = "BGP AS to use for ADVPN."
  default     = 65000
}

variable "vdom" {
  type        = string
  description = "VDOM to apply configuration."
  default     = "root"
}

variable "hub_id" {
  type = number
  validation {
    condition     = var.hub_id >= 0 && var.hub_id <= 99
    error_message = "Value must be between 0 and 99 inclusive."
  }
  description = "Hub ID - single digit int."
  default     = 1
}

variable "sla_loopback_ip" {
  type        = string
  description = "Loopback address for SLA and VPN tunnel monitoring."
  default     = "169.254.255.255/32"
}

variable "ipsec_proposal" {
  type        = string
  description = "List of proposals separated by whitespace."
  default     = "aes256-sha256"
}

variable "ipsec_psk" {
  type        = string
  description = "Pre-shared key for IPSEC tunnels."
  default     = null
}

variable "ipsec_dhgrp" {
  type        = string
  description = "List of dhgrp separated by whitespace."
  default     = "14"
}

variable "vpn_name_prefix" {
  type        = string
  description = "Used to prefix advpn interface name."
  default     = "advpn-"
  validation {
    condition     = length(var.vpn_name_prefix) < 9
    error_message = "Length of string must be max 8 due to interface name length restrictions."
  }
}
