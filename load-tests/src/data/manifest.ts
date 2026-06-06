declare function open(path: string): string;

export interface ManifestUser {
  id: string;
  username: string;
  role: 'admin' | 'teacher' | 'student';
  full_name: string;
}

export interface ManifestClass {
  id: string;
  title: string;
  grade_level: string | null;
  is_deleted: boolean;
}

export interface ManifestAssessment {
  id: string;
  class_id: string;
  title: string;
  total_points: number;
  is_published: boolean;
  grading_period_number: number;
  question_ids: string[];
}

export interface ManifestAssignment {
  id: string;
  class_id: string;
  title: string;
  total_points: number;
  is_published: boolean;
  grading_period_number: number;
}

export interface SeedManifest {
  users: ManifestUser[];
  classes: ManifestClass[];
  assessments: ManifestAssessment[];
  assignments: ManifestAssignment[];
}

// TODO: Populate seed-manifest.json by running:
//   ./server seed-manual --export-manifest ../load-tests/seed-manifest.json
// Until then this will throw at k6 init time.
const raw = open('./seed-manifest.json');
export const manifest: SeedManifest = JSON.parse(raw);

export const publishedAssessments = manifest.assessments.filter(
  (a) => a.is_published,
);

export const publishedAssignments = manifest.assignments.filter(
  (a) => a.is_published,
);

export const activeClasses = manifest.classes.filter(
  (c) => !c.is_deleted,
);

export const students = manifest.users.filter(
  (u) => u.role === 'student',
);

export const teachers = manifest.users.filter(
  (u) => u.role === 'teacher',
);

export function randomItem<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}
