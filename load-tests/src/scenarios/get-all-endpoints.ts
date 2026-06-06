import { createReportGenerator } from '../core/report-generator';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginAll } from '../core/auth-manager';
import { runAllEndpoints } from '../core/all-endpoints-runner';
import { teacherAccounts, studentAccounts } from '../data/accounts';
import { MixedSetupData } from '../types/scenario';

const stages = [
  { duration: '30s', target: 10 },
  { duration: '2m', target: 50 },
  { duration: '3m', target: 100 },
  { duration: '3m', target: 200 },
  { duration: '30s', target: 0 },
];

// ===== ENDPOINT-SPECIFIC THRESHOLDS =====
const endpointThresholds = {
  // Fast endpoints (< 200ms p95)
  'http_req_duration{name:Health:Check}': ['p(95)<200'],
  'http_req_duration{name:Health:Ready}': ['p(95)<200'],
  'http_req_duration{name:Health:DatabaseId}': ['p(95)<200'],
  'http_req_duration{name:Auth:Me}': ['p(95)<200'],
  'http_req_duration{name:Shared:ClassMetadata}': ['p(95)<200'],
  'http_req_duration{name:Shared:AssessmentMetadata}': ['p(95)<200'],
  'http_req_duration{name:Shared:AssignmentMetadata}': ['p(95)<200'],
  'http_req_duration{name:Shared:MaterialMetadata}': ['p(95)<200'],
  'http_req_duration{name:Teacher:GradingConfig}': ['p(95)<200'],
  'http_req_duration{name:Teacher:GradeItems}': ['p(95)<200'],
  'http_req_duration{name:Teacher:TosList}': ['p(95)<200'],
  'http_req_duration{name:Teacher:TosDetail}': ['p(95)<200'],
  'http_req_duration{name:Teacher:MelcsSearch}': ['p(95)<300'],
  
  // Medium endpoints (< 500ms p95)
  'http_req_duration{name:Teacher:ClassList}': ['p(95)<500'],
  'http_req_duration{name:Student:ClassList}': ['p(95)<500'],
  'http_req_duration{name:Teacher:ClassDetail}': ['p(95)<500'],
  'http_req_duration{name:Student:ClassDetail}': ['p(95)<500'],
  'http_req_duration{name:Teacher:AssessmentList}': ['p(95)<500'],
  'http_req_duration{name:Student:AssessmentList}': ['p(95)<500'],
  'http_req_duration{name:Teacher:AssessmentDetail}': ['p(95)<500'],
  'http_req_duration{name:Student:AssessmentDetail}': ['p(95)<500'],
  'http_req_duration{name:Teacher:AssessmentSubmissions}': ['p(95)<500'],
  'http_req_duration{name:Teacher:SubmissionDetail}': ['p(95)<500'],
  'http_req_duration{name:Teacher:StudentAssessmentSubmissions}': ['p(95)<500'],
  'http_req_duration{name:Teacher:AssessmentStats}': ['p(95)<500'],
  'http_req_duration{name:Teacher:AssignmentList}': ['p(95)<500'],
  'http_req_duration{name:Student:AssignmentList}': ['p(95)<500'],
  'http_req_duration{name:Teacher:AssignmentDetail}': ['p(95)<500'],
  'http_req_duration{name:Student:AssignmentDetail}': ['p(95)<500'],
  'http_req_duration{name:Teacher:AssignmentSubmissions}': ['p(95)<500'],
  'http_req_duration{name:Teacher:AssignmentSubmissionDetail}': ['p(95)<500'],
  'http_req_duration{name:Teacher:StudentAssignmentSubmissions}': ['p(95)<500'],
  'http_req_duration{name:Teacher:Grades}': ['p(95)<500'],
  'http_req_duration{name:Student:MyGrades}': ['p(95)<500'],
  'http_req_duration{name:Student:MyQuarterGrades}': ['p(95)<500'],
  'http_req_duration{name:Teacher:GradeSummary}': ['p(95)<500'],
  'http_req_duration{name:Teacher:FinalGrades}': ['p(95)<500'],
  'http_req_duration{name:Teacher:GeneralAverages}': ['p(95)<500'],
  'http_req_duration{name:Teacher:DepedPresets}': ['p(95)<500'],
  'http_req_duration{name:Teacher:ItemScores}': ['p(95)<500'],
  'http_req_duration{name:Teacher:MaterialList}': ['p(95)<500'],
  'http_req_duration{name:Student:MaterialList}': ['p(95)<500'],
  'http_req_duration{name:Teacher:MaterialDetail}': ['p(95)<500'],
  'http_req_duration{name:Student:MaterialDetail}': ['p(95)<500'],
  'http_req_duration{name:Student:AssessmentResults}': ['p(95)<500'],
  
  // Slow endpoints (< 1500ms p95)
  'http_req_duration{name:Teacher:AllGradeData}': ['p(95)<1500'],
  'http_req_duration{name:Teacher:SF9}': ['p(95)<1500'],
  'http_req_duration{name:Teacher:SF10}': ['p(95)<1500'],
  
  // Sync endpoints (critical - can be heavy)
  'http_req_duration{name:Sync:Full}': ['p(95)<3000'],
  'http_req_duration{name:Sync:Delta}': ['p(95)<1500'],
  
  // File downloads (variable, high timeout)
  'http_req_duration{name:Shared:SubmissionDownload}': ['p(95)<2000'],
  'http_req_duration{name:Shared:MaterialDownload}': ['p(95)<2000'],
};

export const options: Options = buildOptions(stages, {
  http_req_duration: ['p(95)<2000'],
  http_req_failed: ['rate<0.05'],
  checks: ['rate>0.90'],
}, endpointThresholds);

export const handleSummary = createReportGenerator('get-all-endpoints').handleSummary;

const TEACHER_VUS = 100;  // 50% teachers
const STUDENT_VUS = 100;  // 50% students

export function setup(): MixedSetupData {
  console.log(`Setup: logging in ${TEACHER_VUS} teachers + ${STUDENT_VUS} students...`);
  const teacherTokens = loginAll(teacherAccounts, TEACHER_VUS);
  const studentTokens = loginAll(studentAccounts, STUDENT_VUS);
  console.log(`Setup complete: ${Object.keys(teacherTokens).length} teachers + ${Object.keys(studentTokens).length} students ready`);
  return { teacherTokens, studentTokens };
}

export default function (data: MixedSetupData): void {
  runAllEndpoints(data, { includeHeavyEndpoints: true, teacherVus: TEACHER_VUS });
}
