import { createReportGenerator } from '../core/report-generator';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginAll } from '../core/auth-manager';
import { runAllEndpoints } from '../core/all-endpoints-runner';
import { teacherAccounts, studentAccounts } from '../data/accounts';
import { MixedSetupData } from '../types/scenario';

const stages = [
  { duration: '15s', target: 50 },
  { duration: '45s', target: 50 },
];

export const options: Options = buildOptions(stages, {
  http_req_duration: ['p(95)<500'],
  http_req_failed: ['rate<0.05'],
});

export const handleSummary = createReportGenerator('get-all-endpoints-quick').handleSummary;

const TEACHER_VUS = 25;
const STUDENT_VUS = 25;

export function setup(): MixedSetupData {
  console.log(`[QUICK] Setup: logging in ${TEACHER_VUS} teachers + ${STUDENT_VUS} students...`);
  const teacherTokens = loginAll(teacherAccounts, TEACHER_VUS);
  const studentTokens = loginAll(studentAccounts, STUDENT_VUS);
  console.log(`[QUICK] Setup complete: ${Object.keys(teacherTokens).length} teachers + ${Object.keys(studentTokens).length} students ready`);
  return { teacherTokens, studentTokens };
}

export default function (data: MixedSetupData): void {
  runAllEndpoints(data, { includeHeavyEndpoints: false, teacherVus: TEACHER_VUS });
}
