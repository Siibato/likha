import { Options } from 'k6/options';
import { createBatchReportGenerator } from '../core/batch-report-generator';
import { buildOptions } from '../core/scenario-builder';
import { loginOne } from '../core/auth-manager';
import { runDiagnosticProbeNoThrow, DIAGNOSTIC_ENDPOINT_NAMES } from '../core/diagnostic-runner';
import { teacherAccounts, studentAccounts, adminAccounts } from '../data/accounts';

const stages = [
  { duration: '10s', target: 10 },
  { duration: '10s', target: 20 },
  { duration: '10s', target: 30 },
  { duration: '10s', target: 40 },
  { duration: '10s', target: 50 },
  { duration: '10s', target: 60 },
  { duration: '10s', target: 70 },
  { duration: '10s', target: 80 },
  { duration: '10s', target: 90 },
  { duration: '10s', target: 100 },
  { duration: '10s', target: 110 },
  { duration: '10s', target: 120 },
  { duration: '10s', target: 130 },
  { duration: '10s', target: 140 },
  { duration: '10s', target: 150 },
  { duration: '10s', target: 160 },
  { duration: '10s', target: 170 },
  { duration: '10s', target: 180 },
  { duration: '10s', target: 190 },
  { duration: '10s', target: 200 },
  { duration: '10s', target: 210 },
  { duration: '10s', target: 220 },
  { duration: '10s', target: 230 },
  { duration: '10s', target: 240 },
  { duration: '10s', target: 250 },
  { duration: '10s', target: 260 },
  { duration: '10s', target: 270 },
  { duration: '10s', target: 280 },
  { duration: '10s', target: 290 },
  { duration: '10s', target: 300 },
  { duration: '10s', target: 310 },
  { duration: '10s', target: 320 },
  { duration: '10s', target: 330 },
  { duration: '10s', target: 340 },
  { duration: '10s', target: 350 },
  { duration: '10s', target: 360 },
  { duration: '10s', target: 370 },
  { duration: '10s', target: 380 },
  { duration: '10s', target: 390 },
  { duration: '10s', target: 400 },
  { duration: '10s', target: 410 },
  { duration: '10s', target: 420 },
  { duration: '10s', target: 430 },
  { duration: '10s', target: 440 },
  { duration: '10s', target: 450 },
  { duration: '10s', target: 460 },
  { duration: '10s', target: 470 },
  { duration: '10s', target: 480 },
  { duration: '10s', target: 490 },
  { duration: '10s', target: 500 },
];

// Generate per-batch per-endpoint thresholds to force k6 to create sub-metrics.
// Without thresholds referencing the name tag, k6 does not break out sub-metrics.
const maxBatch = Math.max(...stages.map((s) => s.target));
const batchThresholds: Record<string, string[]> = {};
for (let batch = 10; batch <= maxBatch; batch += 10) {
  for (const ep of DIAGNOSTIC_ENDPOINT_NAMES) {
    batchThresholds[`http_req_duration{name:vu-${batch}:${ep}}`] = ['p(99)<999999'];
  }
}

export const options: Options = buildOptions(stages, {
  http_req_failed: [{ threshold: 'rate<0.0001', abortOnFail: true, delayAbortEval: '0s' }],
  checks: ['rate>0.99'],
}, batchThresholds);

export function setup(): { teacher: string; student: string; admin: string } {
  console.log('Setup: logging in 1 teacher + 1 student + 1 admin...');
  const teacher = loginOne(teacherAccounts[0]);
  const student = loginOne(studentAccounts[0]);
  const admin = loginOne(adminAccounts[0]);
  console.log('Setup complete');
  return { teacher, student, admin };
}

export default function (tokens: { teacher: string; student: string; admin: string }): void {
  const vuBatch = 'vu-' + Math.ceil(__VU / 10) * 10;
  runDiagnosticProbeNoThrow(tokens, vuBatch);
}

export const handleSummary = createBatchReportGenerator('load-test-to-failure').handleSummary;
