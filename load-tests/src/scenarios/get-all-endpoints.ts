import { sleep } from 'k6';
import { createReportGenerator } from '../core/report-generator';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginAll } from '../core/auth-manager';
import { ApiClient } from '../core/api-client';
import { ClassService } from '../services/class';
import { AssessmentService } from '../services/assessment';
import { AssignmentService } from '../services/assignment';
import { GradingService } from '../services/grading';
import { MaterialService } from '../services/material';
import { TosService } from '../services/tos';
import { SyncService } from '../services/sync';
import { HealthService } from '../services/health';
import { AuthService } from '../services/auth';
import { expectAll, expectStatus2xx } from '../core/check-helpers';
import { teacherAccounts, studentAccounts } from '../data/accounts';
import { activeClasses, publishedAssessments, publishedAssignments, manifest, randomItem } from '../data/manifest';
import { MixedSetupData } from '../types/scenario';

// ===== 3.5-MINUTE INTENSE STAGES =====
// Total: 3m30s load + overhead = ~5 minutes total
const stages = [
  { duration: '15s', target: 10 },   // Warm-up
  { duration: '1m', target: 50 },   // Moderate
  { duration: '1m', target: 100 },  // Heavy
  { duration: '1m', target: 200 },  // Stress (bottleneck detection)
  { duration: '15s', target: 0 },   // Cool-down
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

declare const __VU: number;

export default function (data: MixedSetupData): void {
  // Determine VU type (first 100 = teacher, last 100 = student)
  const isTeacher = __VU <= TEACHER_VUS;
  const token = isTeacher ? data.teacherTokens[__VU] : data.studentTokens[__VU - TEACHER_VUS];
  const role: 'Teacher' | 'Student' = isTeacher ? 'Teacher' : 'Student';
  
  if (!token) {
    console.error(`No token for VU ${__VU}`);
    return;
  }

  const client = new ApiClient(token);
  
  // Initialize all services
  const healthSvc = new HealthService(client);
  const authSvc = new AuthService(client);
  const classSvc = new ClassService(client);
  const assessmentSvc = new AssessmentService(client);
  const assignmentSvc = new AssignmentService(client);
  const gradingSvc = new GradingService(client);
  const materialSvc = new MaterialService(client);
  const tosSvc = new TosService(client);
  const syncSvc = new SyncService(client);

  // Get random class/assessment/assignment for detail calls
  const classId = randomItem(activeClasses).id;
  const assessment = publishedAssessments.length > 0 ? randomItem(publishedAssessments) : null;
  const assignment = publishedAssignments.length > 0 ? randomItem(publishedAssignments) : null;
  
  // ===== 1. HEALTH & SHARED ENDPOINTS (All VUs) =====
  const healthRes = healthSvc.health();
  expectAll(healthRes, 'health-check', { status: 200, underMs: 100 });
  
  const readyRes = healthSvc.ready();
  expectAll(readyRes, 'health-ready', { status: 200, underMs: 100 });
  
  const dbIdRes = healthSvc.databaseId();
  expectAll(dbIdRes, 'database-id', { status: 200, underMs: 100 });
  
  const authRes = authSvc.me();
  expectAll(authRes, 'auth-me', { status: 200, underMs: 100 });
  
  // Shared metadata endpoints
  const classMetaRes = classSvc.metadata();
  expectAll(classMetaRes, 'class-metadata', { status: 200, underMs: 150 });
  
  const assessMetaRes = assessmentSvc.metadata();
  expectAll(assessMetaRes, 'assessment-metadata', { status: 200, underMs: 150 });
  
  // ===== 2. ROLE-SPECIFIC WORKFLOW =====
  if (role === 'Teacher') {
    // Teacher workflow - intensive endpoint coverage
    
    // Class endpoints
    const classRes = classSvc.list(role);
    expectAll(classRes, 'teacher-classes', { status: 200, underMs: 400 });
    
    const classDetailRes = classSvc.detail(classId, role);
    expectAll(classDetailRes, 'teacher-class-detail', { status: 200, underMs: 400 });
    
    // Assessment endpoints
    const assessRes = assessmentSvc.list(classId, role);
    expectAll(assessRes, 'teacher-assessments', { status: 200, underMs: 400 });
    
    if (assessment) {
      const assessDetailRes = assessmentSvc.detail(assessment.id, role);
      expectAll(assessDetailRes, 'teacher-assessment-detail', { status: 200, underMs: 400 });
      
      const submissionsRes = assessmentSvc.getSubmissions(assessment.id);
      // May 404 if no submissions exist
      if (submissionsRes.status === 200) {
        expectAll(submissionsRes, 'teacher-assessment-submissions', { status: 200, underMs: 500 });
      }
      
      const statsRes = assessmentSvc.getStatistics(assessment.id);
      expectAll(statsRes, 'teacher-assessment-stats', { status: 200, underMs: 500 });
    }
    
    // Assignment endpoints
    const assignRes = assignmentSvc.list(classId, role);
    expectAll(assignRes, 'teacher-assignments', { status: 200, underMs: 400 });
    
    if (assignment) {
      const assignDetailRes = assignmentSvc.detail(assignment.id, role);
      expectAll(assignDetailRes, 'teacher-assignment-detail', { status: 200, underMs: 400 });
      
      const assignSubsRes = assignmentSvc.getSubmissions(assignment.id);
      if (assignSubsRes.status === 200) {
        expectAll(assignSubsRes, 'teacher-assignment-submissions', { status: 200, underMs: 500 });
      }
    }
    
    // Grading workflow - most intensive
    const gradeConfigRes = gradingSvc.getConfig(classId);
    expectAll(gradeConfigRes, 'teacher-grading-config', { status: 200, underMs: 300 });
    
    const gradeItemsRes = gradingSvc.getGradeItems(classId);
    expectAll(gradeItemsRes, 'teacher-grade-items', { status: 200, underMs: 400 });
    
    const gradesRes = gradingSvc.getGrades(classId);
    expectAll(gradesRes, 'teacher-grades', { status: 200, underMs: 500 });
    
    const gradeSummaryRes = gradingSvc.getGradeSummary(classId);
    expectAll(gradeSummaryRes, 'teacher-grade-summary', { status: 200, underMs: 500 });
    
    const finalGradesRes = gradingSvc.getFinalGrades(classId);
    expectAll(finalGradesRes, 'teacher-final-grades', { status: 200, underMs: 600 });
    
    // DepEd presets
    const presetsRes = gradingSvc.getDepedPresets();
    expectAll(presetsRes, 'teacher-deped-presets', { status: 200, underMs: 300 });
    
    // General averages
    const genAvgRes = gradingSvc.getGeneralAverages(classId);
    if (genAvgRes.status === 200) {
      expectAll(genAvgRes, 'teacher-general-averages', { status: 200, underMs: 600 });
    }
    
    // TOS
    const tosRes = tosSvc.list(classId);
    if (tosRes.status === 200) {
      expectAll(tosRes, 'teacher-tos-list', { status: 200, underMs: 400 });
    }
    
    const melcsRes = tosSvc.searchMelcs('science');
    if (melcsRes.status === 200) {
      expectAll(melcsRes, 'teacher-melcs-search', { status: 200, underMs: 500 });
    }
    
    // Materials
    const materialsRes = materialSvc.list(classId, role);
    expectAll(materialsRes, 'teacher-materials', { status: 200, underMs: 400 });
    
    const materialMetaRes = materialSvc.metadata();
    expectAll(materialMetaRes, 'material-metadata', { status: 200, underMs: 150 });
    
    // Heavy endpoints (occasional - 30% chance to avoid overloading)
    if (Math.random() < 0.3) {
      const allGradeDataRes = gradingSvc.getGradeData(classId);
      if (allGradeDataRes.status === 200) {
        expectAll(allGradeDataRes, 'teacher-all-grade-data', { status: 200, underMs: 1500 });
      }
      
      // SF9/SF10 (only if we have students)
      const students = manifest.users.filter(u => u.role === 'student');
      if (students.length > 0) {
        const student = randomItem(students);
        
        const sf9Res = gradingSvc.getSf9(classId, student.id);
        if (sf9Res.status === 200) {
          expectAll(sf9Res, 'teacher-sf9', { status: 200, underMs: 1500 });
        }
        
        const sf10Res = gradingSvc.getSf10(classId, student.id);
        if (sf10Res.status === 200) {
          expectAll(sf10Res, 'teacher-sf10', { status: 200, underMs: 1500 });
        }
        
        // Item scores for a grade item
        const gradeItemsBody = typeof gradeItemsRes.body === 'string' ? gradeItemsRes.body : '[]';
        const gradeItems = JSON.parse(gradeItemsBody || '[]');
        if (Array.isArray(gradeItems) && gradeItems.length > 0) {
          const itemId = gradeItems[0].id;
          const itemScoresRes = gradingSvc.getItemScores(itemId);
          if (itemScoresRes.status === 200) {
            expectAll(itemScoresRes, 'teacher-item-scores', { status: 200, underMs: 500 });
          }
        }
      }
    }
  }
  
  if (role === 'Student') {
    // Student workflow
    
    // Class endpoints
    const classRes = classSvc.list(role);
    expectAll(classRes, 'student-classes', { status: 200, underMs: 400 });
    
    const classDetailRes = classSvc.detail(classId, role);
    expectAll(classDetailRes, 'student-class-detail', { status: 200, underMs: 400 });
    
    // Assignment endpoints
    const studentAssignRes = assignmentSvc.studentList();
    expectAll(studentAssignRes, 'student-assignments', { status: 200, underMs: 400 });
    
    if (assignment) {
      const assignDetailRes = assignmentSvc.detail(assignment.id, role);
      expectAll(assignDetailRes, 'student-assignment-detail', { status: 200, underMs: 400 });
    }
    
    // Grading endpoints
    const myGradesRes = gradingSvc.getMyGrades(classId);
    expectAll(myGradesRes, 'student-my-grades', { status: 200, underMs: 400 });
    
    const myQuarterGradesRes = gradingSvc.getMyQuarterGrades(classId, '1');
    expectAll(myQuarterGradesRes, 'student-my-quarter-grades', { status: 200, underMs: 400 });
    
    // Materials
    const materialsRes = materialSvc.list(classId, role);
    expectAll(materialsRes, 'student-materials', { status: 200, underMs: 400 });
    
    const materialMetaRes = materialSvc.metadata();
    expectAll(materialMetaRes, 'material-metadata', { status: 200, underMs: 150 });
    
    // Assessment results (if assessment exists and has submissions)
    if (assessment) {
      const assessDetailRes = assessmentSvc.detail(assessment.id, role);
      expectAll(assessDetailRes, 'student-assessment-detail', { status: 200, underMs: 400 });
      
      // Try to get results - may 404 if no submission
      const students = manifest.users.filter(u => u.role === 'student');
      if (students.length > 0) {
        const student = randomItem(students);
        const resultsRes = assessmentSvc.getStudentSubmissions(classId, student.id);
        if (resultsRes.status === 200) {
          expectAll(resultsRes, 'student-assessment-results', { status: 200, underMs: 500 });
        }
      }
    }
  }
  
  // ===== 3. SYNC PULL (critical bottleneck detection) =====
  // All roles do sync - this is where major bottlenecks occur
  
  // 60% do delta sync, 30% do full sync (to compare performance)
  const syncRand = Math.random();
  if (syncRand < 0.6) {
    // Delta sync with random time window (1 min to 24 hours ago)
    const minutesAgo = Math.floor(Math.random() * 1440) + 1;
    const lastSyncAt = new Date(Date.now() - minutesAgo * 60 * 1000).toISOString();
    const deltaRes = syncSvc.deltaSync({ last_sync_at: lastSyncAt });
    expectAll(deltaRes, 'sync-delta', { status: 200, underMs: 1000 });
  } else if (syncRand < 0.9) {
    // Full sync (the heavy one!)
    const fullRes = syncSvc.fullSync();
    expectAll(fullRes, 'sync-full', { status: 200, underMs: 2500 });
  }
  
  // Minimal sleep to maximize throughput
  sleep(0.1);
}
