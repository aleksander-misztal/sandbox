# K6 Load Test Runner for HPA Demo
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  K6 Load Test - HPA Demo" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if k6 is installed
$k6Installed = Get-Command k6 -ErrorAction SilentlyContinue

if (-not $k6Installed) {
    Write-Host "ERROR: k6 is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install k6:" -ForegroundColor Yellow
    Write-Host "  Windows: choco install k6" -ForegroundColor White
    Write-Host "  Or download from: https://k6.io/docs/get-started/installation/" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "Starting load test..." -ForegroundColor Green
Write-Host "Target: http://localhost:8080" -ForegroundColor Gray
Write-Host ""
Write-Host "Test profile:" -ForegroundColor Yellow
Write-Host "  30s  -> 10 VUs" -ForegroundColor Gray
Write-Host "  1m   -> 50 VUs" -ForegroundColor Gray
Write-Host "  2m   -> 100 VUs (PEAK)" -ForegroundColor Gray
Write-Host "  1m   -> 50 VUs" -ForegroundColor Gray
Write-Host "  30s  -> 0 VUs" -ForegroundColor Gray
Write-Host ""
Write-Host "Watch Grafana: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Watch HPA: kubectl get hpa -w" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop..." -ForegroundColor Yellow
Write-Host ""

# Run k6 test
k6 run scripts/load-test.js

Write-Host ""
Write-Host "Load test completed!" -ForegroundColor Green
Write-Host "Results saved to: load-test-results.json" -ForegroundColor Cyan
