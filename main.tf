# Validation logic for configuration requirements
locals {
  # GitHub authentication validation - avoid referencing sensitive values in error message
  github_auth_failed = var.enable_github_authentication == true && (var.github_client_id == "" || var.github_client_secret == "")
  github_auth_error  = local.github_auth_failed ? "GitHub authentication is enabled but required credentials are missing. Both github_client_id and github_client_secret must be provided." : null

  # Authentication method validation  
  auth_method_failed = var.enable_github_authentication == false && var.enable_password_authentication == false
  auth_method_error  = local.auth_method_failed ? "At least one authentication method must be enabled. Set either enable_github_authentication or enable_password_authentication to true." : null

  # Registry authentication validation - avoid referencing sensitive values in error message
  registry_auth_failed = var.selfservice_ui_registry_auth_enabled == true && (var.selfservice_ui_registry_username == "" || var.selfservice_ui_registry_password == "")
  registry_auth_error  = local.registry_auth_failed ? "Registry authentication is enabled but required credentials are missing. Both selfservice_ui_registry_username and selfservice_ui_registry_password must be provided." : null

  # Combine all validation errors
  validation_errors = compact([
    local.github_auth_error,
    local.auth_method_error,
    local.registry_auth_error
  ])

  # Create a single error message that doesn't reference sensitive values
  validation_error_message = length(local.validation_errors) > 0 ? join(" | ", local.validation_errors) : ""
}

# Use null_resource to trigger validation errors
resource "null_resource" "validation" {
  count = length(local.validation_errors) > 0 ? 1 : 0

  lifecycle {
    precondition {
      condition     = length(local.validation_errors) == 0
      error_message = nonsensitive(local.validation_error_message)
    }
  }
}

resource "helm_release" "ory-db" {
  name       = var.kratos_db_release_name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  namespace  = var.kratos_namespace

  create_namespace = true

  set = [
    {
      name  = "global.postgresql.auth.username"
      value = var.kratos_db_username
    },
    {
      name  = "global.postgresql.auth.password"
      value = var.kratos_db_password
    },
    {
      name  = "global.postgresql.auth.postgresPassword"
      value = var.kratos_db_admin_password
    },
    {
      name  = "global.postgresql.auth.database"
      value = var.kratos_db_name
    },
    {
      name  = "primary.persistence.enabled"
      value = var.kratos_db_persistence_enabled
    },
    {
      name  = "containerPorts.postgresql"
      value = var.kratos_db_port
    },
    {
      name  = "primary.service.ports.postgresql"
      value = var.kratos_db_port
    }
  ]
}

resource "helm_release" "kratos" {
  name       = var.kratos_release_name
  repository = var.ory_helm_repo
  chart      = "kratos"
  version    = var.kratos_chart_version
  namespace  = var.kratos_namespace

  create_namespace = true

  values = [
    templatefile("${path.module}/kratos.values.yaml.tftpl", {
      is_dev_mode                    = var.is_dev_mode
      kratos_release_name            = var.kratos_release_name
      kratos_namespace               = var.kratos_namespace
      ory_db_username                = var.kratos_db_username
      ory_db_password                = var.kratos_db_password
      ory_db_chart_name              = var.kratos_db_release_name
      ory_db_port                    = var.kratos_db_port
      ory_db_name                    = var.kratos_db_name
      enable_github_authentication   = var.enable_github_authentication
      enable_password_authentication = var.enable_password_authentication || !var.enable_github_authentication
      github_client_id               = var.enable_github_authentication ? var.github_client_id : ""
      github_client_secret           = var.enable_github_authentication ? var.github_client_secret : ""
      domain_name                    = var.domain_name
      kratos_sub_domain              = var.kratos_sub_domain
      self_service_ui_sub_domain     = var.self_service_ui_sub_domain
      apps_sub_domains               = var.apps_sub_domains
      enable_https                   = var.enable_https
      kratos_secret_key              = var.kratos_secret_key
      ssl_secret_name                = var.ssl_secret_name
      selfservice_ui_release_name    = var.selfservice_ui_release_name
      ingress_class_name             = var.ingress_class_name
      api_sub_domain                 = var.api_sub_domain
      kratos_webhook_secret          = var.kratos_webhook_secret
    })
  ]

  depends_on = [
    helm_release.ory-db
  ]
}

# Create registry authentication secret for selfservice UI
resource "kubernetes_secret" "selfservice_ui_registry_auth" {
  count = var.enable_selfservice_ui && var.selfservice_ui_registry_auth_enabled ? 1 : 0

  metadata {
    name      = var.selfservice_ui_image_pull_secret_name != "" ? var.selfservice_ui_image_pull_secret_name : "${var.selfservice_ui_release_name}-registry-auth"
    namespace = var.selfservice_ui_namespace
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.selfservice_ui_registry_server}" = {
          username = var.selfservice_ui_registry_username
          password = var.selfservice_ui_registry_password
          email    = var.selfservice_ui_registry_email
          auth     = base64encode("${var.selfservice_ui_registry_username}:${var.selfservice_ui_registry_password}")
        }
      }
    })
  }
}

# Create TLS secret for Kratos ingress when HTTPS is enabled
resource "kubernetes_secret" "kratos_tls" {
  count = var.enable_https ? 1 : 0

  metadata {
    name      = var.ssl_secret_name != "" ? var.ssl_secret_name : "${var.kratos_release_name}-tls"
    namespace = var.kratos_namespace
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = file(var.ssl_cert_path)
    "tls.key" = file(var.ssl_private_key_path)
  }
}

# Create TLS secret for selfservice UI ingress when HTTPS is enabled
resource "kubernetes_secret" "selfservice_ui_tls" {
  count = var.enable_https && var.enable_selfservice_ui ? 1 : 0

  metadata {
    name      = var.ssl_secret_name != "" ? "${var.ssl_secret_name}-ui" : "${var.selfservice_ui_release_name}-tls"
    namespace = var.selfservice_ui_namespace
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = file(var.ssl_cert_path)
    "tls.key" = file(var.ssl_private_key_path)
  }
}

resource "helm_release" "selfservice_ui" {
  count      = var.enable_selfservice_ui ? 1 : 0
  name       = var.selfservice_ui_release_name
  chart      = "kratos-selfservice-ui-node"
  version    = var.selfservice_ui_chart_version
  repository = var.ory_helm_repo
  namespace  = var.selfservice_ui_namespace

  create_namespace = true

  values = [
    templatefile("${path.module}/selfservice-ui.values.yaml.tftpl", {
      container_image_selfservice_ui     = var.container_image_selfservice_ui
      container_image_selfservice_ui_tag = var.container_image_selfservice_ui_tag
      selfservice_ui_namespace           = var.selfservice_ui_namespace
      kratos_release_name                = var.kratos_release_name
      kratos_namespace                   = var.kratos_namespace
      registry_auth_enabled              = var.selfservice_ui_registry_auth_enabled
      image_pull_secret_name             = var.selfservice_ui_registry_auth_enabled ? (var.selfservice_ui_image_pull_secret_name != "" ? var.selfservice_ui_image_pull_secret_name : "${var.selfservice_ui_release_name}-registry-auth") : ""
      domain_name                        = var.domain_name
      kratos_sub_domain                  = var.kratos_sub_domain
      self_service_ui_sub_domain         = var.self_service_ui_sub_domain
      enable_https                       = var.enable_https
      ssl_secret_name                    = var.ssl_secret_name
      selfservice_ui_release_name        = var.selfservice_ui_release_name
      ingress_class_name                 = var.ingress_class_name
    })
  ]

  # Ensure the registry secret is created before the helm release
  depends_on = [
    kubernetes_secret.selfservice_ui_registry_auth,
    kubernetes_secret.selfservice_ui_tls,
    helm_release.kratos
  ]
}
