########################################################################################################
#google_privateca_certificate_authority.key_spec.algorithm creating false condition by mentioning any other values mentioned in SED
########################################################################################################

locals {
  googleapis = ["privateca.googleapis.com", "storage.googleapis.com", "cloudkms.googleapis.com"]
}

# Enable required services
resource "google_project_service" "apis" {
  for_each           = toset(local.googleapis)
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# Create a service account to the CA service
resource "google_project_service_identity" "privateca_sa" {
  provider = google-beta
  service  = "privateca.googleapis.com"
  project  = "modular-scout-345114"
}

# Grant access to the CA Pool
resource "google_privateca_ca_pool_iam_member" "policy" {
  ca_pool = google_privateca_ca_pool.example_ca_pool_devops.id
  role    = "roles/privateca.certificateManager"
  member  = "serviceAccount:${google_project_service_identity.privateca_sa.email}"
}


# Create a CA pool selecting devops tier
resource "google_privateca_ca_pool" "example_ca_pool_devops" {
  name     = "my-pool53"
  tier     = "DEVOPS"
  location = "us-central1"
}
# Create a Root CA from CA pool in enterprise tier
resource "google_privateca_certificate_authority" "example_ca_root" {
  pool                     = google_privateca_ca_pool.example_ca_pool_devops.name
  certificate_authority_id = "ca-devops-certificate-authority"
  type                     = "SELF_SIGNED"
  location                 = "us-central1"
  key_spec {
    algorithm = "EC_P256_SHA256"
  }
  config {
    subject_config {
      subject {
        organization = "Example, Org."
        common_name  = "Example Authority"
      }
    }
    x509_config {
      ca_options {
        # is_ca *MUST* be true for certificate authorities
        is_ca                  = true
        max_issuer_path_length = 10
      }
      key_usage {
        base_key_usage {
          # cert_sign and crl_sign *MUST* be true for certificate authorities
          cert_sign = true
          crl_sign  = true
        }
        extended_key_usage {
          server_auth = false
        }
      }
    }
  }


}

