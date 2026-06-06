import { ScenarioReport, EndpointMetrics, ThresholdResult, ErrorDistribution } from '../types/report';
import { getReportPath } from './paths';

// k6's handleSummary runs in a special context where we can return file outputs
// Each test run generates a new timestamped JSON file in reports/{scenario}/

function formatDuration(ms: number): string {
  const seconds = Math.floor(ms / 1000);
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return mins > 0 ? `${mins}m${secs}s` : `${secs}s`;
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} kB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function extractPercentiles(values: Record<string, number>): Pick<EndpointMetrics, 'p10' | 'p20' | 'p30' | 'p40' | 'p50' | 'p60' | 'p70' | 'p80' | 'p90' | 'p95' | 'p99'> {
  return {
    p10: values['p(10)'] ?? 0,
    p20: values['p(20)'] ?? 0,
    p30: values['p(30)'] ?? 0,
    p40: values['p(40)'] ?? 0,
    p50: values['p(50)'] ?? 0,
    p60: values['p(60)'] ?? 0,
    p70: values['p(70)'] ?? 0,
    p80: values['p(80)'] ?? 0,
    p90: values['p(90)'] ?? 0,
    p95: values['p(95)'] ?? 0,
    p99: values['p(99)'] ?? 0,
  };
}

function buildEndpoints(metrics: Record<string, any>): EndpointMetrics[] {
  const endpoints: EndpointMetrics[] = [];

  // k6 sub-metrics for http_req_duration are keyed like "http_req_duration{name:ClassList}"
  // or "http_req_duration{expected_response:true}" — we only want the custom name tags
  for (const [key, metric] of Object.entries(metrics)) {
    if (!key.startsWith('http_req_duration{')) continue;
    const nameMatch = key.match(/name:([^,}]+)/);
    if (!nameMatch) continue;

    const name = nameMatch[1];
    const values = metric.values || {};

    // Find matching failed sub-metric
    const failedKey = `http_req_failed{name:${name}}`;
    const failedMetric = metrics[failedKey];
    const failCount = failedMetric?.values?.fails ?? 0;
    const failRate = values.count ? (failCount / values.count) * 100 : 0;

    endpoints.push({
      name,
      count: values.count ?? 0,
      failCount,
      failRate: Math.round(failRate * 100) / 100,
      min: values.min ?? 0,
      avg: values.avg ?? 0,
      med: values.med ?? 0,
      max: values.max ?? 0,
      ...extractPercentiles(values),
    });
  }

  // Sort by request count descending
  return endpoints.sort((a, b) => b.count - a.count);
}

function buildThresholds(metrics: Record<string, any>): ThresholdResult[] {
  const results: ThresholdResult[] = [];

  for (const [metricName, metric] of Object.entries(metrics)) {
    if (!metric.thresholds) continue;
    for (const [ruleName, threshold] of Object.entries(metric.thresholds as Record<string, { ok: boolean }>)) {
      results.push({
        metric: metricName,
        rule: ruleName,
        passed: threshold.ok,
        actual: threshold.ok ? 'pass' : 'fail',
      });
    }
  }

  return results;
}

function buildErrors(metrics: Record<string, any>): ErrorDistribution[] {
  const httpReqs = metrics['http_reqs']?.values ?? {};
  const total = httpReqs.count ?? 0;
  if (total === 0) return [];

  const errors: ErrorDistribution[] = [];

  // k6 tracks status codes via http_reqs{status:XXX} sub-metrics
  for (const [key, metric] of Object.entries(metrics)) {
    const statusMatch = key.match(/^http_reqs\{status:(\d+)\}$/);
    if (!statusMatch) continue;
    const status = parseInt(statusMatch[1], 10);
    const count = metric.values?.count ?? 0;
    errors.push({
      status,
      count,
      percentage: Math.round((count / total) * 10000) / 100,
    });
  }

  // Timeouts
  const timeoutKey = 'http_req_waiting{expected_response:false}';
  const timeoutMetric = metrics[timeoutKey];
  if (timeoutMetric?.values?.count) {
    errors.push({
      status: 'timeout',
      count: timeoutMetric.values.count,
      percentage: Math.round((timeoutMetric.values.count / total) * 10000) / 100,
    });
  }

  return errors.sort((a, b) => b.count - a.count);
}

function buildReport(scenarioName: string, data: Record<string, any>): ScenarioReport {
  const metrics = data.metrics ?? {};
  const state = data.state ?? {};
  const options = data.options ?? {};

  const httpReqs = metrics['http_reqs']?.values ?? {};
  const httpReqDuration = metrics['http_req_duration']?.values ?? {};
  const httpReqFailed = metrics['http_req_failed']?.values ?? {};
  const dataReceived = metrics['data_received']?.values ?? {};
  const dataSent = metrics['data_sent']?.values ?? {};

  const totalRequests = httpReqs.count ?? 0;
  const throughput = httpReqs.rate ?? 0;
  const failedRate = httpReqFailed.rate ?? 0;
  const p95 = httpReqDuration['p(95)'] ?? 0;

  // Max VUs from stages
  const stages = options.stages ?? [];
  const maxVus = stages.length > 0 ? Math.max(...stages.map((s: any) => s.target ?? 0)) : 0;

  // Check if all thresholds passed
  const thresholdResults = buildThresholds(metrics);
  const passed = thresholdResults.length === 0 || thresholdResults.every((t) => t.passed);

  // Note: Previous run comparison is now handled by the dashboard
  // which loads multiple reports and compares client-side

  return {
    meta: {
      scenario: scenarioName,
      timestamp: new Date().toISOString(),
      duration: formatDuration(state.testRunDurationMs ?? 0),
      maxVus,
      totalRequests,
      failedRate: Math.round(failedRate * 10000) / 100,
      throughput: Math.round(throughput * 100) / 100,
      dataReceived: formatBytes(dataReceived.sum ?? 0),
      dataSent: formatBytes(dataSent.sum ?? 0),
      passed,
      p95,
    },
    endpoints: buildEndpoints(metrics),
    thresholds: thresholdResults,
    errors: buildErrors(metrics),
  };
}

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function buildHtml(report: ScenarioReport): string {
  const { meta, endpoints, thresholds, errors } = report;
  const ts = meta.timestamp.replace(/[:.]/g, '-');

  const passClass = meta.passed ? 'pass' : 'fail';
  const passText = meta.passed ? 'PASSED' : 'FAILED';

  // Thresholds table
  const thresholdsHtml = thresholds.length
    ? `<table class="thresholds">
        <tr><th>Metric</th><th>Rule</th><th>Result</th></tr>
        ${thresholds
          .map(
            (t) =>
              `<tr class="${t.passed ? 'pass' : 'fail'}"><td>${escapeHtml(t.metric)}</td><td>${escapeHtml(t.rule)}</td><td>${t.passed ? '✓ pass' : '✗ fail'}</td></tr>`
          )
          .join('')}
      </table>`
    : '<p>No thresholds configured.</p>';

  // Endpoints table
  const endpointsHtml = endpoints.length
    ? `<table class="endpoints">
        <tr>
          <th>Endpoint</th><th>Count</th><th>Fail%</th>
          <th>Min</th><th>Avg</th><th>Med</th>
          <th>p10</th><th>p20</th><th>p30</th><th>p40</th><th>p50</th>
          <th>p60</th><th>p70</th><th>p80</th><th>p90</th><th>p95</th><th>p99</th>
          <th>Max</th>
        </tr>
        ${endpoints
          .map((e) => {
            const p95Class = e.p95 > 200 ? 'slow' : '';
            return `<tr>
              <td>${escapeHtml(e.name)}</td>
              <td>${e.count}</td>
              <td class="${e.failRate > 0 ? 'fail' : ''}">${e.failRate.toFixed(2)}%</td>
              <td>${e.min.toFixed(2)}</td>
              <td>${e.avg.toFixed(2)}</td>
              <td>${e.med.toFixed(2)}</td>
              <td>${e.p10.toFixed(2)}</td>
              <td>${e.p20.toFixed(2)}</td>
              <td>${e.p30.toFixed(2)}</td>
              <td>${e.p40.toFixed(2)}</td>
              <td>${e.p50.toFixed(2)}</td>
              <td>${e.p60.toFixed(2)}</td>
              <td>${e.p70.toFixed(2)}</td>
              <td>${e.p80.toFixed(2)}</td>
              <td>${e.p90.toFixed(2)}</td>
              <td class="${p95Class}">${e.p95.toFixed(2)}</td>
              <td>${e.p99.toFixed(2)}</td>
              <td>${e.max.toFixed(2)}</td>
            </tr>`;
          })
          .join('')}
      </table>`
    : '<p>No endpoint data available.</p>';

  // Errors table
  const errorsHtml = errors.length
    ? `<table class="errors">
        <tr><th>Status</th><th>Count</th><th>%</th></tr>
        ${errors
          .map((e) => `<tr><td>${e.status}</td><td>${e.count}</td><td>${e.percentage.toFixed(2)}%</td></tr>`)
          .join('')}
      </table>`
    : '<p>No errors recorded.</p>';

  // Note: Previous run comparison is now handled by the dashboard
  // which can load and compare multiple reports client-side
  const comparisonHtml = '<p>Compare runs using the web dashboard.</p>';

  // Latency bar chart (CSS-only)
  const chartHtml = endpoints.length
    ? `<div class="chart">
        ${endpoints
          .map((e) => {
            const maxBar = Math.max(...endpoints.map((ep) => ep.p95));
            const width = maxBar > 0 ? (e.p95 / maxBar) * 100 : 0;
            return `<div class="bar-row">
              <span class="bar-label">${escapeHtml(e.name)}</span>
              <div class="bar-track"><div class="bar-fill" style="width:${width.toFixed(1)}%"></div></div>
              <span class="bar-value">${e.p95.toFixed(0)}ms</span>
            </div>`;
          })
          .join('')}
      </div>`
    : '';

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>${escapeHtml(meta.scenario)} — k6 Report</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; padding: 2rem; background: #f5f5f5; color: #333; }
  .container { max-width: 1400px; margin: 0 auto; background: #fff; border-radius: 8px; padding: 2rem; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
  h1 { margin: 0 0 0.5rem; font-size: 1.8rem; }
  .badge { display: inline-block; padding: 0.3rem 0.8rem; border-radius: 4px; font-weight: 600; font-size: 0.9rem; }
  .badge.pass { background: #d4edda; color: #155724; }
  .badge.fail { background: #f8d7da; color: #721c24; }
  .meta { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin: 1.5rem 0; }
  .meta-card { background: #f8f9fa; padding: 1rem; border-radius: 6px; }
  .meta-card .label { font-size: 0.8rem; color: #666; text-transform: uppercase; letter-spacing: 0.05em; }
  .meta-card .value { font-size: 1.4rem; font-weight: 600; margin-top: 0.3rem; }
  h2 { margin-top: 2rem; font-size: 1.3rem; border-bottom: 2px solid #eee; padding-bottom: 0.5rem; }
  table { width: 100%; border-collapse: collapse; margin-top: 1rem; font-size: 0.85rem; }
  th, td { padding: 0.5rem 0.6rem; text-align: right; border-bottom: 1px solid #eee; }
  th { text-align: left; background: #f8f9fa; font-weight: 600; }
  td:first-child, th:first-child { text-align: left; }
  tr:hover { background: #f8f9fa; }
  .pass { color: #28a745; }
  .fail { color: #dc3545; }
  .slow { color: #dc3545; font-weight: 600; }
  .chart { margin-top: 1rem; }
  .bar-row { display: flex; align-items: center; gap: 0.5rem; margin: 0.4rem 0; }
  .bar-label { width: 180px; font-size: 0.8rem; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .bar-track { flex: 1; height: 18px; background: #e9ecef; border-radius: 3px; overflow: hidden; }
  .bar-fill { height: 100%; background: #4dabf7; border-radius: 3px; }
  .bar-value { width: 60px; font-size: 0.8rem; text-align: right; }
  .timestamp { color: #666; font-size: 0.9rem; margin-bottom: 1rem; }
</style>
</head>
<body>
<div class="container">
  <h1>${escapeHtml(meta.scenario)} <span class="badge ${passClass}">${passText}</span></h1>
  <div class="timestamp">${meta.timestamp} · Duration: ${meta.duration} · Max VUs: ${meta.maxVus}</div>

  <div class="meta">
    <div class="meta-card"><div class="label">Total Requests</div><div class="value">${meta.totalRequests.toLocaleString()}</div></div>
    <div class="meta-card"><div class="label">Failed Rate</div><div class="value ${meta.failedRate > 0 ? 'fail' : 'pass'}">${meta.failedRate.toFixed(2)}%</div></div>
    <div class="meta-card"><div class="label">Throughput</div><div class="value">${meta.throughput.toFixed(1)} req/s</div></div>
    <div class="meta-card"><div class="label">Data Received</div><div class="value">${meta.dataReceived}</div></div>
    <div class="meta-card"><div class="label">Data Sent</div><div class="value">${meta.dataSent}</div></div>
  </div>

  <h2>Thresholds</h2>
  ${thresholdsHtml}

  <h2>Latency by Endpoint (p95 bar chart)</h2>
  ${chartHtml}

  <h2>Per-Endpoint Metrics</h2>
  ${endpointsHtml}

  <h2>Error Distribution</h2>
  ${errorsHtml}

  <h2>Comparison with Previous Run</h2>
  ${comparisonHtml}
</div>
</body>
</html>`;
}

export function createReportGenerator(scenarioName: string) {
  return {
    handleSummary(data: Record<string, any>): Record<string, string> {
      const report = buildReport(scenarioName, data);

      // Generate timestamped output path for this run
      const reportPath = getReportPath(scenarioName, report.meta.timestamp);
      const reportJson = JSON.stringify(report, null, 2);

      // Rich CLI summary — build directly from raw k6 metrics
      const { meta: m, thresholds: thr } = report;
      const pt = m.passed ? 'PASSED' : 'FAILED';
      const metrics = data.metrics ?? {};

      // Extract endpoints directly from metrics (same logic as buildEndpoints)
      const cliEndpoints: EndpointMetrics[] = [];
      for (const [key, metric] of Object.entries(metrics) as [string, any][]) {
        if (!key.startsWith('http_req_duration{')) continue;
        const nameMatch = key.match(/name:([^,}]+)/);
        if (!nameMatch) continue;
        const name = nameMatch[1];
        const v = metric.values || {};
        const failedKey = `http_req_failed{name:${name}}`;
        const failedMetric = metrics[failedKey];
        const failCount = failedMetric?.values?.fails ?? 0;
        const count = v.count ?? 0;
        cliEndpoints.push({
          name,
          count,
          failCount,
          failRate: count ? (failCount / count) * 100 : 0,
          min: v.min ?? 0,
          avg: v.avg ?? 0,
          med: v.med ?? 0,
          p10: v['p(10)'] ?? 0,
          p20: v['p(20)'] ?? 0,
          p30: v['p(30)'] ?? 0,
          p40: v['p(40)'] ?? 0,
          p50: v['p(50)'] ?? 0,
          p60: v['p(60)'] ?? 0,
          p70: v['p(70)'] ?? 0,
          p80: v['p(80)'] ?? 0,
          p90: v['p(90)'] ?? 0,
          p95: v['p(95)'] ?? 0,
          p99: v['p(99)'] ?? 0,
          max: v.max ?? 0,
        });
      }
      cliEndpoints.sort((a, b) => b.count - a.count);

      // Checks from raw metrics
      const checksMetric = metrics['checks']?.values ?? {};
      const checksRate = checksMetric.rate ?? 0;
      const checksPasses = checksMetric.passes ?? 0;
      const checksFails = checksMetric.fails ?? 0;

      // Overall latency percentiles
      const dur = metrics['http_req_duration']?.values ?? {};
      const overallLatency = dur.count
        ? `\nOverall Latency  min: ${(dur.min ?? 0).toFixed(1)}ms  avg: ${(dur.avg ?? 0).toFixed(1)}ms  med: ${(dur.med ?? 0).toFixed(1)}ms  p95: ${(dur['p(95)'] ?? 0).toFixed(1)}ms  max: ${(dur.max ?? 0).toFixed(1)}ms`
        : '';

      // ASCII bar chart for p95 latency
      const maxP95 = cliEndpoints.length ? Math.max(...cliEndpoints.map((e) => e.p95)) : 0;
      const barWidth = 40;
      const barChart = cliEndpoints.length
        ? [
            '\np95 Latency by Endpoint',
            ...cliEndpoints.slice(0, 6).map((e: EndpointMetrics) => {
              const len = maxP95 > 0 ? Math.round((e.p95 / maxP95) * barWidth) : 0;
              const bar = '█'.repeat(len) + '░'.repeat(barWidth - len);
              const label = e.name.padEnd(20, ' ').slice(0, 20);
              return `  ${label} ${bar} ${e.p95.toFixed(1)}ms`;
            }),
          ]
        : [];

      // Checks summary
      const checksLine = checksPasses + checksFails > 0
        ? `Checks: ${(checksRate * 100).toFixed(1)}% pass  (${checksPasses} / ${checksPasses + checksFails})`
        : '';

      // Error summary
      const errSummary = report.errors.length
        ? `Errors: ${report.errors.map((e: ErrorDistribution) => `${e.status}=${e.count}`).join(', ')}`
        : '';

      // Endpoint table (top 6, aligned)
      const topEp = cliEndpoints.slice(0, 6);
      const epHeader = topEp.length
        ? '\nEndpoint               Count    Fail%    Min      Avg      Med      p95      Max'
        : '\nNo endpoint metrics found.';
      const epRows = topEp.map((e: EndpointMetrics) => {
        const name = e.name.padEnd(20, ' ').slice(0, 20);
        return `  ${name} ${String(e.count).padStart(6)}  ${(e.failRate.toFixed(2) + '%').padStart(6)}  ${e.min.toFixed(1).padStart(6)}ms  ${e.avg.toFixed(1).padStart(6)}ms  ${e.med.toFixed(1).padStart(6)}ms  ${e.p95.toFixed(1).padStart(6)}ms  ${e.max.toFixed(1).padStart(6)}ms`;
      });

      const lines = [
        `\n══════════════ ${m.scenario.toUpperCase()} — ${pt} ══════════════`,
        `Duration: ${m.duration}  ·  Max VUs: ${m.maxVus}  ·  Total Requests: ${m.totalRequests.toLocaleString()}`,
        `Throughput: ${m.throughput.toFixed(1)} req/s  ·  Failed Rate: ${m.failedRate.toFixed(2)}%  ·  p95: ${m.p95.toFixed(2)}ms`,
        ...(checksLine ? [checksLine] : []),
        ...(errSummary ? [errSummary] : []),
        ...(overallLatency ? [overallLatency] : []),
        ...barChart,
        epHeader,
        ...epRows,
        ...(thr.length
          ? [
              `\nThresholds: ${thr.filter((t: ThresholdResult) => t.passed).length}/${thr.length} passed`,
            ]
          : []),
        ...(thr.filter((t: ThresholdResult) => !t.passed).map((t: ThresholdResult) => `  ✗ ${t.metric} — ${t.rule}`)),
        '════════════════════════════════════════════════════\n',
      ];
      const stdout = lines.join('\n');

      return {
        [reportPath]: reportJson,
        stdout,
      };
    },
  };
}
