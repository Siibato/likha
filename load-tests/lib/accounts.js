export const TEST_PASSWORD = 'TestPassword123!';

export const adminAccounts = [
  { username: 'admin01', password: TEST_PASSWORD, fullName: 'Admin User One' },
  { username: 'admin02', password: TEST_PASSWORD, fullName: 'Admin User Two' },
  { username: 'admin03', password: TEST_PASSWORD, fullName: 'Admin User Three' },
];

export const teacherAccounts = [
  { username: 'teacher01', password: TEST_PASSWORD, fullName: 'Teacher One' },
  { username: 'teacher02', password: TEST_PASSWORD, fullName: 'Teacher Two' },
  { username: 'teacher03', password: TEST_PASSWORD, fullName: 'Teacher Three' },
  { username: 'teacher04', password: TEST_PASSWORD, fullName: 'Teacher Four' },
  { username: 'teacher05', password: TEST_PASSWORD, fullName: 'Teacher Five' },
];

export const studentAccounts = [
  { username: 'student01', password: TEST_PASSWORD, fullName: 'Student One' },
  { username: 'student02', password: TEST_PASSWORD, fullName: 'Student Two' },
  { username: 'student03', password: TEST_PASSWORD, fullName: 'Student Three' },
  { username: 'student04', password: TEST_PASSWORD, fullName: 'Student Four' },
  { username: 'student05', password: TEST_PASSWORD, fullName: 'Student Five' },
  { username: 'student06', password: TEST_PASSWORD, fullName: 'Student Six' },
  { username: 'student07', password: TEST_PASSWORD, fullName: 'Student Seven' },
  { username: 'student08', password: TEST_PASSWORD, fullName: 'Student Eight' },
  { username: 'student09', password: TEST_PASSWORD, fullName: 'Student Nine' },
  { username: 'student10', password: TEST_PASSWORD, fullName: 'Student Ten' },
];

export function getRandomAccount(accountPool) {
  const randomIndex = Math.floor(Math.random() * accountPool.length);
  return accountPool[randomIndex];
}

export function getAccountByVU(accountPool, vuId) {
  return accountPool[(vuId - 1) % accountPool.length];
}

export const allAccounts = [...adminAccounts, ...teacherAccounts, ...studentAccounts];
