# Validation for GitHub authentication requirements
check "github_authentication_requirements" {
  assert {
    condition = var.enable_github_authentication == false || (
      var.enable_github_authentication == true &&
      var.github_client_id != "" &&
      var.github_client_secret != ""
    )
    error_message = "When enable_github_authentication is true, both github_client_id and github_client_secret must be provided and cannot be empty."
  }
}

# Validation to ensure at least one authentication method is enabled
check "authentication_method_required" {
  assert {
    condition     = var.enable_github_authentication == true || var.enable_password_authentication == true
    error_message = "At least one authentication method must be enabled. Set either enable_github_authentication or enable_password_authentication to true."
  }
}

# Validation for selfservice UI registry authentication
check "selfservice_ui_registry_auth_requirements" {
  assert {
    condition = var.selfservice_ui_registry_auth_enabled == false || (
      var.selfservice_ui_registry_auth_enabled == true &&
      var.selfservice_ui_registry_username != "" &&
      var.selfservice_ui_registry_password != ""
    )
    error_message = "When selfservice_ui_registry_auth_enabled is true, both selfservice_ui_registry_username and selfservice_ui_registry_password must be provided."
  }
}

# Validation for SSL certificate requirements when HTTPS is enabled
check "ssl_certificate_requirements" {
  assert {
    condition = var.enable_https == false || (
      var.enable_https == true &&
      var.ssl_cert_path != "" &&
      var.ssl_private_key_path != "" &&
      var.ingress_class_name != ""
    )
    error_message = "When enable_https is true, ssl_cert_path, ssl_private_key_path, and ingress_class_name must be provided and cannot be empty."
  }
}