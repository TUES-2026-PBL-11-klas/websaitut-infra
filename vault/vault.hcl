# HashiCorp Vault Configuration
# Single-node setup with Integrated Storage (Raft)
# Designed to sit behind Caddy reverse proxy (resoponsible for TLS termination)

# --- Storage Backend ---
storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-1"
}

# --- Listener ---
# HTTP only — Caddy handles TLS termination
listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = true
}

# --- General ---
api_addr     = "https://vault.rangelovk.xyz"
cluster_addr = "http://127.0.0.1:8201"
ui           = true

# Prevent memory from being swapped to disk
disable_mlock = false

# Logging
log_level = "info"
