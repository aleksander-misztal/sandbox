# Kubernetes HPA Load Testing

Production-ready demonstration of Kubernetes Horizontal Pod Autoscaler (HPA) with k6 load testing and Prometheus/Grafana monitoring.

## What This Does

Demonstrates Kubernetes auto-scaling behavior under realistic CPU load:
- FastAPI with CPU-intensive endpoint
- HPA configured for 50% CPU target (1-10 pods)
- k6 load test with ramping VUs (0→100→0)
- Prometheus + Grafana for real-time metrics

## Prerequisites

- Docker Desktop with Kubernetes enabled
- kubectl, helm, k6 installed
- Windows: `choco install k6`

## Quick Start

```bash
# 1. Build and deploy everything
make full-demo

# 2. Terminal 1: Port-forward API
make port-forward

# 3. Terminal 2: Port-forward Grafana (optional)
make grafana
# http://localhost:3000 (admin/admin123)

# 4. Terminal 3: Run load test
make load-test

# 5. Watch HPA scale
kubectl get hpa -w
```

## Expected Results

**Load Test:**
- 15-30 RPS
- P95 latency < 5s
- Error rate < 1%
- 100 peak VUs

**HPA Behavior:**
- Start: 1 pod @ 10% CPU
- Peak: 5-8 pods @ 50-60% CPU
- Scale-up: ~30-60s
- Scale-down: 5min (stabilization)

## Architecture

```
k6 (100 VUs) → Service → HPA (1-10 pods) → FastAPI
                          ↓
                    Prometheus + Grafana
```

**Key Config:**
- HPA target: 50% CPU
- Pod limits: 100m request, 500m limit
- Load profile: 30s→1m→2m→1m→30s (10→50→100→50→0 VUs)

## Commands

| Command | Description |
|---------|-------------|
| `make full-demo` | Build + deploy + monitoring |
| `make load-test` | Run k6 load test |
| `make status` | Show HPA and pods |
| `make clean` | Remove app |
| `make destroy` | Remove everything |

## Structure

```
app/
  main.py           # FastAPI with /stress endpoint
k8s/
  deployment.yaml   # Pod resources & probes
  hpa.yaml         # HPA config (50% CPU target)
scripts/
  load-test.js     # k6 test with metrics
```

## Troubleshooting

**Pods not starting:**
```bash
kubectl describe pods -l app=hpa-demo-api
```

**HPA not scaling:**
```bash
kubectl top pods -l app=hpa-demo-api  # Check CPU usage
```

**Metrics unavailable:**
Wait 30s after deployment for metrics-server to initialize.

---

**Production-ready K8s auto-scaling demo**
