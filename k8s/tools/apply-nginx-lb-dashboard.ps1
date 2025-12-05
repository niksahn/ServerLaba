# Nginx Load Balancer Dashboard Installation Script
# PowerShell version for Windows

$ErrorActionPreference = "Stop"

$NAMESPACE = "microservices-lab"
$DASHBOARD_FILE = "k8s\dashboards\nginx-load-balancer-pods.json"
$CONFIGMAP_NAME = "grafana-dashboard-nginx-lb"

Write-Host "Starting Nginx Load Balancer Dashboard installation..." -ForegroundColor Cyan

# Check if dashboard file exists
if (-not (Test-Path $DASHBOARD_FILE)) {
    Write-Host "Error: Dashboard file not found: $DASHBOARD_FILE" -ForegroundColor Red
    exit 1
}

# Step 1: Apply updated configurations
Write-Host ""
Write-Host "Step 1: Applying updated configurations..." -ForegroundColor Yellow

Write-Host "  -> Applying Nginx configuration..."
kubectl apply -f k8s\manifests\configs\nginx-configmap.yaml

Write-Host "  -> Applying Telegraf configuration..."
kubectl apply -f k8s\manifests\configs\telegraf-nginx-configmap.yaml

# Step 2: Restart Nginx
Write-Host ""
Write-Host "Step 2: Restarting Nginx..." -ForegroundColor Yellow
kubectl rollout restart deployment/nginx -n $NAMESPACE

Write-Host "  -> Waiting for Nginx to be ready..."
kubectl rollout status deployment/nginx -n $NAMESPACE --timeout=120s

# Step 3: Create/update ConfigMap with dashboard
Write-Host ""
Write-Host "Step 3: Creating ConfigMap with dashboard..." -ForegroundColor Yellow

# Delete old ConfigMap if exists
kubectl delete configmap $CONFIGMAP_NAME -n $NAMESPACE --ignore-not-found=true 2>$null | Out-Null

# Create new ConfigMap
kubectl create configmap $CONFIGMAP_NAME `
  --from-file=nginx-load-balancer-pods.json=$DASHBOARD_FILE `
  -n $NAMESPACE

# Add label for Grafana auto-discovery
kubectl label configmap $CONFIGMAP_NAME `
  grafana_dashboard=1 `
  -n $NAMESPACE

Write-Host "  ConfigMap created: $CONFIGMAP_NAME" -ForegroundColor Green

# Step 4: Check Grafana
Write-Host ""
Write-Host "Step 4: Checking Grafana..." -ForegroundColor Yellow

$GRAFANA_POD = kubectl get pods -n $NAMESPACE -l app=grafana -o jsonpath='{.items[0].metadata.name}' 2>$null

if ([string]::IsNullOrEmpty($GRAFANA_POD)) {
    Write-Host "  Warning: Grafana not found in namespace $NAMESPACE" -ForegroundColor Yellow
    Write-Host "  Dashboard will be available after Grafana starts"
} else {
    Write-Host "  -> Restarting Grafana to load dashboard..."
    kubectl rollout restart deployment/grafana -n $NAMESPACE
    
    Write-Host "  -> Waiting for Grafana to be ready..."
    kubectl rollout status deployment/grafana -n $NAMESPACE --timeout=120s
    
    Write-Host "  Grafana restarted successfully" -ForegroundColor Green
}

# Step 5: Check metrics
Write-Host ""
Write-Host "Step 5: Checking Telegraf metrics..." -ForegroundColor Yellow

$NGINX_POD = kubectl get pods -n $NAMESPACE -l app=nginx -o jsonpath='{.items[0].metadata.name}' 2>$null

if ([string]::IsNullOrEmpty($NGINX_POD)) {
    Write-Host "  Warning: Nginx pod not found" -ForegroundColor Yellow
} else {
    Write-Host "  -> Checking Telegraf logs..."
    $logs = kubectl logs -n $NAMESPACE $NGINX_POD -c telegraf --tail=10 2>$null
    if ($logs -match "error") {
        Write-Host "  Warning: Errors found in Telegraf logs" -ForegroundColor Yellow
    } else {
        Write-Host "  Telegraf is running without errors" -ForegroundColor Green
    }
}

# Final information
Write-Host ""
Write-Host "Dashboard installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open Grafana:" -ForegroundColor White
Write-Host "   kubectl port-forward -n $NAMESPACE svc/grafana 3000:3000" -ForegroundColor Gray
Write-Host "   Then open http://localhost:3000" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Find the dashboard:" -ForegroundColor White
Write-Host "   Dashboards -> Browse -> 'Nginx Load Balancer - Raspределение po podam'" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Generate test traffic:" -ForegroundColor White
Write-Host "   kubectl run -it --rm load-test --image=busybox --restart=Never -- sh -c `"while true; do wget -q -O- http://nginx/app-service/health; sleep 0.1; done`"" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Check metrics directly:" -ForegroundColor White
Write-Host "   kubectl port-forward -n $NAMESPACE svc/nginx 9273:9273" -ForegroundColor Gray
Write-Host "   curl http://localhost:9273/metrics | Select-String nginxlog" -ForegroundColor Gray
Write-Host ""
Write-Host "Documentation: k8s\docs\NGINX-LOAD-BALANCER-DASHBOARD.md" -ForegroundColor Cyan
