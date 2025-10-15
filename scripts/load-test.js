import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 10 },   // Ramp up to 10 VUs
    { duration: '1m', target: 50 },    // Ramp up to 50 VUs
    { duration: '2m', target: 100 },   // Peak load: 100 VUs
    { duration: '1m', target: 50 },    // Ramp down to 50 VUs
    { duration: '30s', target: 0 },    // Ramp down to 0
  ],
  thresholds: {
    'http_req_duration': ['p(95)<5000'],  // 95% of requests under 5s
    'http_req_failed': ['rate<0.01'],     // Error rate < 1%
    'errors': ['rate<0.01'],              // Custom error rate < 1%
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:8080';

export default function () {
  // Hit the stress endpoint
  const res = http.get(`${BASE_URL}/stress?duration=15`);

  // Validate response
  const success = check(res, {
    'status is 200': (r) => r.status === 200,
    'response has status': (r) => r.json('status') === 'completed',
    'response has pod_name': (r) => r.json('pod_name') !== undefined,
  });

  // Track errors
  errorRate.add(!success);

  // Small delay between iterations
  sleep(1);
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'load-test-results.json': JSON.stringify(data),
  };
}

function textSummary(data, options) {
  const indent = options.indent || '';
  const enableColors = options.enableColors || false;

  let summary = '\n';
  summary += `${indent}====================================\n`;
  summary += `${indent}     K6 LOAD TEST SUMMARY\n`;
  summary += `${indent}====================================\n\n`;

  // Requests
  const requests = data.metrics.http_reqs.values.count;
  const rps = data.metrics.http_reqs.values.rate.toFixed(2);
  summary += `${indent}📊 Requests:\n`;
  summary += `${indent}  Total: ${requests}\n`;
  summary += `${indent}  RPS: ${rps}\n\n`;

  // Response times
  const p50 = data.metrics.http_req_duration.values['p(50)'].toFixed(2);
  const p95 = data.metrics.http_req_duration.values['p(95)'].toFixed(2);
  const p99 = data.metrics.http_req_duration.values['p(99)'].toFixed(2);
  const avg = data.metrics.http_req_duration.values.avg.toFixed(2);
  const max = data.metrics.http_req_duration.values.max.toFixed(2);

  summary += `${indent}⏱️  Response Time (ms):\n`;
  summary += `${indent}  Average: ${avg}\n`;
  summary += `${indent}  P50: ${p50}\n`;
  summary += `${indent}  P95: ${p95}\n`;
  summary += `${indent}  P99: ${p99}\n`;
  summary += `${indent}  Max: ${max}\n\n`;

  // Errors
  const failed = data.metrics.http_req_failed.values.rate * 100;
  const errorPct = (data.metrics.errors.values.rate * 100).toFixed(2);
  summary += `${indent}❌ Errors:\n`;
  summary += `${indent}  Failed requests: ${failed.toFixed(2)}%\n`;
  summary += `${indent}  Error rate: ${errorPct}%\n\n`;

  // Virtual Users
  const vus = data.metrics.vus.values.max;
  summary += `${indent}👥 Virtual Users: ${vus}\n\n`;

  summary += `${indent}====================================\n`;

  return summary;
}
