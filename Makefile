.PHONY: help build deploy-k8s deploy-monitoring load-test demo clean destroy

IMAGE_NAME := hpa-demo-api
IMAGE_TAG := latest

help:
	@echo "=================================="
	@echo "   Kubernetes HPA Demo"
	@echo "=================================="
	@echo.
	@echo "Commands:"
	@echo "  make build              - Build Docker image"
	@echo "  make deploy-k8s         - Deploy to K8s"
	@echo "  make deploy-monitoring  - Install Prometheus + Grafana"
	@echo "  make full-demo          - Everything (build + deploy + monitoring)"
	@echo "  make load-test          - K6 load test"
	@echo "  make status             - Show status"
	@echo "  make grafana            - Open Grafana"
	@echo "  make port-forward       - Port-forward API"
	@echo "  make clean              - Remove app"
	@echo "  make destroy            - Remove everything"

build:
	@echo "Building Docker image..."
	cd app && docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "Image built!"

check-metrics-server:
	@powershell -ExecutionPolicy Bypass -File scripts/check-metrics.ps1

deploy-k8s: check-metrics-server
	@echo "Deploying app..."
	kubectl apply -f k8s/deployment.yaml
	kubectl apply -f k8s/service.yaml
	kubectl apply -f k8s/hpa.yaml
	@echo "Waiting for pods..."
	kubectl wait --for=condition=ready pod -l app=hpa-demo-api --timeout=60s || echo "Timeout, but may work"
	@echo "App deployed!"
	@$(MAKE) status

deploy-monitoring:
	@powershell -ExecutionPolicy Bypass -File scripts/check-monitoring.ps1
	@echo.
	@echo "Grafana: http://localhost:3000"
	@echo "   User: admin | Pass: admin123"
	@echo.
	@echo "Run in new terminal: make grafana"

status:
	@echo "=================================="
	@echo "          APP STATUS"
	@echo "=================================="
	@echo.
	@echo "PODS:"
	@kubectl get pods -l app=hpa-demo-api
	@echo.
	@echo "HPA:"
	@kubectl get hpa hpa-demo-api
	@echo.
	@echo "METRICS:"
	@kubectl top pods -l app=hpa-demo-api 2>nul || echo "Metrics unavailable (wait 30s)"

grafana:
	@echo "Grafana: http://localhost:3000"
	@echo "User: admin | Pass: admin123"
	@echo.
	@echo "Keep this window open!"
	@echo.
	kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80

port-forward:
	@echo "API: http://localhost:8080"
	@echo.
	@echo "Keep this window open!"
	@echo.
	kubectl port-forward service/hpa-demo-service 8080:80

load-test:
	@powershell -ExecutionPolicy Bypass -File scripts/load-test.ps1

demo: build deploy-k8s
	@echo.
	@echo "=================================="
	@echo "        APP READY!"
	@echo "=================================="
	@echo.
	@echo "Next steps:"
	@echo.
	@echo "1. make deploy-monitoring   (install monitoring)"
	@echo "2. make grafana             (terminal 1)"
	@echo "3. make port-forward        (terminal 2)"
	@echo "4. make load-test           (terminal 3)"

full-demo: build deploy-k8s deploy-monitoring
	@echo.
	@echo "=================================="
	@echo "   EVERYTHING INSTALLED!"
	@echo "=================================="
	@echo.
	@echo "Open 3 NEW terminals and run:"
	@echo.
	@echo "Terminal 1: make grafana"
	@echo "Terminal 2: make port-forward"
	@echo "Terminal 3: make load-test"
	@echo.
	@echo "Then open: http://localhost:3000"

clean:
	@echo "Removing app..."
	kubectl delete -f k8s/ --ignore-not-found=true
	@echo "Removed!"

destroy: clean
	@echo "Removing monitoring..."
	helm uninstall monitoring -n monitoring 2>nul || echo "OK"
	kubectl delete namespace monitoring --ignore-not-found=true
	@echo "Everything removed!"

logs:
	kubectl logs -l app=hpa-demo-api --tail=50 --prefix=true

events:
	kubectl get events --sort-by='.lastTimestamp' | findstr hpa-demo