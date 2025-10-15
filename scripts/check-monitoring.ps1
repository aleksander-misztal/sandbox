Write-Host "Checking monitoring..." -ForegroundColor Cyan

$monitoring = helm list -n monitoring 2>$null | Select-String "monitoring"

if ($monitoring) {
    Write-Host "Monitoring already installed, skipping" -ForegroundColor Yellow
} else {
    Write-Host "Installing Prometheus + Grafana (3-5 minutes)..." -ForegroundColor Cyan
    
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>$null
    helm repo update
    
    Write-Host "Installation in progress..." -ForegroundColor Yellow
    
    helm install monitoring prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --set grafana.adminPassword=admin123 --set nodeExporter.enabled=false --wait --timeout 5m
    
    Write-Host "Monitoring installed!" -ForegroundColor Green
}