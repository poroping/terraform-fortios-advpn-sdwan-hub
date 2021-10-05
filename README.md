<!-- BEGIN_TF_DOCS -->
# terraform-fortios-advpn-sdwan-hub

Requires forked version of fortios provider

Does stuff.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_fortios"></a> [fortios](#provider\_fortios) | >= 2.3.4 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_interfaces"></a> [interfaces](#input\_interfaces) | Set of interface objects. interface\_id is significant to hub. interface\_name is name of parent interface to bind tunnel to. local\_gw is local gateway for phase1-interface. nat\_ip is ext IP if hub behind NAT. tunnel\_subnet is subnet used for dial-in tunnels. | <pre>set(object({<br>    interface_id   = number<br>    interface_name = string<br>    local_gw       = string<br>    nat_ip         = string<br>    tunnel_subnet  = string<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_bgp_as"></a> [bgp\_as](#input\_bgp\_as) | BGP AS to use for ADVPN. | `number` | `65000` | no |
| <a name="input_hub_id"></a> [hub\_id](#input\_hub\_id) | Hub ID - single digit int. | `number` | `1` | no |
| <a name="input_interregional_hubs"></a> [interregional\_hubs](#input\_interregional\_hubs) | Set of inter-regional hub objects. | <pre>set(object({<br>    region_name = string<br>    remote_gw   = string<br>    bgp_as      = number<br>    remote_ip   = string<br>    local_ip    = string<br>    }<br>  ))</pre> | `null` | no |
| <a name="input_interregional_interface"></a> [interregional\_interface](#input\_interregional\_interface) | n/a | <pre>object({<br>    name     = string<br>    local_gw = string<br>    nat_ip   = string<br>    }<br>  )</pre> | `null` | no |
| <a name="input_intrahub_hubs"></a> [intrahub\_hubs](#input\_intrahub\_hubs) | Set of intra-regional hub objects. | <pre>set(object({<br>    hub_id    = string<br>    remote_gw = string<br>    # bgp_as      = number<br>    remote_ip = string<br>    local_ip  = string<br>    }<br>  ))</pre> | `null` | no |
| <a name="input_intrahub_interface"></a> [intrahub\_interface](#input\_intrahub\_interface) | n/a | <pre>object({<br>    name     = string<br>    local_gw = string<br>    nat_ip   = string<br>    }<br>  )</pre> | `null` | no |
| <a name="input_networks"></a> [networks](#input\_networks) | Networks to add to BGP networks. | `set(string)` | `[]` | no |
| <a name="input_region_name"></a> [region\_name](#input\_region\_name) | Region name. | `string` | `"adpvn"` | no |
| <a name="input_sla_loopback_ip"></a> [sla\_loopback\_ip](#input\_sla\_loopback\_ip) | Loopback address for SLA and VPN tunnel monitoring. | `string` | `"10.0.0.0/32"` | no |
| <a name="input_vdom"></a> [vdom](#input\_vdom) | VDOM to apply configuration. | `string` | `"root"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_hub"></a> [hub](#output\_hub) | n/a |
<!-- END_TF_DOCS -->