import http from 'k6/http';
import { check } from 'k6';

export function login(baseUrl, username, password) {
  const payload = {
    username: username,
    password: password,
  };

  const response = http.post(`${baseUrl}/api/v1/auth/login`, JSON.stringify(payload), {
    headers: {
      'Content-Type': 'application/json',
    },
    timeout: '5s',
  });

  let token = '';
  try {
    const result = response.json();
    token = result.token || result.access_token || '';
  } catch (e) {
    console.error(`Login failed for ${username}: ${response.status}`);
  }

  check(response, {
    'login: status 200': (r) => r.status === 200,
    'login: has token': () => token.length > 0,
  });

  return token;
}

export function loginWithAccount(baseUrl, account) {
  return login(baseUrl, account.username, account.password);
}

export function getAuthHeaders(token) {
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}

export function validateToken(baseUrl, token) {
  const response = http.get(`${baseUrl}/api/v1/classes`, {
    headers: getAuthHeaders(token),
    timeout: '3s',
  });

  return response.status === 200;
}
