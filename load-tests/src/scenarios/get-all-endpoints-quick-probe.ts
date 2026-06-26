import { Options } from 'k6/options';
import { createReportGenerator } from '../core/report-generator';
import { buildOptions } from '../core/scenario-builder';
import { loginOne } from '../core/auth-manager';
import { runAllEndpointsProbe } from '../core/diagnostic-all-endpoints-runner';
import { teacherAccounts, studentAccounts, adminAccounts } from '../data/accounts';

const stages = [
  { duration: '30s', target: 200 },
  { duration: '30s', target: 200 },
];

export const options: Options = buildOptions(stages, {
  http_req_failed: [{ threshold: 'rate<0.0001', abortOnFail: true, delayAbortEval: '0s' }],
  checks: ['rate>0.99'],
});

export function setup(): { teacher: string; student: string; admin: string } {
  console.log('Setup: logging in 1 teacher + 1 student + 1 admin...');
  const teacher = loginOne(teacherAccounts[0]);
  const student = loginOne(studentAccounts[0]);
  const admin = loginOne(adminAccounts[0]);
  console.log('Setup complete');
  return { teacher, student, admin };
}

export default function (tokens: { teacher: string; student: string; admin: string }): void {
  runAllEndpointsProbe(tokens);
}

export const handleSummary = createReportGenerator('get-all-endpoints-quick-probe').handleSummary;
