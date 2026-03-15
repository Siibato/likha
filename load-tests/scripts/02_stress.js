import http from 'k6/http';
import { check, sleep } from 'k6';
import { stressOptions, getAuthHeaders } from '../config/options.js';
import { loginWithAccount } from '../lib/auth.js';
import { getAccountByVU, studentAccounts } from '../lib/accounts.js';

export const options = stressOptions;

const BASE_URL = __ENV.BASE_URL || 'http://192.168.x.x:8000';

export function setup() {
  console.log('Setup phase: Logging in student accounts...');
  const tokens = {};

  for (let i = 1; i <= 500; i++) {
    const account = getAccountByVU(studentAccounts, i);
    const token = loginWithAccount(BASE_URL, account);

    if (token) {
      tokens[i] = token;
      if (i % 50 === 0) console.log(`✓ Logged in ${i} users`);
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
  const rand = Math.random();

  if (rand < 0.4) {
    const syncRes = http.get(`${BASE_URL}/api/v1/sync/full`, {
      headers,
      timeout: '5s',
    });
    check(syncRes, {
      'sync: status 200': (r) => r.status === 200,
      'sync: response < 500ms': (r) => r.timings.duration < 500,
      'sync: no timeout': (r) => r.status !== 0,
    });
  } else if (rand < 0.7) {
    const classRes = http.get(`${BASE_URL}/api/v1/classes`, {
      headers,
      timeout: '5s',
    });
    check(classRes, {
      'classes: status 200': (r) => r.status === 200,
      'classes: response < 300ms': (r) => r.timings.duration < 300,
    });
  } else {
    const assessRes = http.get(`${BASE_URL}/api/v1/assessments`, {
      headers,
      timeout: '5s',
    });
    check(assessRes, {
      'assessments: status 200': (r) => r.status === 200,
      'assessments: response < 300ms': (r) => r.timings.duration < 300,
    });
  }

  sleep(1);
}
