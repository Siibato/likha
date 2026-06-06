import { sleep } from 'k6';
import { Options } from 'k6/options';
import { buildOptions } from '../core/scenario-builder';
import { loginPool } from '../core/auth-manager';
import { ApiClient } from '../core/api-client';
import { AssessmentService } from '../services/assessment';
import { expectAll, expectStatus2xx, expectNoServerError } from '../core/check-helpers';
import { stages } from '../config/stages';
import { thresholds } from '../config/thresholds';
import { studentAccounts } from '../data/accounts';
import { fakeAnswerSave } from '../data/fixtures';
import { publishedAssessments, randomItem } from '../data/manifest';
import { TokenMap } from '../types/scenario';

// Simulates all 70 students bursting into the same exam simultaneously,
// auto-saving answers every ~10s, then submitting at the end.
export const options: Options = buildOptions(stages.examSurge, thresholds.normal);

// Pick one published assessment to storm. All VUs use this same assessment.
const TARGET_ASSESSMENT = publishedAssessments.length > 0 ? publishedAssessments[0] : null;

export function setup(): TokenMap {
  if (!TARGET_ASSESSMENT) {
    throw new Error('No published assessments found in manifest. Run seed-manual --export-manifest first.');
  }
  console.log(`Exam surge setup: targeting assessment "${TARGET_ASSESSMENT.title}" (${TARGET_ASSESSMENT.id})`);
  const tokens = loginPool(studentAccounts);
  console.log(`Setup complete: ${Object.keys(tokens).length} students ready`);
  return tokens;
}

declare const __VU: number;
declare const __ITER: number;

export default function (tokens: TokenMap): void {
  if (!TARGET_ASSESSMENT) return;

  const token = tokens[__VU];
  if (!token) {
    console.error(`No token for VU ${__VU}`);
    return;
  }

  const client = new ApiClient(token);
  const assessmentService = new AssessmentService(client);

  // Step 1: Start the assessment (burst)
  const startRes = assessmentService.start(TARGET_ASSESSMENT.id);
  const startOk = expectAll(startRes, 'exam-start', { status: 200, underMs: 500 });
  if (!startOk) {
    console.warn(`VU ${__VU} failed to start assessment, iter ${__ITER}`);
    return;
  }

  const submissionId = (startRes.json() as Record<string, unknown>)?.id as string;
  if (!submissionId) {
    console.warn(`VU ${__VU}: no submission id returned`);
    return;
  }

  // Step 2: Auto-save answers (simulates periodic saves during exam)
  for (let save = 0; save < 3; save++) {
    sleep(10);
    const questionIds = TARGET_ASSESSMENT.question_ids.length > 0
      ? TARGET_ASSESSMENT.question_ids
      : ['q_placeholder'];
    const saveRes = assessmentService.saveAnswers(submissionId, fakeAnswerSave(questionIds));
    expectStatus2xx(saveRes, 'exam-save-answers');
  }

  // Step 3: Submit
  sleep(2);
  const submitRes = assessmentService.submit(submissionId);
  expectAll(submitRes, 'exam-submit', { status: 200, underMs: 1000 });
  expectNoServerError(submitRes, 'exam-submit');

  sleep(1);
}
