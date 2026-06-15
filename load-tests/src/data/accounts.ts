import { Account } from '../types/scenario';

export const ADMIN_PASSWORD = 'admin123';
export const TEACHER_PASSWORD = 'teacher123';
export const STUDENT_PASSWORD = 'student123';

export const teacherAccounts: Account[] = Array.from({ length: 5 }, (_, i) => ({
  username: `teacher_${String(i + 1).padStart(2, '0')}`,
  password: TEACHER_PASSWORD,
  role: 'teacher' as const,
  fullName: `Teacher ${['One', 'Two', 'Three', 'Four', 'Five'][i]}`,
}));

export const studentAccounts: Account[] = Array.from({ length: 70 }, (_, i) => ({
  username: `student_${String(i + 1).padStart(2, '0')}`,
  password: STUDENT_PASSWORD,
  role: 'student' as const,
  fullName: `Student ${i + 1}`,
}));

export const adminAccounts: Account[] = [
  {
    username: 'admin',
    password: ADMIN_PASSWORD,
    role: 'admin' as const,
    fullName: 'System Administrator',
  },
];

export const allAccounts: Account[] = [...adminAccounts, ...teacherAccounts, ...studentAccounts];

export function getAccountByVU(pool: Account[], vuId: number): Account {
  return pool[(vuId - 1) % pool.length];
}
