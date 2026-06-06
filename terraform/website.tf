resource "azurerm_container_app" "website" {
  for_each = local.environments

  name                         = "ca-website-${each.key}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app["website-${each.key}"].id]
  }

  dynamic "secret" {
    for_each = local.website_secret_ids[each.key]
    content {
      name                = secret.key
      key_vault_secret_id = secret.value
      identity            = azurerm_user_assigned_identity.app["website-${each.key}"].id
    }
  }

  registry {
    server               = "ghcr.io"
    username             = var.ghcr_username
    password_secret_name = "ghcr-password"
  }

  template {
    min_replicas = local.app_config[each.key].min_replicas
    max_replicas = 10

    container {
      name   = "website"
      image  = var.images[each.key]
      cpu    = local.app_config[each.key].cpu
      memory = local.app_config[each.key].memory

      env {
        name  = "DIRECTUS_URL"
        value = "https://${azurerm_container_app.cms[each.key].ingress[0].fqdn}"
      }
      env {
        name        = "DIRECTUS_TOKEN"
        secret_name = "directus-token"
      }

      liveness_probe {
        transport     = "TCP"
        port          = 3000
        initial_delay = 0
        timeout       = 5
      }

      readiness_probe {
        transport               = "TCP"
        port                    = 3000
        interval_seconds        = 5
        timeout                 = 5
        failure_count_threshold = 48
        success_count_threshold = 1
      }

      startup_probe {
        transport               = "TCP"
        port                    = 3000
        failure_count_threshold = 240
        interval_seconds        = 1
        timeout                 = 3
        initial_delay           = 1
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags       = merge(local.common_tags, { environment = each.key })
  depends_on = [time_sleep.wait_for_kv_rbac, azurerm_container_app.cms]
}
