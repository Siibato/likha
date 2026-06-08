export interface Account {
  username: string;
  password: string;
  role: 'admin' | 'teacher' | 'student';
  fullName: string;
}

export interface AccountPool {
  accounts: Account[];
  allocate(vuId: number): Account;
}

export type TokenMap = Record<number, string>;

export interface VUContext {
  token: string;
  vuId: number;
  role: 'admin' | 'teacher' | 'student';
}

export interface BaseSetupData {
  tokens: TokenMap;
}

export interface MixedSetupData {
  adminTokens: TokenMap;
  teacherTokens: TokenMap;
  studentTokens: TokenMap;
  roleMap?: Record<number, 'Teacher' | 'Student' | 'Admin'>;
  vuTokens?: TokenMap;
}
