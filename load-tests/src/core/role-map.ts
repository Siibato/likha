import { TokenMap } from '../types/scenario';

export function buildRoleMap(
  teacherVus: number,
  studentVus: number,
  adminVus: number,
  teacherTokens: TokenMap,
  studentTokens: TokenMap,
  adminTokens: TokenMap,
): {
  roleMap: Record<number, 'Teacher' | 'Student' | 'Admin'>;
  vuTokens: TokenMap;
} {
  const total = teacherVus + studentVus + adminVus;
  const roleMap: Record<number, 'Teacher' | 'Student' | 'Admin'> = {};
  const vuTokens: TokenMap = {};

  // Reserve first 3 VUs: teacher, student, admin
  roleMap[1] = 'Teacher';
  vuTokens[1] = teacherTokens[1];
  roleMap[2] = 'Student';
  vuTokens[2] = studentTokens[1];
  roleMap[3] = 'Admin';
  vuTokens[3] = adminTokens[1];

  let t = 1;
  let s = 1;
  let a = 1;

  for (let vu = 4; vu <= total; vu++) {
    // Greedy deficit: pick whichever role is most behind its ideal ratio
    const tIdeal = teacherVus * (vu / total);
    const sIdeal = studentVus * (vu / total);
    const aIdeal = adminVus * (vu / total);

    const tDeficit = tIdeal - t;
    const sDeficit = sIdeal - s;
    const aDeficit = aIdeal - a;

    let chosen: 'Teacher' | 'Student' | 'Admin';

    if (t < teacherVus && tDeficit >= sDeficit && tDeficit >= aDeficit) {
      chosen = 'Teacher';
    } else if (s < studentVus && sDeficit >= aDeficit) {
      chosen = 'Student';
    } else if (a < adminVus) {
      chosen = 'Admin';
    } else if (t < teacherVus) {
      chosen = 'Teacher';
    } else {
      chosen = 'Student';
    }

    roleMap[vu] = chosen;
    if (chosen === 'Teacher') vuTokens[vu] = teacherTokens[++t];
    else if (chosen === 'Student') vuTokens[vu] = studentTokens[++s];
    else vuTokens[vu] = adminTokens[++a];
  }

  return { roleMap, vuTokens };
}
