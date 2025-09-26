# Terraform Module: Deploy Ory Kratos

This Terraform module deploys [Ory Kratos](https://www.ory.sh/kratos/) (identity and user management system) along with its dependencies using Helm charts.

## Features

- 🗄️ **PostgreSQL Database**: Automatically deploys and configures PostgreSQL for Kratos
- 🔐 **Multiple Authentication Methods**: Support for GitHub OAuth and password-based authentication
- 🎨 **Self-Service UI**: Optional self-service UI for user registration, login, and account management
- 🔒 **HTTPS/TLS Support**: Built-in SSL certificate management and secure ingress configuration
- 🐳 **Registry Authentication**: Support for private container registries with authentication
- ⚙️ **Configurable**: Flexible configuration options for different deployment scenarios
- � **Development Mode**: Optional development mode with enhanced logging and debugging
- ☸️ **Kubernetes Native**: Uses Helm charts and Kubernetes secrets for secure deployment

## Kubernetes Authentication

This module inherits provider configuration from the parent Terraform configuration. Configure your Kubernetes and Helm providers in your main configuration, and the module will automatically use them.

### 1. Using kubeconfig file (Recommended for local development)
```hcl
# Configure providers in your main configuration
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "my-cluster-context"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "my-cluster-context"
  }
}

# Use the module without any provider variables
module "kratos" {
  source = "path/to/this/module"

  kratos_db_username      = "kratos"
  kratos_db_password      = "secure-password"
  kratos_db_admin_password = "admin-password"
  container_image_selfservice_ui = "oryd/kratos-selfservice-ui-node"
}
```

### 2. Using service account token (Recommended for CI/CD)
```hcl
provider "kubernetes" {
  host                   = "https://your-k8s-api-server.com"
  token                  = var.k8s_token
  cluster_ca_certificate = base64decode(var.k8s_ca_cert)
}

provider "helm" {
  kubernetes {
    host                   = "https://your-k8s-api-server.com"
    token                  = var.k8s_token
    cluster_ca_certificate = base64decode(var.k8s_ca_cert)
  }
}

module "kratos" {
  source = "path/to/this/module"

  kratos_db_username      = "kratos"
  kratos_db_password      = "secure-password"
  kratos_db_admin_password = "admin-password"
  container_image_selfservice_ui = "oryd/kratos-selfservice-ui-node"
}
```

### 3. For AWS EKS
```hcl
data "aws_eks_cluster" "cluster" {
  name = "my-eks-cluster"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "my-eks-cluster"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

module "kratos" {
  source = "path/to/this/module"

  kratos_db_username      = "kratos"
  kratos_db_password      = "secure-password"
  kratos_db_admin_password = "admin-password"
  container_image_selfservice_ui = "oryd/kratos-selfservice-ui-node"
}
```

### 4. For Google GKE
```hcl
data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
  name     = "my-gke-cluster"
  location = "us-central1"
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
  }
}

module "kratos" {
  source = "path/to/this/module"

  kratos_db_username      = "kratos"
  kratos_db_password      = "secure-password"
  kratos_db_admin_password = "admin-password"
  container_image_selfservice_ui = "oryd/kratos-selfservice-ui-node"
}
```

## Quick Start

```hcl
module "kratos" {
  source = "path/to/this/module"

  # Required: Database credentials
  kratos_db_username       = "kratos"
  kratos_db_password       = "secure-password"
  kratos_db_admin_password = "admin-password"

  # Required: Kratos secret key for cookie encryption
  kratos_secret_key = "your-32-character-secret-key-here"

  # Domain configuration
  domain_name                    = "yourdomain.com"
  kratos_sub_domain             = "auth"
  self_service_ui_sub_domain    = "accounts"

  # Authentication methods (at least one must be enabled)
  enable_github_authentication = true
  github_client_id             = "your-github-client-id"
  github_client_secret         = "your-github-client-secret"

  # Optional: HTTPS configuration (requires SSL certificates when enabled)
  enable_https         = true
  ssl_cert_path        = "/path/to/certificate.crt"
  ssl_private_key_path = "/path/to/private.key"
  ingress_class_name   = "nginx"

  # Optional: Self-service UI customization
  container_image_selfservice_ui = "oryd/kratos-selfservice-ui-node"
  
  # Optional: Development mode (not for production)
  is_dev_mode = false
}
```

## Authentication Methods

### GitHub OAuth (Default)
When `enable_github_authentication = true`:
- Users can sign in with their GitHub accounts
- Requires GitHub OAuth app setup
- Identity schema includes email, nickname, and name fields

### Password Authentication
When `enable_password_authentication = true` or GitHub auth is disabled:
- Traditional email/password authentication
- Identity schema includes only email field
- Automatically enabled when GitHub auth is disabled

## SSL Certificates

When `enable_https = true`, SSL certificate files are **required**:

- `ssl_cert_path`: Path to your SSL certificate file (`.crt`, `.pem`, or `.cert`)
- `ssl_private_key_path`: Path to your private key file (`.key` or `.pem`)
- `ssl_ca_cert_path`: Path to CA certificate file (optional)
- `ssl_secret_name`: Custom name for the Kubernetes TLS secret (optional)

The module will:
1. Create Kubernetes TLS secrets from your certificate files
2. Configure ingress resources to use these secrets for TLS termination
3. Generate HTTPS URLs for all Kratos endpoints

**Note**: SSL certificates are mandatory when HTTPS is enabled to ensure secure production deployments.

## Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `kratos_db_username` | Database username for Kratos | `string` |
| `kratos_db_password` | Database password for Kratos | `string` |
| `kratos_db_admin_password` | Database admin password | `string` |
| `kratos_secret_key` | Secret key for Kratos cookie encryption | `string` |

### Core Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `domain_name` | Domain name for deployment | `string` | `"example.com"` |
| `kratos_sub_domain` | Subdomain for Kratos public API | `string` | `"auth"` |
| `self_service_ui_sub_domain` | Subdomain for self-service UI | `string` | `"accounts"` |
| `apps_sub_domains` | List of app subdomains to enable with Kratos | `list(string)` | `["app"]` |
| `public_port` | External port for accessing services | `string` | `"8080"` |

### Authentication Methods

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_github_authentication` | Enable GitHub OAuth authentication | `bool` | `true` |
| `github_client_id` | GitHub OAuth client ID (required if GitHub auth enabled) | `string` | `""` |
| `github_client_secret` | GitHub OAuth client secret (required if GitHub auth enabled) | `string` | `""` |
| `enable_password_authentication` | Enable password authentication | `bool` | `false` |

### HTTPS/TLS Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_https` | Enable HTTPS with SSL certificates | `bool` | `false` |
| `ssl_cert_path` | Path to SSL certificate file (required if HTTPS enabled) | `string` | `""` |
| `ssl_private_key_path` | Path to SSL private key file (required if HTTPS enabled) | `string` | `""` |
| `ssl_ca_cert_path` | Path to SSL CA certificate file | `string` | `""` |
| `ssl_secret_name` | Custom name for TLS secret | `string` | `""` |
| `ingress_class_name` | Ingress class name (required if HTTPS enabled) | `string` | `""` |

### Self-Service UI Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_selfservice_ui` | Deploy self-service UI | `bool` | `true` |
| `container_image_selfservice_ui` | Self-service UI container image (uses chart default if empty) | `string` | `""` |
| `container_image_selfservice_ui_tag` | Image tag for self-service UI | `string` | `"latest"` |
| `selfservice_ui_registry_auth_enabled` | Enable registry authentication for UI image | `bool` | `false` |
| `selfservice_ui_registry_server` | Registry server URL | `string` | `"docker.io"` |
| `selfservice_ui_registry_username` | Registry username (required if registry auth enabled) | `string` | `""` |
| `selfservice_ui_registry_password` | Registry password (required if registry auth enabled) | `string` | `""` |
| `selfservice_ui_registry_email` | Registry email | `string` | `""` |

### Advanced Configuration

<details>
<summary>View advanced variables</summary>

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `ory_helm_repo` | Ory Helm repository URL | `string` | `"https://k8s.ory.sh/helm/charts"` |
| `kratos_db_release_name` | PostgreSQL release name | `string` | `"kratos-db"` |
| `kratos_db_name` | Database name | `string` | `"kratos-db"` |
| `kratos_db_port` | Database port | `string` | `"5432"` |
| `kratos_db_persistence_enabled` | Enable database persistence | `bool` | `true` |
| `kratos_release_name` | Kratos release name | `string` | `"kratos"` |
| `kratos_chart_version` | Kratos Helm chart version | `string` | `"0.58.0"` |
| `kratos_namespace` | Kubernetes namespace for Kratos | `string` | `"default"` |
| `selfservice_ui_release_name` | Self-service UI release name | `string` | `"selfservice-ui"` |
| `selfservice_ui_namespace` | Kubernetes namespace for UI | `string` | `"default"` |
| `selfservice_ui_image_pull_secret_name` | Custom name for image pull secret | `string` | `""` |
| `is_dev_mode` | Enable development mode (not for production) | `bool` | `false` |

</details>

## Outputs

### Core Service Information

| Name | Description |
|------|-------------|
| `kratos_release_name` | The Helm release name for Kratos |
| `kratos_namespace` | Kubernetes namespace where Kratos is deployed |
| `kratos_admin_service` | Kratos admin service name |
| `kratos_public_service` | Kratos public service name |
| `kratos_admin_url` | Internal Kratos admin API URL for service-to-service communication |
| `kratos_public_url` | External Kratos public API URL |

### Database Information

| Name | Description |
|------|-------------|
| `database_release_name` | PostgreSQL database release name |
| `database_service_name` | PostgreSQL database service name |
| `database_connection_string` | Database connection string (without credentials) |

### Authentication Configuration

| Name | Description |
|------|-------------|
| `authentication_methods_enabled` | List of enabled authentication methods |
| `github_authentication_enabled` | Whether GitHub OAuth authentication is enabled |
| `password_authentication_enabled` | Whether password authentication is enabled |

### Self-Service UI Information

| Name | Description |
|------|-------------|
| `selfservice_ui_enabled` | Whether self-service UI is deployed |
| `selfservice_ui_release_name` | The Helm release name for the self-service UI |
| `selfservice_ui_namespace` | Kubernetes namespace where self-service UI is deployed |
| `selfservice_ui_url` | Self-service UI URL (when enabled) |
| `selfservice_ui_registry_auth_enabled` | Whether registry authentication is enabled for UI |
| `selfservice_ui_image_pull_secret_name` | Name of the image pull secret for UI |

### HTTPS and Security

| Name | Description |
|------|-------------|
| `https_enabled` | Whether HTTPS is enabled for the deployment |
| `ingress_class_name` | Ingress class name being used |
| `kratos_tls_secret_name` | Name of the TLS secret for Kratos ingress |
| `selfservice_ui_tls_secret_name` | Name of the TLS secret for selfservice UI ingress |
| `domain_configuration` | Domain configuration object with all subdomain mappings |
| `dev_mode_enabled` | Whether development mode is enabled |

## Usage Examples

### Production Deployment with HTTPS
```hcl
module "kratos" {
  source = "./modules/kratos"

  # Required credentials
  kratos_db_username       = "kratos"
  kratos_db_password       = var.db_password
  kratos_db_admin_password = var.db_admin_password
  kratos_secret_key        = var.kratos_secret_key

  # Domain configuration
  domain_name                    = "yourdomain.com"
  kratos_sub_domain             = "auth"
  self_service_ui_sub_domain    = "accounts"
  apps_sub_domains              = ["app1", "app2"]

  # HTTPS configuration
  enable_https         = true
  ssl_cert_path        = "/path/to/your/certificate.crt"
  ssl_private_key_path = "/path/to/your/private.key"
  ssl_ca_cert_path     = "/path/to/your/ca.crt"    # Optional
  ssl_secret_name      = "kratos-tls-secret"       # Optional
  ingress_class_name   = "nginx"

  # Authentication
  enable_github_authentication = true
  github_client_id             = var.github_client_id
  github_client_secret         = var.github_client_secret

  # UI configuration
  container_image_selfservice_ui = "oryd/kratos-selfservice-ui-node"
}
```

### Development/Testing Deployment
```hcl
module "kratos" {
  source = "./modules/kratos"

  # Required credentials
  kratos_db_username       = "kratos"
  kratos_db_password       = "dev-password"
  kratos_db_admin_password = "dev-admin-password"
  kratos_secret_key        = "development-secret-key-32chars"

  # Development configuration
  is_dev_mode                   = true
  enable_github_authentication = true
  github_client_id             = var.github_client_id
  github_client_secret         = var.github_client_secret

  # Uses chart default UI image
  # container_image_selfservice_ui not specified
}
```

### Custom Namespace Deployment
```hcl
module "kratos" {
  source = "./modules/kratos"

  # Required credentials
  kratos_db_username       = "kratos"
  kratos_db_password       = var.db_password
  kratos_db_admin_password = var.db_admin_password
  kratos_secret_key        = var.kratos_secret_key

  # Custom namespaces
  kratos_namespace           = "identity"
  selfservice_ui_namespace   = "identity-ui"

  # Authentication
  enable_github_authentication = true
  github_client_id             = var.github_client_id
  github_client_secret         = var.github_client_secret

  # Custom UI image
  container_image_selfservice_ui     = "oryd/kratos-selfservice-ui-node"
  container_image_selfservice_ui_tag = "v0.13.0"
}
```

### Password Authentication Only
```hcl
module "kratos" {
  source = "./modules/kratos"

  # Required credentials
  kratos_db_username       = "kratos"
  kratos_db_password       = var.db_password
  kratos_db_admin_password = var.db_admin_password
  kratos_secret_key        = var.kratos_secret_key

  # Disable GitHub OAuth, enable password auth
  enable_github_authentication   = false
  enable_password_authentication = true

  container_image_selfservice_ui = "oryd/kratos-selfservice-ui-node"
}
```

### Both Authentication Methods
```hcl
module "kratos" {
  source = "./modules/kratos"

  # Required credentials
  kratos_db_username       = "kratos"
  kratos_db_password       = var.db_password
  kratos_db_admin_password = var.db_admin_password
  kratos_secret_key        = var.kratos_secret_key

  # Enable both authentication methods
  enable_github_authentication   = true
  enable_password_authentication = true
  github_client_id               = var.github_client_id
  github_client_secret           = var.github_client_secret

  container_image_selfservice_ui = "oryd/kratos-selfservice-ui-node"
}
```

### Private Registry Authentication
```hcl
module "kratos" {
  source = "./modules/kratos"

  # Required credentials
  kratos_db_username       = "kratos"
  kratos_db_password       = var.db_password
  kratos_db_admin_password = var.db_admin_password
  kratos_secret_key        = var.kratos_secret_key

  # Authentication
  enable_github_authentication = true
  github_client_id             = var.github_client_id
  github_client_secret         = var.github_client_secret

  # Private registry configuration
  container_image_selfservice_ui           = "your-private-registry.com/kratos-ui"
  container_image_selfservice_ui_tag       = "v1.0.0"
  selfservice_ui_registry_auth_enabled     = true
  selfservice_ui_registry_server           = "your-private-registry.com"
  selfservice_ui_registry_username         = var.registry_username
  selfservice_ui_registry_password         = var.registry_password
  selfservice_ui_registry_email            = "your-email@example.com"
  selfservice_ui_image_pull_secret_name    = "custom-registry-secret"
}
```

## Configuration Notes

### GitHub OAuth Setup

1. Create a GitHub OAuth App in your GitHub settings
2. Set the authorization callback URL based on your domain configuration:
   - For HTTPS: `https://{kratos_sub_domain}.{domain_name}/self-service/methods/oidc/callback/github`
   - For development: `http://localhost:8080/auth/self-service/methods/oidc/callback/github`
3. Use the Client ID and Client Secret in your Terraform configuration

### Authentication Method Requirements

- At least one authentication method must be enabled
- When GitHub authentication is disabled, password authentication is automatically enabled
- Both methods can be enabled simultaneously for maximum flexibility

### HTTPS Configuration Requirements

When `enable_https = true`:
- `ssl_cert_path` and `ssl_private_key_path` are **required**
- `ingress_class_name` is **required** (e.g., "nginx", "traefik")
- Certificate files must exist and be readable by Terraform
- The module creates Kubernetes TLS secrets automatically

### Development Mode

When `is_dev_mode = true`:
- Enables trace-level logging
- **Should never be used in production**
- Useful for debugging authentication flows and configuration issues

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14 |
| kubernetes | >= 2.0 |
| helm | >= 2.0 |

### Infrastructure Requirements

- Kubernetes cluster (v1.19+ recommended)
- Ingress controller (if using HTTPS)
- Persistent storage for PostgreSQL (if persistence enabled)
- kubectl access to the cluster

## License

MIT License - see [LICENSE](LICENSE) file for details.