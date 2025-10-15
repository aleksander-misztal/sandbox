Write-Host "Checking Metrics Server..." -ForegroundColor Cyan

$metricsServer = kubectl get deployment metrics-server -n kube-system 2>$null

if ($metricsServer) {
    Write-Host "Metrics Server is running" -ForegroundColor Green
} else {
    Write-Host "Installing Metrics Server..." -ForegroundColor Yellow
    
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    kubectl patch deployment metrics-server -n kube-system --type=json -p '[{\"op\": \"add\", \"path\": \"/spec/template/spec/containers/0/args/-\", \"value\": \"--kubelet-insecure-tls\"}]'
    
    Write-Host "Metrics Server installed" -ForegroundColor Green
    Write-Host "Waiting 30s..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}