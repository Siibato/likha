import { sleep } from 'k6';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginPool } from '../core/auth-manager';
import { ApiClient } from '../core/api-client';
import { AssessmentService } from '../services/assessment';
import { GradingService } from '../services/grading';
import { expectAll, expectStatus2xx } from '../core/check-helpers';
import { stages } from '../config/stages';
import { thresholds } from '../config/thresholds';
import { teacherAccounts } from '../data/accounts';
import { publishedAssessments, activeClasses, randomItem } from '../data/manifest';
import { TokenMap } from '../types/scenario';

// Simulates 5 teachers concurrently grading submissions and computing period grades.
// Tests write-heavy, CPU-bound operations: grade-essay, compute grades.
const TEACHER_VU_COUNT = 5;

export const options: Options = buildOptions(
  stages.gradualRamp(TEACHER_VU_COUNT),
  thresholds.normal,
);

export function setup(): TokenMap {
  console.log('Teacher grading setup: logging in teachers...');
  const tokens = loginPool(teacherAccounts);
  console.log(`Setup complete: ${Object.keys(tokens).length} teachers ready`);
  return tokens;
}

declare const __VU: number;

export default function (tokens: TokenMap): void {
  const token = tokens[__VU];
  if (!token) {
    console.error(`No token for VU ${__VU}`);
    return;
  }

  const client = new ApiClient(token);
  const assessmentService = new AssessmentService(client);
  const gradingService = new GradingService(client);

  // Step 1: Pick an assessment and get its submissions
  if (publishedAssessments.length > 0) {
    const assessment = randomItem(publishedAssessments);

    const subsRes = assessmentService.getSubmissions(assessment.id);
    expectAll(subsRes, 'grading-get-submissions', { status: 200, underMs: 500 });
    sleep(0.5);

    // Step 2: Get assessment stats
    const statsRes = assessmentService.getStatistics(assessment.id);
    expectStatus2xx(statsRes, 'grading-stats');
    sleep(0.5);
  }

  // Step 3: Trigger grade computation for a class
  if (activeClasses.length > 0) {
    const cls = randomItem(activeClasses);

    const configRes = gradingService.getConfig(cls.id);
    expectStatus2xx(configRes, 'grading-config');
    sleep(0.3);

    const itemsRes = gradingService.getGradeItems(cls.id);
    expectStatus2xx(itemsRes, 'grading-items');
    sleep(0.3);

    const computeRes = gradingService.compute(cls.id);
    expectAll(computeRes, 'grading-compute', { status: 200, underMs: 2000 });
    sleep(1);

    const gradesRes = gradingService.getGrades(cls.id);
    expectAll(gradesRes, 'grading-get-grades', { status: 200, underMs: 500 });
  }

  sleep(2);
}
