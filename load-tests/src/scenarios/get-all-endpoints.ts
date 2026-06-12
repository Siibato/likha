import { createReportGenerator } from '../core/report-generator';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginAll } from '../core/auth-manager';
import { runAllEndpoints } from '../core/all-endpoints-runner';
import { buildRoleMap } from '../core/role-map';
import { endpointThresholds } from '../config/thresholds';
import { teacherAccounts, studentAccounts, adminAccounts } from '../data/accounts';
import { MixedSetupData } from '../types/scenario';

const TOTAL_VUS = 200;

const stages = [
  { duration: '30s', target: 10 },
  { duration: '2m', target: 50 },
  { duration: '3m', target: 100 },
  { duration: '3m', target: TOTAL_VUS },
  { duration: '30s', target: 0 },
];


export const options: Options = buildOptions(stages, {
  http_req_duration: ['p(95)<2000'],
  http_req_failed: ['rate<0.05'],
  checks: ['rate>0.90'],
}, endpointThresholds);

export const handleSummary = createReportGenerator('get-all-endpoints').handleSummary;

const TEACHER_VUS = 76;
const STUDENT_VUS = 120;
const ADMIN_VUS = 4;

export function setup(): MixedSetupData {
  console.log(`Setup: logging in ${ADMIN_VUS} admins + ${TEACHER_VUS} teachers + ${STUDENT_VUS} students...`);
  const adminTokens = loginAll(adminAccounts, ADMIN_VUS);
  const teacherTokens = loginAll(teacherAccounts, TEACHER_VUS);
  const studentTokens = loginAll(studentAccounts, STUDENT_VUS);
  console.log(`Setup complete: ${Object.keys(adminTokens).length} admins + ${Object.keys(teacherTokens).length} teachers + ${Object.keys(studentTokens).length} students ready`);

  const { roleMap, vuTokens } = buildRoleMap(TEACHER_VUS, STUDENT_VUS, ADMIN_VUS, teacherTokens, studentTokens, adminTokens);
  return { adminTokens, teacherTokens, studentTokens, roleMap, vuTokens };
}

export default function (data: MixedSetupData): void {
  runAllEndpoints(data, { includeHeavyEndpoints: true, teacherVus: TEACHER_VUS, studentVus: STUDENT_VUS, adminVus: ADMIN_VUS });
}
