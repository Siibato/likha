import { BatchReport, VUBatch, BatchEndpointMetrics, ThresholdResult, ErrorDistribution } from '../types/report';
import { getReportPath } from './paths';

function formatDuration(ms: number): string {
  const seconds = Math.floor(ms / 1000);
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return mins > 0 ? `${mins}m${secs}s` : `${secs}s`;
}

function buildBatchEndpoints(metrics: Record<string, any>): Map<string, BatchEndpointMetrics[]> {
  const batchMap = new Map<string, Map<string, BatchEndpointMetrics>>();

  for (const [key, metric] of Object.entries(metrics)) {
    if (!key.startsWith('http_req_duration{')) continue;
    const nameMatch = key.match(/name:([^,}]+)/);
    if (!nameMatch) continue;

    const fullName = nameMatch[1];
    const colonIdx = fullName.indexOf(':');
    if (colonIdx === -1) continue;

    const batch = fullName.substring(0, colonIdx);
    const name = fullName.substring(colonIdx + 1);
    if (!batch.startsWith('vu-')) continue;

    const values = metric.values || {};
    const count = values.count ?? 0;
    const avg = values.avg ?? 0;

    // Skip placeholder sub-metrics that never had actual requests
    if (avg === 0) continue;

    const failedKey = `http_req_failed{name:${fullName}}`;
    const failedMetric = metrics[failedKey];
    const failCount = failedMetric?.values?.fails ?? 0;
    const failRate = count ? (failCount / count) * 100 : 0;

    if (!batchMap.has(batch)) batchMap.set(batch, new Map());
    batchMap.get(batch)!.set(name, {
      name,
      count,
      failRate: Math.round(failRate * 100) / 100,
      avg: values.avg ?? 0,
      p95: values['p(95)'] ?? 0,
      p99: values['p(99)'] ?? 0,
    });
  }

  const result = new Map<string, BatchEndpointMetrics[]>();
  for (const [batch, endpoints] of batchMap) {
    result.set(batch, Array.from(endpoints.values()).sort((a, b) => b.count - a.count));
  }
  return result;
}

function buildVUBatches(batchEndpoints: Map<string, BatchEndpointMetrics[]>): VUBatch[] {
  const batches = Array.from(batchEndpoints.keys()).sort((a, b) => {
    const na = parseInt(a.replace('vu-', ''), 10);
    const nb = parseInt(b.replace('vu-', ''), 10);
    return na - nb;
  });

  return batches
    .map((batch) => {
      const n = parseInt(batch.replace('vu-', ''), 10);
      const vuRange = `${n - 9}-${n}`;
      return {
        batch,
        vuRange,
        endpoints: batchEndpoints.get(batch) ?? [],
      };
    })
    .filter((b) => b.endpoints.length > 0);
}

function buildThresholds(metrics: Record<string, any>): ThresholdResult[] {
  const results: ThresholdResult[] = [];
  for (const [metricName, metric] of Object.entries(metrics)) {
    if (!metric.thresholds) continue;
    // Skip placeholder batch thresholds for sub-metrics that never had actual data
    if (metricName.startsWith('http_req_duration{name:vu-')) {
      const values = metric.values || {};
      if ((values.avg ?? 0) === 0) continue;
    }
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
  for (const [key, metric] of Object.entries(metrics)) {
    const statusMatch = key.match(/^http_reqs\{status:(\d+)/);
    if (!statusMatch) continue;
    const status = parseInt(statusMatch[1], 10);
    const count = metric.values?.count ?? 0;
    errors.push({
      status,
      count,
      percentage: Math.round((count / total) * 10000) / 100,
    });
  }

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

function buildBatchReport(scenarioName: string, data: Record<string, any>): BatchReport {
  const metrics = data.metrics ?? {};
  const state = data.state ?? {};
  const options = data.options ?? {};

  const httpReqs = metrics['http_reqs']?.values ?? {};
  const httpReqFailed = metrics['http_req_failed']?.values ?? {};

  const totalRequests = httpReqs.count ?? 0;
  const throughput = httpReqs.rate ?? 0;
  const failedRate = httpReqFailed.rate ?? 0;

  const vusMaxMetric = metrics['vus_max']?.values ?? {};
  const maxVusFromMetrics = vusMaxMetric.max ?? 0;
  const stages = options.stages ?? [];
  const maxVusFromStages = stages.length > 0 ? Math.max(...stages.map((s: any) => s.target ?? 0)) : 0;
  const scenarioStages = options.scenarios?.default?.stages ?? [];
  const maxVusFromScenarios = scenarioStages.length > 0 ? Math.max(...scenarioStages.map((s: any) => s.target ?? 0)) : 0;
  const maxVus = maxVusFromMetrics || maxVusFromStages || maxVusFromScenarios;

  const thresholdResults = buildThresholds(metrics);
  const passed = thresholdResults.length === 0 || thresholdResults.every((t) => t.passed);

  const batchEndpoints = buildBatchEndpoints(metrics);
  const vuBatches = buildVUBatches(batchEndpoints);

  return {
    meta: {
      scenario: scenarioName,
      timestamp: new Date().toISOString(),
      duration: formatDuration(state.testRunDurationMs ?? 0),
      maxVus,
      totalRequests,
      failedRate: Math.round(failedRate * 10000) / 100,
      throughput: Math.round(throughput * 100) / 100,
      passed,
    },
    vuBatches,
    thresholds: thresholdResults,
    errors: buildErrors(metrics),
  };
}

export function createBatchReportGenerator(scenarioName: string) {
  return {
    handleSummary(data: Record<string, any>): Record<string, string> {
      const report = buildBatchReport(scenarioName, data);

      const reportPath = getReportPath(scenarioName, report.meta.timestamp);
      const reportJson = JSON.stringify(report, null, 2);

      const { meta: m, thresholds: thr, vuBatches } = report;
      const pt = m.passed ? 'PASSED' : 'FAILED';

      // Collect all endpoint names and find top 5 by total count across all batches
      const endpointTotals = new Map<string, number>();
      for (const batch of vuBatches) {
        for (const ep of batch.endpoints) {
          endpointTotals.set(ep.name, (endpointTotals.get(ep.name) ?? 0) + ep.count);
        }
      }
      const topEndpoints = Array.from(endpointTotals.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([name]) => name);

      // Build degradation table: rows = top endpoints, columns = batches that ran
      const batchLabels = vuBatches.map((b) => b.batch);
      const colWidth = 10;
      const nameWidth = 22;

      const tableHeader = `  ${'Endpoint'.padEnd(nameWidth)} ${batchLabels.map((l) => l.padStart(colWidth)).join(' ')}`;
      const tableSeparator = `  ${'─'.repeat(nameWidth)} ${batchLabels.map(() => '─'.repeat(colWidth)).join(' ')}`;

      const tableRows = topEndpoints.map((epName) => {
        const cells = batchLabels.map((label) => {
          const batch = vuBatches.find((b) => b.batch === label);
          const ep = batch?.endpoints.find((e) => e.name === epName);
          return ep && ep.avg > 0 ? ep.avg.toFixed(1).padStart(colWidth) : '-'.padStart(colWidth);
        });
        return `  ${epName.padEnd(nameWidth).slice(0, nameWidth)} ${cells.join(' ')}`;
      });

      // Error summary
      const errSummary = report.errors.length
        ? `Errors: ${report.errors.map((e: ErrorDistribution) => `${e.status}=${e.count}`).join(', ')}`
        : '';

      const lines = [
        `\n══════════════ ${m.scenario.toUpperCase()} — ${pt} ══════════════`,
        `Duration: ${m.duration}  ·  Max VUs: ${m.maxVus}  ·  Total Requests: ${m.totalRequests.toLocaleString()}`,
        `Throughput: ${m.throughput.toFixed(1)} req/s  ·  Failed Rate: ${m.failedRate.toFixed(2)}%`,
        ...(errSummary ? [errSummary] : []),
        '',
        `VU Batch Degradation (avg ms)`,
        tableHeader,
        tableSeparator,
        ...tableRows,
        '',
        ...(thr.length
          ? [`Thresholds: ${thr.filter((t: ThresholdResult) => t.passed).length}/${thr.length} passed`]
          : []),
        ...(thr.filter((t: ThresholdResult) => !t.passed).slice(0, 10).map((t: ThresholdResult) => `  ✗ ${t.metric} — ${t.rule}`)),
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
