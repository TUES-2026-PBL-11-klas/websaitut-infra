#!/usr/bin/env bash
# Fetches community Grafana dashboards and wraps them as ConfigMap YAML files
# in this directory. Run once; the output ConfigMaps should be committed to
# the repo as source of truth.
#
# Usage: ./fetch-dashboards.sh
#
# Dashboards are sourced from grafana.com/grafana/dashboards/<id>.
# If grafana.com is down, the URLs to manually fetch are printed at the end.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# id:name:datasource-type mapping
#   id       — grafana.com dashboard ID
#   name     — short name used in ConfigMap and filename
#   ds-type  — prometheus | loki (what the dashboard queries)
DASHBOARDS=(
  "15759:k8s-cluster:prometheus"      # Kubernetes / Views / Global
  "1860:node-exporter:prometheus"     # Node Exporter Full
  "16714:flux:prometheus"             # FluxCD Cluster Stats
  "17346:traefik:prometheus"          # Traefik 3
  "9628:postgres:prometheus"          # PostgreSQL Database
  "7587:blackbox:prometheus"          # Prometheus Blackbox Exporter
)

fetch_one() {
  local id="$1"
  local name="$2"
  local ds_type="$3"
  local out="dashboard-${name}.json"
  local configmap="configmap-${name}.yaml"

  echo "==> Fetching dashboard ${id} (${name})"

  # grafana.com returns the dashboard JSON at this URL.
  curl -fsSL "https://grafana.com/api/dashboards/${id}/revisions/latest/download" \
    -o "$out"

  # Replace any dashboard-embedded datasource with our provisioned one.
  # Community dashboards reference ${DS_PROMETHEUS} or similar templated vars;
  # we hard-code them to our datasource names.
  if [ "$ds_type" = "prometheus" ]; then
    # Match any ${DS_*PROMETHEUS*} variant (DS_PROMETHEUS, DS_SIGNCL-PROMETHEUS, etc.)
    sed -i.bak -E '
      s/"\$\{DS_[^}]*PROMETHEUS[^}]*\}"/"Prometheus"/g
      s/"\$\{datasource\}"/"Prometheus"/g
      s/"uid":[[:space:]]*"[Pp]rometheus"/"uid": "prometheus"/g
      s/"uid":[[:space:]]*"\$\{DS_[^}]*\}"/"uid": "prometheus"/g
    ' "$out"
  else
    sed -i.bak -E '
      s/"\$\{DS_[^}]*LOKI[^}]*\}"/"Loki"/g
      s/"uid":[[:space:]]*"[Ll]oki"/"uid": "loki"/g
    ' "$out"
  fi
  rm -f "${out}.bak"
  # Wrap as ConfigMap.
  cat > "$configmap" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard-${name}
  namespace: grafana
data:
  ${name}.json: |
EOF
  sed 's/^/    /' "$out" >> "$configmap"

  rm "$out"
  echo "    wrote ${configmap}"
}

for entry in "${DASHBOARDS[@]}"; do
  IFS=':' read -r id name ds <<< "$entry"
  fetch_one "$id" "$name" "$ds"
done

echo
echo "==> Done. Custom 'logs' dashboard must be created separately (see README)."
echo "    Review, commit the configmap-*.yaml files, and you're done."
