output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Ressourcengruppe"
}

output "storage_static_web_url" {
  value       = azurerm_storage_account.static_site.primary_web_endpoint
  description = "Live-Endpunkt des statischen Webhostings"
}

output "function_app_url" {
  value       = "https://${azurerm_windows_function_app.api.default_hostname}/api/hello"
  description = "Live-Endpunkt der Serverless API"
}

output "front_door_target_url" {
  value       = "https://${azurerm_cdn_frontdoor_endpoint.endpoint.host_name}"
  description = "Enterprise Front Door Endpunkt (vorbehaltlich Enterprise-Subscription)"
}