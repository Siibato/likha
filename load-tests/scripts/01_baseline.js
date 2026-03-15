import http from 'k6/http';
import { check, sleep } from 'k6';
import { baselineOptions, getAuthHeaders } from '../config/options.js';
import { loginWithAccount } from '../lib/auth.js';
import { getAccountByVU, teacherAccounts } from '../lib/accounts.js';

export const options = baselineOptions;

const BASE_URL = __ENV.BASE_URL || 'http://192.168.x.x:8000';

export function setup() {
  console.log('Setup phase: Logging in all users...');
  const tokens = {};

  for (let i = 1; i <= 50; i++) {
    const account = getAccountByVU(teacherAccounts, i);
    const token = loginWithAccount(BASE_URL, account);

    if (token) {
      tokens[i] = token;
      console.log(`✓ VU ${i} (${account.username}) logged in`);
    } else {
      console.error(`✗ VU ${i} (${account.username}) login failed - check account exists`);
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
    'classes: status 200': (r) => r.status === 200,
    'classes: response < 200ms': (r) => r.timings.duration < 200,
  });

  sleep(0.5);

  const assessRes = http.get(`${BASE_URL}/api/v1/assessments`, { headers });
  check(assessRes, {
    'assessments: status 200': (r) => r.status === 200,
    'assessments: response < 200ms': (r) => r.timings.duration < 200,
  });

  sleep(0.5);

  const assignRes = http.get(`${BASE_URL}/api/v1/assignments`, { headers });
  check(assignRes, {
    'assignments: status 200': (r) => r.status === 200,
    'assignments: response < 200ms': (r) => r.timings.duration < 200,
  });

  sleep(1);
}
