import http from 'k6/http';
import { check, sleep } from 'k6';
import { syncFlowOptions, getAuthHeaders } from '../config/options.js';
import { loginWithAccount } from '../lib/auth.js';
import { getAccountByVU, studentAccounts } from '../lib/accounts.js';

export const options = syncFlowOptions;

const BASE_URL = __ENV.BASE_URL || 'http://192.168.x.x:8000';

export function setup() {
  console.log('Setup phase: Logging in student accounts...');
  const tokens = {};

  for (let i = 1; i <= 100; i++) {
    const account = getAccountByVU(studentAccounts, i);
    const token = loginWithAccount(BASE_URL, account);

    if (token) {
      tokens[i] = token;
      if (i % 25 === 0) console.log(`✓ Logged in ${i} users`);
    } else {
      console.error(`✗ VU ${i} login failed - check account ${account.username} exists`);
    }
  }

  console.log(`Setup complete: ${Object.keys(tokens).length} users ready`);
  return tokens;
}

export default function (tokens) {
  const token = tokens[__VU];

  if (!token) {
    console.error(`No token for VU ${__VU}`);
    return;
  }

  const headers = getAuthHeaders(token);

  const classRes = http.get(`${BASE_URL}/api/v1/classes`, { headers });
  check(classRes, {
    'step1-classes: status 200': (r) => r.status === 200,
    'step1-classes: response < 200ms': (r) => r.timings.duration < 200,
  });

  sleep(0.5);

  const syncFullRes = http.get(`${BASE_URL}/api/v1/sync/full`, { headers });
  check(syncFullRes, {
    'step2-sync-full: status 200': (r) => r.status === 200,
    'step2-sync-full: response < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(0.5);

  const syncPayload = {
    operations: [
      {
        entity_type: 'assessment_submission',
        operation_type: 'create',
        entity_id: `submission_${Date.now()}_${__VU}`,
        data: {
          assessment_id: '1',
          student_id: '1',
          submitted_at: new Date().toISOString(),
          answers: { question_1: 'test answer' },
        },
      },
    ],
  };

  const syncPushRes = http.post(`${BASE_URL}/api/v1/sync/push`, JSON.stringify(syncPayload), {
    headers,
    timeout: '5s',
  });

  check(syncPushRes, {
    'step3-sync-push: status 200/201': (r) => r.status === 200 || r.status === 201,
    'step3-sync-push: response < 500ms': (r) => r.timings.duration < 500,
    'step3-sync-push: no server error': (r) => r.status < 500,
  });

  sleep(1);
}
