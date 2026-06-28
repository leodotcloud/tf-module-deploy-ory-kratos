variable "ory_helm_repo" {
  default     = "https://k8s.ory.sh/helm/charts"
  description = "Specify the URL of Ory Helm repository"
}

variable "public_port" {
  default     = "8080"
  description = "Port on which the apps are accessed on the client side (not necessarily same port as Ingress)"
}

variable "kratos_db_release_name" {
  default     = "kratos-db"
  description = "Specify the release name for DB used with Kratos"
}

variable "kratos_db_name" {
  default     = "kratos-db"
  description = "Specify DB name"
}

variable "kratos_db_username" {
  description = "Specify DB username"
}

variable "kratos_db_password" {
  description = "Specify DB password"
}

variable "kratos_db_admin_password" {
  description = "Specify DB admin/root password"
}

variable "kratos_db_port" {
  default     = "5432"
  description = "Specify port number to use with DB"
}

variable "kratos_db_persistence_enabled" {
  default     = true
  description = "Specify if persistence needs to be enabled"
}

variable "kratos_release_name" {
  default = "kratos"
}

variable "kratos_chart_version" {
  default = "0.61.1"
}

variable "kratos_namespace" {
  default = "default"
}

variable "enable_github_authentication" {
  type        = bool
  default     = true
  description = "Boolean to enable GitHub authentication in Kratos. When disabled, password authentication will be enabled instead."
}

variable "enable_password_authentication" {
  type        = bool
  default     = false
  description = "Boolean to enable password authentication in Kratos. This is automatically enabled when GitHub authentication is disabled."
}

variable "github_client_id" {
  type        = string
  sensitive   = true
  description = "Specify GitHub Client ID. Required when enable_github_authentication is true"
  default     = ""

  validation {
    condition     = can(regex("^[a-zA-Z0-9]*$", var.github_client_id)) || var.github_client_id == ""
    error_message = "github_client_id must contain only alphanumeric characters."
  }
}

variable "github_client_secret" {
  type        = string
  sensitive   = true
  description = "Specify GitHub Client Secret. Required when enable_github_authentication is true"
  default     = ""

  validation {
    condition     = length(var.github_client_secret) == 0 || length(var.github_client_secret) >= 10
    error_message = "github_client_secret must be at least 10 characters long when provided."
  }
}

variable "enable_selfservice_ui" {
  default     = true
  description = "Enable Self-Service UI"
}

variable "selfservice_ui_release_name" {
  default = "selfservice-ui"
}

variable "selfservice_ui_namespace" {
  default = "default"
}

variable "selfservice_ui_chart_version" {
  default     = "0.61.1"
  description = "Helm chart version for the selfservice UI"
}

variable "container_image_selfservice_ui" {
  description = "Container image used for the Self Service UI. If empty, uses chart default."
  type        = string
  default     = ""
}

variable "container_image_selfservice_ui_tag" {
  description = "Tag used for the Self Service UI. Only used if container_image_selfservice_ui is specified."
  type        = string
  default     = "latest"
}

# Registry authentication variables
variable "selfservice_ui_registry_auth_enabled" {
  description = "Enable registry authentication for selfservice UI image"
  type        = bool
  default     = false
}

variable "selfservice_ui_registry_server" {
  description = "Registry server URL (e.g., docker.io, gcr.io, etc.)"
  type        = string
  default     = "docker.io"
}

variable "selfservice_ui_registry_username" {
  description = "Registry username for selfservice UI image"
  type        = string
  sensitive   = true
  default     = ""
}

variable "selfservice_ui_registry_password" {
  description = "Registry password for selfservice UI image"
  type        = string
  sensitive   = true
  default     = ""
}

variable "selfservice_ui_registry_email" {
  description = "Registry email for selfservice UI image (optional)"
  type        = string
  default     = ""
}

variable "selfservice_ui_image_pull_secret_name" {
  description = "Name for the image pull secret. If not provided, will be auto-generated"
  type        = string
  default     = ""
}


variable "domain_name" {
  description = "Specify what domain name to use for deployment"
  type        = string
  default     = "example.com"
}

variable "kratos_sub_domain" {
  description = "Specify the sub-domain to use for kratos"
  type        = string
  default     = "auth"
}

variable "self_service_ui_sub_domain" {
  description = "Specify the sub-domain to use for Self service UI"
  type        = string
  default     = "accounts"
}

variable "apps_sub_domains" {
  description = "Specify the list of app sub-domains to enable with Kratos"
  type        = list(string)
  default     = ["app"]
}

variable "api_sub_domain" {
  description = "Sub-domain of the TwinStreak API server (used for after-registration webhook URL)"
  type        = string
  default     = "api"
}

variable "kratos_webhook_secret" {
  description = "Shared secret included in the Authorization header when Kratos calls the after-registration webhook"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_https" {
  description = "Enable HTTPS for URLs in Kratos configuration. When true, SSL certificate paths must be provided."
  type        = bool
  default     = false
}

variable "ssl_cert_path" {
  description = "Path to the SSL certificate file. Required when enable_https is true."
  type        = string
  default     = ""
  sensitive   = false

  validation {
    condition     = can(regex("^.*\\.(crt|pem|cert|cer)$", var.ssl_cert_path)) || var.ssl_cert_path == ""
    error_message = "ssl_cert_path must be a valid certificate file path ending in .crt, .pem, or .cert or .cer"
  }
}

variable "ssl_private_key_path" {
  description = "Path to the SSL private key file. Required when enable_https is true."
  type        = string
  default     = ""
  sensitive   = false

  validation {
    condition     = can(regex("^.*\\.(key|pem)$", var.ssl_private_key_path)) || var.ssl_private_key_path == ""
    error_message = "ssl_private_key_path must be a valid private key file path ending in .key or .pem"
  }
}

variable "ssl_ca_cert_path" {
  description = "Path to the SSL CA certificate file. Optional."
  type        = string
  default     = ""
  sensitive   = false

  validation {
    condition     = can(regex("^.*\\.(crt|pem|cert)$", var.ssl_ca_cert_path)) || var.ssl_ca_cert_path == ""
    error_message = "ssl_ca_cert_path must be a valid certificate file path ending in .crt, .pem, or .cert when provided"
  }
}

variable "ssl_secret_name" {
  description = "Name for the Kubernetes TLS secret. If not provided, will be auto-generated based on release names."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.ssl_secret_name)) || var.ssl_secret_name == ""
    error_message = "ssl_secret_name must be a valid Kubernetes resource name (lowercase alphanumeric and hyphens only)"
  }
}

variable "ingress_class_name" {
  description = "Ingress class name to use (e.g., 'traefik', 'nginx', 'haproxy'). Required when enable_https is true."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.ingress_class_name)) || var.ingress_class_name == ""
    error_message = "ingress_class_name must be a valid ingress class name (lowercase alphanumeric and hyphens only)"
  }
}

variable "kratos_secret_key" {
  description = "Secret key for Kratos cookie encryption"
  type        = string
  sensitive   = true
}

variable "is_dev_mode" {
  description = "Enable dev mode, NOT FOR PROD"
  type        = bool
  default     = false
}
