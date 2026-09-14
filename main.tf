# 1. Azure Ressourcengruppe (Grundkonfiguration)
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags = {
    Kurs      = "DLBSEPCP01_D"
    Student   = "Dennis Krieg"
    Portfolio = "Phase 2 - Cloud Programming"
  }
}

# 2. KOMPONENTE 1: Azure Storage Account
resource "azurerm_storage_account" "static_site" {
  name                     = "stdkphase2web01"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = azurerm_resource_group.rg.tags
}

# Automatisches Deployment der HTML-Dateien in den $web-Container
resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.static_site.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = file("${path.module}/../frontend/index.html")
}

resource "azurerm_storage_blob" "error_html" {
  name                   = "404.html"
  storage_account_name   = azurerm_storage_account.static_site.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = file("${path.module}/../frontend/404.html")
}

# 3. KOMPONENTE 2: Azure Functions
# Speicher für die Function-Laufzeitumgebung
resource "azurerm_storage_account" "func_storage" {
  name                     = "stfndkphase2prod01"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# Serverless Consumption Plan
resource "azurerm_service_plan" "consumption" {
  name                = "asp-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = "Y1"
}

# Function App
resource "azurerm_windows_function_app" "api" {
  name                = "fn-dkphase2-api"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.func_storage.name
  storage_account_access_key = azurerm_storage_account.func_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.consumption.id

  site_config {
    application_stack {
      node_version = "~20"
    }
    # CORS für den Storage-Endpunkt erlauben
    cors {
      allowed_origins = [
        "https://stdkphase2web01.z1.web.core.windows.net",
        "*"
      ]
      support_credentials = false
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    "WEBSITE_RUN_FROM_PACKAGE" = "0"
  }

  tags = azurerm_resource_group.rg.tags
}

# 4. KOMPONENTE 3: Azure Front Door (Beispielskript, da fehlende Berechtigung)
resource "azurerm_cdn_frontdoor_profile" "afd" {
  name                = "afd-${var.project_name}-prod"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = azurerm_resource_group.rg.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "fde-${var.project_name}-prod"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
}

resource "azurerm_cdn_frontdoor_origin_group" "og_static" {
  name                     = "og-static-web"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "origin_storage" {
  name                          = "origin-storage"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.og_static.id
  enabled                       = true

  certificate_name_check_enabled = true
  host_name                      = azurerm_storage_account.static_site.primary_web_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_storage_account.static_site.primary_web_host
  priority                       = 1
  weight                         = 1000
}

resource "azurerm_cdn_frontdoor_route" "route_static" {
  name                          = "route-static"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.og_static.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.origin_storage.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/css", "application/javascript"]
  }
}