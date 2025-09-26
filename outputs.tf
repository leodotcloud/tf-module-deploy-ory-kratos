# Core Service Information
output "kratos_release_name" {
  description = "The Helm release name for Kratos"
  value       = var.kratos_release_name
}

output "kratos_namespace" {
  description = "Kubernetes namespace where Kratos is deployed"
  value       = var.kratos_namespace
}

output "kratos_admin_service" {
  description = "Kratos admin service name"
  value       = "${var.kratos_release_name}-admin"
}

output "kratos_public_service" {
  description = "Kratos public service name"
  value       = "${var.kratos_release_name}-public"
}

output "kratos_admin_url" {
  description = "Internal Kratos admin API URL for service-to-service communication"
  value       = "http://${var.kratos_release_name}-admin.${var.kratos_namespace}.svc.cluster.local"
}

output "kratos_public_url" {
  description = "External Kratos public API URL"
  value       = var.enable_https ? "https://${var.kratos_sub_domain}.${var.domain_name}" : "http://localhost:${var.public_port}/auth"
}

# Database Information
output "database_release_name" {
  description = "PostgreSQL database release name"
  value       = var.kratos_db_release_name
}

output "database_service_name" {
  description = "PostgreSQL database service name"
  value       = "${var.kratos_db_release_name}-postgresql"
}

output "database_connection_string" {
  description = "Database connection string (without credentials for security)"
  value       = "postgres://${var.kratos_db_release_name}-postgresql:${var.kratos_db_port}/${var.kratos_db_name}"
  sensitive   = false
}

# Authentication Configuration
output "authentication_methods_enabled" {
  description = "List of enabled authentication methods"
  value = compact([
    var.enable_github_authentication ? "github" : "",
    var.enable_password_authentication || !var.enable_github_authentication ? "password" : ""
  ])
}

output "github_authentication_enabled" {
  description = "Whether GitHub OAuth authentication is enabled"
  value       = var.enable_github_authentication
}

output "password_authentication_enabled" {
  description = "Whether password authentication is enabled"
  value       = var.enable_password_authentication || !var.enable_github_authentication
}

# Self-Service UI Information
output "selfservice_ui_enabled" {
  description = "Whether self-service UI is enabled"
  value       = var.enable_selfservice_ui
}

output "selfservice_ui_release_name" {
  description = "The Helm release name for the self-service UI"
  value       = var.enable_selfservice_ui ? var.selfservice_ui_release_name : null
}

output "selfservice_ui_namespace" {
  description = "Kubernetes namespace where self-service UI is deployed"
  value       = var.enable_selfservice_ui ? var.selfservice_ui_namespace : null
}

output "selfservice_ui_url" {
  description = "Self-service UI URL (when enabled)"
  value       = var.enable_selfservice_ui ? (var.enable_https ? "https://${var.self_service_ui_sub_domain}.${var.domain_name}" : "http://localhost:${var.public_port}/accounts") : null
}

output "selfservice_ui_registry_auth_enabled" {
  description = "Whether registry authentication is enabled for selfservice UI"
  value       = var.enable_selfservice_ui ? var.selfservice_ui_registry_auth_enabled : false
}

output "selfservice_ui_image_pull_secret_name" {
  description = "Name of the image pull secret for selfservice UI (when registry auth is enabled)"
  value       = var.enable_selfservice_ui && var.selfservice_ui_registry_auth_enabled ? (var.selfservice_ui_image_pull_secret_name != "" ? var.selfservice_ui_image_pull_secret_name : "${var.selfservice_ui_release_name}-registry-auth") : null
}

# HTTPS and TLS Configuration
output "https_enabled" {
  description = "Whether HTTPS is enabled for the deployment"
  value       = var.enable_https
}

output "ingress_class_name" {
  description = "Ingress class name being used"
  value       = var.enable_https ? var.ingress_class_name : null
}

output "kratos_tls_secret_name" {
  description = "Name of the TLS secret for Kratos ingress (when HTTPS is enabled)"
  value       = var.enable_https ? (var.ssl_secret_name != "" ? var.ssl_secret_name : "${var.kratos_release_name}-tls") : null
}

output "selfservice_ui_tls_secret_name" {
  description = "Name of the TLS secret for selfservice UI ingress (when HTTPS is enabled)"
  value       = var.enable_https && var.enable_selfservice_ui ? (var.ssl_secret_name != "" ? "${var.ssl_secret_name}-ui" : "${var.selfservice_ui_release_name}-tls") : null
}

# Domain Configuration
output "domain_configuration" {
  description = "Domain configuration for the deployment"
  value = {
    domain_name              = var.domain_name
    kratos_subdomain         = var.kratos_sub_domain
    selfservice_ui_subdomain = var.self_service_ui_sub_domain
    allowed_app_subdomains   = var.apps_sub_domains
  }
}

# Development Mode
output "dev_mode_enabled" {
  description = "Whether development mode is enabled"
  value       = var.is_dev_mode
}
