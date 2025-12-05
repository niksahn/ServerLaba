#!/bin/bash

# Script to generate Grafana dashboards ConfigMap from all JSON files in k8s/dashboards

set -e

NAMESPACE="microservices-lab"
DASHBOARDS_DIR="../dashboards"
CONFIGMAP_NAME="grafana-dashboards"

echo "Generating Grafana dashboards ConfigMap from $DASHBOARDS_DIR..."
echo ""

# Check if dashboards directory exists
if [ ! -d "$DASHBOARDS_DIR" ]; then
    echo "Error: Directory $DASHBOARDS_DIR not found"
    exit 1
fi

# Count JSON files
JSON_COUNT=$(find "$DASHBOARDS_DIR" -maxdepth 1 -name "*.json" -type f | wc -l)

if [ "$JSON_COUNT" -eq 0 ]; then
    echo "Error: No JSON files found in $DASHBOARDS_DIR"
    exit 1
fi

echo "Found $JSON_COUNT dashboard files"
echo ""

# Delete old ConfigMap if exists
echo "Deleting old ConfigMap (if exists)..."
kubectl delete configmap $CONFIGMAP_NAME -n $NAMESPACE --ignore-not-found=true

# Create new ConfigMap from all JSON files
echo "Creating ConfigMap from all dashboard files..."
kubectl create configmap $CONFIGMAP_NAME \
  --from-file=$DASHBOARDS_DIR \
  -n $NAMESPACE \
  --dry-run=client -o yaml | \
  kubectl apply -f -

# Add label for Grafana auto-discovery
echo "Adding label for Grafana auto-discovery..."
kubectl label configmap $CONFIGMAP_NAME \
  grafana_dashboard=1 \
  -n $NAMESPACE \
  --overwrite

echo ""
echo "ConfigMap created successfully with $JSON_COUNT dashboards!"
echo ""

# List all dashboard files included
echo "Included dashboards:"
find "$DASHBOARDS_DIR" -maxdepth 1 -name "*.json" -type f -exec basename {} \;

echo ""
echo "Restarting Grafana to load dashboards..."
kubectl rollout restart deployment/grafana -n $NAMESPACE

echo ""
echo "Waiting for Grafana to be ready..."
kubectl rollout status deployment/grafana -n $NAMESPACE --timeout=120s

echo ""
echo "Done! All dashboards from $DASHBOARDS_DIR are now in Grafana"
echo ""
echo "To access Grafana:"
echo "  kubectl port-forward -n $NAMESPACE svc/grafana 3000:3000"
echo "  Then open http://localhost:3000"
