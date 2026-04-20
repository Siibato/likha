import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/grade_computation_util.dart';
import 'package:likha/domain/grading/entities/grade_config.dart';
import 'package:likha/domain/grading/entities/grade_item.dart';
import 'package:likha/domain/grading/entities/grade_score.dart';
import 'package:likha/domain/grading/entities/period_grade.dart';

void main() {
  group('GradeComputationUtil', () {
    // Test data builders
    GradeConfig createConfig({
      double wwWeight = 30.0,
      double ptWeight = 50.0,
      double qaWeight = 20.0,
    }) {
      return GradeConfig(
        id: 'config-1',
        classId: 'class-1',
        gradingPeriodNumber: 1,
        wwWeight: wwWeight,
        ptWeight: ptWeight,
        qaWeight: qaWeight,
      );
    }

    GradeItem createItem({
      required String id,
      required String component,
      double totalPoints = 100.0,
    }) {
      return GradeItem(
        id: id,
        classId: 'class-1',
        title: 'Test Item',
        component: component,
        gradingPeriodNumber: 1,
        totalPoints: totalPoints,
        sourceType: 'assignment',
        orderIndex: 0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    }

    GradeScore createScore({
      required String itemId,
      required double? score,
      double? overrideScore,
    }) {
      return GradeScore(
        id: 'score-$itemId',
        gradeItemId: itemId,
        studentId: 'student-1',
        score: score,
        isAutoPopulated: false,
        overrideScore: overrideScore,
      );
    }

    group('computePreview', () {
      test('returns correct period grade with all components', () {
        final config = createConfig(wwWeight: 30, ptWeight: 50, qaWeight: 20);
        final items = [
          createItem(id: 'ww1', component: 'written_work', totalPoints: 100),
          createItem(id: 'pt1', component: 'performance_task', totalPoints: 100),
          createItem(id: 'qa1', component: 'quarterly_assessment', totalPoints: 100),
        ];
        final scoresByItem = {
          'ww1': [createScore(itemId: 'ww1', score: 80)], // 80%
          'pt1': [createScore(itemId: 'pt1', score: 90)], // 90%
          'qa1': [createScore(itemId: 'qa1', score: 85)], // 85%
        };

        final result = GradeComputationUtil.computePreview(
          config: config,
          items: items,
          scoresByItem: scoresByItem,
          classId: 'class-1',
          studentId: 'student-1',
          gradingPeriodNumber: 1,
        );

        // WW: 80 * 0.30 = 24
        // PT: 90 * 0.50 = 45
        // QA: 85 * 0.20 = 17
        // Initial: 24 + 45 + 17 = 86
        expect(result.initialGrade, closeTo(86.0, 0.01));
        // Transmuted: floor(75 + (86-60)/1.6) = floor(91.25) = 91
        expect(result.transmutedGrade, equals(91));
        expect(result.isLocked, isTrue); // All items have scores
        expect(result.isPreview, isTrue);
      });

      test('handles empty items list', () {
        final config = createConfig();
        final items = <GradeItem>[];
        final scoresByItem = <String, List<GradeScore>>{};

        final result = GradeComputationUtil.computePreview(
          config: config,
          items: items,
          scoresByItem: scoresByItem,
          classId: 'class-1',
          studentId: 'student-1',
          gradingPeriodNumber: 1,
        );

        // All components are 0, so initial grade is 0
        expect(result.initialGrade, equals(0.0));
        expect(result.isLocked, isFalse); // No items, not complete
      });

      test('handles partial scores (not all items scored)', () {
        final config = createConfig();
        final items = [
          createItem(id: 'ww1', component: 'written_work'),
          createItem(id: 'ww2', component: 'written_work'),
        ];
        final scoresByItem = {
          'ww1': [createScore(itemId: 'ww1', score: 80)],
          // ww2 has no score
        };

        final result = GradeComputationUtil.computePreview(
          config: config,
          items: items,
          scoresByItem: scoresByItem,
          classId: 'class-1',
          studentId: 'student-1',
          gradingPeriodNumber: 1,
        );

        expect(result.isLocked, isFalse); // Not all items scored
      });

      test('handles missing component (no items of a type)', () {
        final config = createConfig();
        final items = [
          createItem(id: 'ww1', component: 'written_work'), // Only WW items
        ];
        final scoresByItem = {
          'ww1': [createScore(itemId: 'ww1', score: 80)],
        };

        final result = GradeComputationUtil.computePreview(
          config: config,
          items: items,
          scoresByItem: scoresByItem,
          classId: 'class-1',
          studentId: 'student-1',
          gradingPeriodNumber: 1,
        );

        // PT and QA contribute 0 but don't break calculation
        expect(result.initialGrade, closeTo(24.0, 0.01)); // 80 * 0.30 = 24
      });

      test('handles override scores correctly', () {
        final config = createConfig();
        final items = [
          createItem(id: 'ww1', component: 'written_work'),
        ];
        final scoresByItem = {
          'ww1': [createScore(itemId: 'ww1', score: 70, overrideScore: 85)],
        };

        final result = GradeComputationUtil.computePreview(
          config: config,
          items: items,
          scoresByItem: scoresByItem,
          classId: 'class-1',
          studentId: 'student-1',
          gradingPeriodNumber: 1,
        );

        // Should use override score (85) not original (70)
        expect(result.initialGrade, closeTo(25.5, 0.01)); // 85 * 0.30 = 25.5
      });

      test('handles null scores (student has no score)', () {
        final config = createConfig();
        final items = [
          createItem(id: 'ww1', component: 'written_work'),
        ];
        final scoresByItem = {
          'ww1': [createScore(itemId: 'ww1', score: null)],
        };

        final result = GradeComputationUtil.computePreview(
          config: config,
          items: items,
          scoresByItem: scoresByItem,
          classId: 'class-1',
          studentId: 'student-1',
          gradingPeriodNumber: 1,
        );

        expect(result.isLocked, isFalse); // Score is null, not complete
      });

      test('applies different weight configurations', () {
        // Math/Science weight: WW 40%, PT 40%, QA 20%
        final config = createConfig(wwWeight: 40, ptWeight: 40, qaWeight: 20);
        final items = [
          createItem(id: 'ww1', component: 'written_work'),
          createItem(id: 'pt1', component: 'performance_task'),
          createItem(id: 'qa1', component: 'quarterly_assessment'),
        ];
        final scoresByItem = {
          'ww1': [createScore(itemId: 'ww1', score: 80)], // 80 * 0.40 = 32
          'pt1': [createScore(itemId: 'pt1', score: 90)], // 90 * 0.40 = 36
          'qa1': [createScore(itemId: 'qa1', score: 85)], // 85 * 0.20 = 17
        };

        final result = GradeComputationUtil.computePreview(
          config: config,
          items: items,
          scoresByItem: scoresByItem,
          classId: 'class-1',
          studentId: 'student-1',
          gradingPeriodNumber: 1,
        );

        // 32 + 36 + 17 = 85
        expect(result.initialGrade, closeTo(85.0, 0.01));
      });

      test('correctly computes transmuted grade', () {
        final config = createConfig();
        final items = [
          createItem(id: 'ww1', component: 'written_work'),
        ];
        final scoresByItem = {
          'ww1': [createScore(itemId: 'ww1', score: 100)], // 100%
        };

        final result = GradeComputationUtil.computePreview(
          config: config,
          items: items,
          scoresByItem: scoresByItem,
          classId: 'class-1',
          studentId: 'student-1',
          gradingPeriodNumber: 1,
        );

        // 100 * 0.30 = 30 initial
        expect(result.initialGrade, closeTo(30.0, 0.01));
        // Verify transmuted is calculated
        expect(result.transmutedGrade, isNotNull);
      });

      test('handles multiple students in score list (filters correctly)', () {
        final config = createConfig();
        final items = [
          createItem(id: 'ww1', component: 'written_work'),
        ];
        final scoresByItem = {
          'ww1': [
            GradeScore(
              id: 'score-1',
              gradeItemId: 'ww1',
              studentId: 'other-student',
              score: 95,
              isAutoPopulated: false,
            ),
            GradeScore(
              id: 'score-2',
              gradeItemId: 'ww1',
              studentId: 'student-1',
              score: 80,
              isAutoPopulated: false,
            ),
          ],
        };

        final result = GradeComputationUtil.computePreview(
          config: config,
          items: items,
          scoresByItem: scoresByItem,
          classId: 'class-1',
          studentId: 'student-1',
          gradingPeriodNumber: 1,
        );

        // Should use 80 (student-1's score), not 95
        expect(result.initialGrade, closeTo(24.0, 0.01)); // 80 * 0.30 = 24
      });
    });

    group('computeFinalGrade', () {
      test('returns null for empty period grades list', () {
        expect(GradeComputationUtil.computeFinalGrade([]), isNull);
      });

      test('returns null when no grades are locked', () {
        final grades = [
          PeriodGrade(
            id: 'pg1',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 1,
            initialGrade: 85,
            transmutedGrade: 88,
            isLocked: false,
            computedAt: DateTime.now(),
          ),
        ];
        expect(GradeComputationUtil.computeFinalGrade(grades), isNull);
      });

      test('returns null when no grades have transmuted grades', () {
        final grades = [
          PeriodGrade(
            id: 'pg1',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 1,
            initialGrade: 85,
            transmutedGrade: null,
            isLocked: true,
            computedAt: DateTime.now(),
          ),
        ];
        expect(GradeComputationUtil.computeFinalGrade(grades), isNull);
      });

      test('computes average of single locked grade', () {
        final grades = [
          PeriodGrade(
            id: 'pg1',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 1,
            initialGrade: 85,
            transmutedGrade: 88,
            isLocked: true,
            computedAt: DateTime.now(),
          ),
        ];
        expect(GradeComputationUtil.computeFinalGrade(grades), equals(88.0));
      });

      test('computes average of multiple locked grades', () {
        final grades = [
          PeriodGrade(
            id: 'pg1',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 1,
            initialGrade: 80,
            transmutedGrade: 84,
            isLocked: true,
            computedAt: DateTime.now(),
          ),
          PeriodGrade(
            id: 'pg2',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 2,
            initialGrade: 90,
            transmutedGrade: 92,
            isLocked: true,
            computedAt: DateTime.now(),
          ),
        ];
        // (84 + 92) / 2 = 88
        expect(GradeComputationUtil.computeFinalGrade(grades), equals(88.0));
      });

      test('ignores unlocked grades in average', () {
        final grades = [
          PeriodGrade(
            id: 'pg1',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 1,
            initialGrade: 80,
            transmutedGrade: 84,
            isLocked: true,
            computedAt: DateTime.now(),
          ),
          PeriodGrade(
            id: 'pg2',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 2,
            initialGrade: 90,
            transmutedGrade: 92,
            isLocked: false, // Not locked - should be ignored
            computedAt: DateTime.now(),
          ),
        ];
        expect(GradeComputationUtil.computeFinalGrade(grades), equals(84.0));
      });

      test('ignores grades with null transmuted in average', () {
        final grades = [
          PeriodGrade(
            id: 'pg1',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 1,
            initialGrade: 80,
            transmutedGrade: 84,
            isLocked: true,
            computedAt: DateTime.now(),
          ),
          PeriodGrade(
            id: 'pg2',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 2,
            initialGrade: 90,
            transmutedGrade: null, // Null transmuted - should be ignored
            isLocked: true,
            computedAt: DateTime.now(),
          ),
        ];
        expect(GradeComputationUtil.computeFinalGrade(grades), equals(84.0));
      });

      test('handles all four quarters (SF10 use case)', () {
        final grades = [
          PeriodGrade(
            id: 'q1',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 1,
            initialGrade: 85,
            transmutedGrade: 88,
            isLocked: true,
            computedAt: DateTime.now(),
          ),
          PeriodGrade(
            id: 'q2',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 2,
            initialGrade: 87,
            transmutedGrade: 89,
            isLocked: true,
            computedAt: DateTime.now(),
          ),
          PeriodGrade(
            id: 'q3',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 3,
            initialGrade: 86,
            transmutedGrade: 88,
            isLocked: true,
            computedAt: DateTime.now(),
          ),
          PeriodGrade(
            id: 'q4',
            classId: 'class-1',
            studentId: 'student-1',
            gradingPeriodNumber: 4,
            initialGrade: 88,
            transmutedGrade: 90,
            isLocked: true,
            computedAt: DateTime.now(),
          ),
        ];
        // (88 + 89 + 88 + 90) / 4 = 88.75
        expect(GradeComputationUtil.computeFinalGrade(grades), equals(88.75));
      });
    });
  });
}
