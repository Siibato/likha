import { sleep } from 'k6';
import { createReportGenerator } from '../core/report-generator';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginPool } from '../core/auth-manager';
import { ApiClient } from '../core/api-client';
import { ClassService } from '../services/class';
import { AssessmentService } from '../services/assessment';
import { AssignmentService } from '../services/assignment';
import { SyncService } from '../services/sync';
import { GradingService } from '../services/grading';
import { expectAll, expectStatus2xx } from '../core/check-helpers';
import { stages } from '../config/stages';
import { thresholds } from '../config/thresholds';
import { teacherAccounts, studentAccounts, adminAccounts } from '../data/accounts';
import { fakeAssessmentSubmissionPush } from '../data/fixtures';
import { manifest, publishedAssessments, activeClasses, randomItem } from '../data/manifest';
import { MixedSetupData } from '../types/scenario';

const TEACHER_VU_COUNT = 5;
const STUDENT_VU_COUNT = 70;
const TOTAL_VU_COUNT = TEACHER_VU_COUNT + STUDENT_VU_COUNT;

export const options: Options = {
  ...buildOptions(stages.gradualRamp(TOTAL_VU_COUNT), thresholds.normal),
};

export const handleSummary = createReportGenerator('classroom-mix').handleSummary;

export function setup(): MixedSetupData {
  console.log('Classroom-mix setup: logging in teachers and students...');
  const adminTokens = loginPool(adminAccounts);
  const teacherTokens = loginPool(teacherAccounts);
  const studentTokens = loginPool(studentAccounts);
  console.log(`Setup complete: ${teacherAccounts.length} teachers + ${studentAccounts.length} students`);
  return { adminTokens, teacherTokens, studentTokens };
}

declare const __VU: number;

export default function (data: MixedSetupData): void {
  const isTeacher = __VU <= TEACHER_VU_COUNT;

  if (isTeacher) {
    const token = data.teacherTokens[__VU];
    if (!token) return;
    runTeacherFlow(token);
  } else {
    const studentVuIndex = __VU - TEACHER_VU_COUNT;
    const token = data.studentTokens[studentVuIndex];
    if (!token) return;
    runStudentFlow(token);
  }
}

function runTeacherFlow(token: string): void {
  const client = new ApiClient(token);
  const classService = new ClassService(client);
  const assessmentService = new AssessmentService(client);
  const gradingService = new GradingService(client);

  const classRes = classService.list();
  expectAll(classRes, 'teacher-class-list', { status: 200, underMs: 300 });
  sleep(0.5);

  if (activeClasses.length > 0) {
    const cls = randomItem(activeClasses);
    const assessRes = assessmentService.list(cls.id);
    expectAll(assessRes, 'teacher-assessment-list', { status: 200, underMs: 300 });
    sleep(0.5);

    const gradesRes = gradingService.getGradeSummary(cls.id);
    expectStatus2xx(gradesRes, 'teacher-grade-summary');
  }

  sleep(2);
}

function runStudentFlow(token: string): void {
  const client = new ApiClient(token);
  const syncService = new SyncService(client);
  const classService = new ClassService(client);
  const assignmentService = new AssignmentService(client);

  const syncRes = syncService.fullSync();
  expectAll(syncRes, 'student-full-sync', { status: 200, underMs: 1000 });
  sleep(1);

  const classRes = classService.list();
  expectAll(classRes, 'student-class-list', { status: 200, underMs: 300 });
  sleep(0.5);

  const assignRes = assignmentService.studentList();
  expectAll(assignRes, 'student-assignment-list', { status: 200, underMs: 300 });
  sleep(0.5);

  if (publishedAssessments.length > 0) {
    const assessment = randomItem(publishedAssessments);
    const studentId = randomItem(manifest.users.filter(u => u.role === 'student')).id;
    const pushPayload = fakeAssessmentSubmissionPush(assessment.id, studentId);
    const pushRes = syncService.push(pushPayload);
    expectStatus2xx(pushRes, 'student-sync-push');
  }

  sleep(1);
}
