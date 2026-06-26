import { sleep } from 'k6';
import { createReportGenerator } from '../core/report-generator';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginAll } from '../core/auth-manager';
import { buildRoleMap } from '../core/role-map';
import { endpointThresholds } from '../config/thresholds';
import { teacherAccounts, studentAccounts, adminAccounts } from '../data/accounts';
import { MixedSetupData } from '../types/scenario';
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
import { AdminService } from '../services/admin';
import { expectAll, expectNoServerError } from '../core/check-helpers';
import {
  activeClasses,
  publishedAssessments,
  publishedAssignments,
  manifest,
  randomItem,
  students,
} from '../data/manifest';
import {
  fakeGradeScorePush,
  fakeAssessmentSubmissionServerPush,
  fakeAssignmentSubmissionServerPush,
  ServerPushPayload,
} from '../data/fixtures';

// Realistic 150-user steady-state load test
// Traffic distribution: 85% GET reads, 10% delta sync, 4% push sync, 1% full sync
// Role distribution: ~70% students, ~25% teachers, ~5% admin

const TOTAL_VUS = 150;
const TEACHER_VUS = 38;
const STUDENT_VUS = 105;
const ADMIN_VUS = 7;

const stages = [
  { duration: '30s', target: 50 },
  { duration: '1m', target: 100 },
  { duration: '3m', target: TOTAL_VUS },
  { duration: '2m', target: TOTAL_VUS },
  { duration: '30s', target: 0 },
];

export const options: Options = buildOptions(stages, {
  http_req_duration: ['p(95)<2000'],
  http_req_failed: ['rate<0.05'],
  checks: ['rate>0.90'],
}, endpointThresholds);

export const handleSummary = createReportGenerator('realistic-150').handleSummary;

export function setup(): MixedSetupData {
  console.log(`Setup: logging in ${ADMIN_VUS} admins + ${TEACHER_VUS} teachers + ${STUDENT_VUS} students...`);
  const adminTokens = loginAll(adminAccounts, ADMIN_VUS);
  const teacherTokens = loginAll(teacherAccounts, TEACHER_VUS);
  const studentTokens = loginAll(studentAccounts, STUDENT_VUS);
  console.log(`Setup complete: ${Object.keys(adminTokens).length} admins + ${Object.keys(teacherTokens).length} teachers + ${Object.keys(studentTokens).length} students ready`);
  const { roleMap, vuTokens } = buildRoleMap(TEACHER_VUS, STUDENT_VUS, ADMIN_VUS, teacherTokens, studentTokens, adminTokens);
  return { adminTokens, teacherTokens, studentTokens, roleMap, vuTokens };
}

declare const __VU: number;
declare const __ITER: number;

const fullSyncDone: Record<number, boolean> = {};

export default function (data: MixedSetupData): void {
  const role = data.roleMap?.[__VU];
  const token = data.vuTokens?.[__VU];
  if (!role || !token) return;

  const client = new ApiClient(token);

  const healthSvc = new HealthService(client);
  const authSvc = new AuthService(client);
  const classSvc = new ClassService(client);
  const assessmentSvc = new AssessmentService(client);
  const assignmentSvc = new AssignmentService(client);
  const gradingSvc = new GradingService(client);
  const materialSvc = new MaterialService(client);
  const tosSvc = new TosService(client);
  const adminSvc = new AdminService(client);
  const syncSvc = new SyncService(client);

  const classId = randomItem(activeClasses).id;
  const assessment = publishedAssessments.length > 0 ? randomItem(publishedAssessments) : null;
  const assignment = publishedAssignments.length > 0 ? randomItem(publishedAssignments) : null;
  const deviceId = `vu_${__VU}`;

  // First iteration: full sync (simulates first login)
  if (!fullSyncDone[__VU]) {
    fullSyncDone[__VU] = true;
    const classIds = activeClasses.map((c) => c.id);
    const fullRes = syncSvc.fullSync(deviceId, classIds);
    expectAll(fullRes, 'sync-full', { status: 200, underMs: 3000 });
    expectNoServerError(fullRes, 'sync-full');
    sleep(1 + Math.random() * 2);
    return;
  }

  const action = Math.random();

  if (action < 0.85) {
    // ===== GET READS (85%) — user navigating the app =====
    runReads(role, healthSvc, authSvc, classSvc, assessmentSvc, assignmentSvc, gradingSvc, materialSvc, tosSvc, adminSvc, classId, assessment, assignment);
  } else if (action < 0.95) {
    // ===== DELTA SYNC (10%) — app restart / reconnect =====
    const minutesAgo = Math.floor(Math.random() * 30) + 1;
    const lastSyncAt = new Date(Date.now() - minutesAgo * 60 * 1000).toISOString();
    const deltaRes = syncSvc.deltaSync({ device_id: deviceId, last_sync_at: lastSyncAt });
    expectAll(deltaRes, 'sync-delta', { status: 200, underMs: 1500 });
    expectNoServerError(deltaRes, 'sync-delta');
  } else if (action < 0.99) {
    // ===== PUSH SYNC (4%) — user writes data =====
    runPushSync(role, syncSvc, classId, assessment, assignment);
  } else {
    // ===== FULL SYNC (1%) — rare: data expiry or re-login =====
    const classIds = activeClasses.map((c) => c.id);
    const fullRes = syncSvc.fullSync(deviceId, classIds);
    expectAll(fullRes, 'sync-full', { status: 200, underMs: 3000 });
    expectNoServerError(fullRes, 'sync-full');
  }

  // Think time: 2-5 seconds with jitter
  sleep(2 + Math.random() * 3);
}

function runReads(
  role: string,
  healthSvc: HealthService,
  authSvc: AuthService,
  classSvc: ClassService,
  assessmentSvc: AssessmentService,
  assignmentSvc: AssignmentService,
  gradingSvc: GradingService,
  materialSvc: MaterialService,
  tosSvc: TosService,
  adminSvc: AdminService,
  classId: string,
  assessment: { id: string } | null,
  assignment: { id: string } | null,
): void {
  // Lightweight shared endpoints (all roles)
  const healthRes = healthSvc.health();
  expectAll(healthRes, 'health-check', { status: 200, underMs: 200 });

  const authRes = authSvc.me();
  expectAll(authRes, 'auth-me', { status: 200, underMs: 200 });

  if (role === 'Teacher') {
    const classRes = classSvc.list('Teacher');
    expectAll(classRes, 'teacher-classes', { status: 200, underMs: 500 });

    const classDetailRes = classSvc.detail(classId, 'Teacher');
    expectAll(classDetailRes, 'teacher-class-detail', { status: 200, underMs: 500 });

    const assessRes = assessmentSvc.list(classId, 'Teacher');
    expectAll(assessRes, 'teacher-assessments', { status: 200, underMs: 500 });

    if (assessment) {
      const assessDetailRes = assessmentSvc.detail(assessment.id, 'Teacher');
      expectAll(assessDetailRes, 'teacher-assessment-detail', { status: 200, underMs: 500 });

      const statsRes = assessmentSvc.getStatistics(assessment.id);
      expectAll(statsRes, 'teacher-assessment-stats', { status: 200, underMs: 500 });
    }

    const assignRes = assignmentSvc.list(classId, 'Teacher');
    expectAll(assignRes, 'teacher-assignments', { status: 200, underMs: 500 });

    const gradeConfigRes = gradingSvc.getConfig(classId);
    expectAll(gradeConfigRes, 'teacher-grading-config', { status: 200, underMs: 300 });

    const gradeItemsRes = gradingSvc.getGradeItems(classId);
    expectAll(gradeItemsRes, 'teacher-grade-items', { status: 200, underMs: 500 });

    const gradesRes = gradingSvc.getGrades(classId);
    expectAll(gradesRes, 'teacher-grades', { status: 200, underMs: 500 });

    const gradeSummaryRes = gradingSvc.getGradeSummary(classId);
    expectAll(gradeSummaryRes, 'teacher-grade-summary', { status: 200, underMs: 500 });

    const materialsRes = materialSvc.list(classId, 'Teacher');
    expectAll(materialsRes, 'teacher-materials', { status: 200, underMs: 500 });
  } else if (role === 'Student') {
    const classRes = classSvc.list('Student');
    expectAll(classRes, 'student-classes', { status: 200, underMs: 500 });

    const classDetailRes = classSvc.detail(classId, 'Student');
    expectAll(classDetailRes, 'student-class-detail', { status: 200, underMs: 500 });

    const studentAssignRes = assignmentSvc.studentList();
    expectAll(studentAssignRes, 'student-assignments', { status: 200, underMs: 500 });

    if (assignment) {
      const assignDetailRes = assignmentSvc.detail(assignment.id, 'Student');
      expectAll(assignDetailRes, 'student-assignment-detail', { status: 200, underMs: 500 });
    }

    const myGradesRes = gradingSvc.getMyGrades(classId);
    expectAll(myGradesRes, 'student-my-grades', { status: 200, underMs: 500 });

    const myTermGradesRes = gradingSvc.getMyTermGrades(classId, '1');
    expectAll(myTermGradesRes, 'student-my-term-grades', { status: 200, underMs: 500 });

    const materialsRes = materialSvc.list(classId, 'Student');
    expectAll(materialsRes, 'student-materials', { status: 200, underMs: 500 });

    if (assessment) {
      const assessDetailRes = assessmentSvc.detail(assessment.id, 'Student');
      expectAll(assessDetailRes, 'student-assessment-detail', { status: 200, underMs: 500 });
    }
  } else if (role === 'Admin') {
    const accountsRes = adminSvc.listAccounts();
    expectAll(accountsRes, 'admin-account-list', { status: 200, underMs: 500 });

    const randomUser = randomItem(manifest.users);
    const accountRes = adminSvc.getAccount(randomUser.id);
    expectAll(accountRes, 'admin-account-detail', { status: 200, underMs: 300 });

    const settingsRes = adminSvc.getSchoolSettings();
    expectAll(settingsRes, 'admin-school-settings', { status: 200, underMs: 200 });
  }
}

function runPushSync(
  role: string,
  syncSvc: SyncService,
  classId: string,
  assessment: { id: string } | null,
  assignment: { id: string } | null,
): void {
  let payload: ServerPushPayload | null = null;

  if (role === 'Teacher') {
    // Teacher: push grade score update
    const student = randomItem(students);
    payload = fakeGradeScorePush(classId, student.id);
  } else if (role === 'Student') {
    // Student: push assessment or assignment submission
    if (assessment && Math.random() < 0.5) {
      const student = randomItem(students);
      payload = fakeAssessmentSubmissionServerPush(assessment.id, student.id);
    } else if (assignment) {
      const student = randomItem(students);
      payload = fakeAssignmentSubmissionServerPush(assignment.id, student.id);
    }
  }

  if (payload) {
    const pushRes = syncSvc.push(payload as any);
    expectAll(pushRes, 'sync-push', { status: 200, underMs: 1000 });
    expectNoServerError(pushRes, 'sync-push');
  }
}
