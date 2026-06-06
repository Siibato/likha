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
  role: 'teacher' | 'student';
}

export interface BaseSetupData {
  tokens: TokenMap;
}

export interface MixedSetupData {
  teacherTokens: TokenMap;
  studentTokens: TokenMap;
}
