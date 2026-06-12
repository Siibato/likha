import { createReportGenerator } from '../core/report-generator';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginAll } from '../core/auth-manager';
import { runAllEndpoints } from '../core/all-endpoints-runner';
import { buildRoleMap } from '../core/role-map';
import { endpointThresholds } from '../config/thresholds';
import { teacherAccounts, studentAccounts, adminAccounts } from '../data/accounts';
import { MixedSetupData } from '../types/scenario';

const stages = [
  { duration: '15s', target: 50 },
  { duration: '45s', target: 50 },
];

// Derive from shared thresholds — omit heavy endpoints not run by this scenario
const {
  'http_req_duration{name:Teacher:AllGradeData}': _allGradeData,
  'http_req_duration{name:Teacher:SF9}': _sf9,
  'http_req_duration{name:Teacher:SF10}': _sf10,
  'http_req_duration{name:Shared:SubmissionDownload}': _subDownload,
  'http_req_duration{name:Shared:MaterialDownload}': _matDownload,
  ...quickEndpointThresholds
} = endpointThresholds;

export const options: Options = buildOptions(stages, {
  http_req_duration: ['p(95)<500'],
  http_req_failed: ['rate<0.05'],
}, quickEndpointThresholds);

export const handleSummary = createReportGenerator('get-all-endpoints-quick').handleSummary;

const TEACHER_VUS = 19;
const STUDENT_VUS = 30;
const ADMIN_VUS = 1;

export function setup(): MixedSetupData {
  console.log(`[QUICK] Setup: logging in ${ADMIN_VUS} admins + ${TEACHER_VUS} teachers + ${STUDENT_VUS} students...`);
  const adminTokens = loginAll(adminAccounts, ADMIN_VUS);
  const teacherTokens = loginAll(teacherAccounts, TEACHER_VUS);
  const studentTokens = loginAll(studentAccounts, STUDENT_VUS);
  console.log(`[QUICK] Setup complete: ${Object.keys(adminTokens).length} admins + ${Object.keys(teacherTokens).length} teachers + ${Object.keys(studentTokens).length} students ready`);

  const { roleMap, vuTokens } = buildRoleMap(TEACHER_VUS, STUDENT_VUS, ADMIN_VUS, teacherTokens, studentTokens, adminTokens);
  return { adminTokens, teacherTokens, studentTokens, roleMap, vuTokens };
}

export default function (data: MixedSetupData): void {
  runAllEndpoints(data, { includeHeavyEndpoints: false, teacherVus: TEACHER_VUS, studentVus: STUDENT_VUS, adminVus: ADMIN_VUS });
}
