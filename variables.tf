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
      ],
      length(hub.interface_name) < 14
    )
    error_message = "Value of interface_id must be between 0 and 99 inclusive. String length of interface_name must be < 14 due to tunnel naming restrictions."
  }
  description = "Set of interface objects. interface_id is significant to hub. interface_name is name of parent interface to bind tunnel to. local_gw is local gateway for phase1-interface. nat_ip is ext IP if hub behind NAT. tunnel_subnet is subnet used for dial-in tunnels. "
}

variable "networks" {
  type        = set(string)
  description = "Networks to add to BGP networks."
  default     = []
}

variable "region_name" {
  type        = string
  description = "Region name."
  default     = "adpvn"
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
  default     = "10.0.0.0/32"
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