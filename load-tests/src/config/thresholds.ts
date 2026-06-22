import { Options } from 'k6/options';

type Thresholds = NonNullable<Options['thresholds']>;

export const thresholds = {
  strict: {
    http_req_duration: ['p(95)<200'],
    http_req_failed: ['rate<0.01'],
    checks: ['rate>0.99'],
  } satisfies Thresholds,

  normal: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.02'],
    checks: ['rate>0.95'],
  } satisfies Thresholds,

  stress: {
    http_req_duration: ['p(95)<1000'],
    http_req_failed: ['rate<0.05'],
    checks: ['rate>0.90'],
  } satisfies Thresholds,

  sync: {
    http_req_duration: ['p(95)<800'],
    http_req_failed: ['rate<0.02'],
    checks: ['rate>0.95'],
  } satisfies Thresholds,
} as const;

export const endpointThresholds = {
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
  'http_req_duration{name:Student:MyTermGrades}': ['p(95)<500'],
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

  // Admin endpoints
  'http_req_duration{name:Admin:AccountList}': ['p(95)<500'],
  'http_req_duration{name:Admin:AccountDetail}': ['p(95)<300'],
  'http_req_duration{name:Admin:ActivityLogs}': ['p(95)<400'],
  'http_req_duration{name:Admin:SetupQr}': ['p(95)<300'],
  'http_req_duration{name:Admin:SetupCode}': ['p(95)<200'],
  'http_req_duration{name:Admin:SchoolSettings}': ['p(95)<200'],
  'http_req_duration{name:Admin:StudentSearch}': ['p(95)<400'],

  // File downloads (variable, high timeout)
  'http_req_duration{name:Shared:SubmissionDownload}': ['p(95)<2000'],
  'http_req_duration{name:Shared:MaterialDownload}': ['p(95)<2000'],
} satisfies Thresholds;
