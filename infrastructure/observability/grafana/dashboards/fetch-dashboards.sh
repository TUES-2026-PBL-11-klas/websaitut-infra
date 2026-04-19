#!/usr/bin/env bash
# Fetches community Grafana dashboards and wraps them as ConfigMap YAML files.
# Run once to refresh; commit the output configmap-*.yaml files.
#
# Requirements: curl, jq
# Usage: ./fetch-dashboards.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v jq &>/dev/null; then
  echo "error: jq is required" >&2
  exit 1
fi

DASHBOARDS=(
  "15759:k8s-cluster"            # Kubernetes / Views / Global
  "16714:flux"                   # FluxCD Cluster Stats
  "9628:postgres"                # PostgreSQL Database
  "7587:blackbox"                # Prometheus Blackbox Exporter
  "21550:victorialogs-simple"    # Simple VictoriaLogs — basic logs browser
)

# jq program that normalizes all datasource references in a dashboard.
# Handles both legacy string form ("${DS_PROMETHEUS}") and modern object form
# ({"type": "...", "uid": "..."}), in panels, annotations, and templating.
read -r -d '' NORMALIZE_JQ <<'JQ' || true
def normalize_ds:
  if . == null then .
  elif type == "string" then
    if test("\\$\\{DS_") or test("prometheus"; "i") then
      {"type": "prometheus", "uid": "prometheus"}
    elif test("loki"; "i") or test("victorialogs"; "i") or test("victoriametrics-logs"; "i") then
      {"type": "victoriametrics-logs-datasource", "uid": "victorialogs"}
    else . end
  elif type == "object" then
    if ((.uid // "") | (test("\\$\\{DS_") or test("prometheus"; "i"))) then
      {"type": "prometheus", "uid": "prometheus"}
    elif ((.uid // "") | (test("loki"; "i") or test("victorialogs"; "i"))) then
      {"type": "victoriametrics-logs-datasource", "uid": "victorialogs"}
    elif ((.type // "") | test("victoriametrics-logs")) then
      {"type": "victoriametrics-logs-datasource", "uid": "victorialogs"}
    else . end
  else . end
;
walk(
  if type == "object" and has("datasource") then
    .datasource |= normalize_ds
  else . end
)
# Remove links to silence "parse *: empty url" toast
| del(.links)
# Remove id/uid so Grafana assigns fresh ones on import
| del(.id, .uid)
# Remove import-only metadata
| del(.__inputs, .__requires, .__elements)
JQ

fetch_one() {
  local id="$1"
  local name="$2"
  local configmap="configmap-${name}.yaml"

  echo "==> Fetching dashboard ${id} (${name})"

  local raw
  raw=$(curl -fsSL "https://grafana.com/api/dashboards/${id}/revisions/latest/download")

  local normalized
  normalized=$(echo "$raw" | jq "$NORMALIZE_JQ")

  cat > "$configmap" <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard-${name}
  namespace: grafana
  labels:
    grafana_dashboard: "1"
data:
  ${name}.json: |
YAML
  echo "$normalized" | sed 's/^/    /' >> "$configmap"

  echo "    wrote ${configmap}"
}

for entry in "${DASHBOARDS[@]}"; do
  IFS=':' read -r id name <<< "$entry"
  fetch_one "$id" "$name"
done

echo
echo "==> Done. Review and commit the configmap-*.yaml files."
