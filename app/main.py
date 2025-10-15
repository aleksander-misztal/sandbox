from fastapi import FastAPI, Query
import time
import os
import math
import uvicorn

app = FastAPI(title="HPA Demo API", version="1.0.0")


@app.get("/health")
def health():
    """Health check endpoint for k8s probes."""
    return {"status": "healthy"}


@app.get("/")
def root():
    """Root endpoint with API documentation."""
    return {
        "message": "HPA Demo API - Kubernetes Load Testing",
        "endpoints": {
            "/health": "Health check",
            "/stress?duration=10": "CPU stress test (default: 10s)",
            "/docs": "OpenAPI documentation"
        },
        "pod_name": os.environ.get("HOSTNAME", "unknown")
    }


@app.get("/stress")
def stress(duration: int = Query(default=10, ge=1, le=60, description="Duration in seconds (1-60)")):
    """
    CPU stress test endpoint - continuous heavy computation.

    Args:
        duration: seconds to run stress test (default: 10, max: 60)

    Returns:
        JSON with completion status and execution time
    """
    start_time = time.time()

    # CPU-bound loop with heavy math operations
    result = 0
    while time.time() - start_time < duration:
        for i in range(10000):
            result += math.sqrt(i) * math.sin(i) * math.cos(i)

    elapsed = time.time() - start_time

    return {
        "status": "completed",
        "duration_seconds": round(elapsed, 2),
        "computation_result": round(result, 2),
        "pod_name": os.environ.get("HOSTNAME", "unknown")
    }


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print(f"Starting HPA Demo API on port {port}")
    print(f"Pod: {os.environ.get('HOSTNAME', 'unknown')}")
    uvicorn.run(app, host="0.0.0.0", port=port)
