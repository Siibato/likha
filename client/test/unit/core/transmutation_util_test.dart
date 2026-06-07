import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/utils/transmutation_util.dart';
import 'package:likha/domain/assignments/entities/assignment.dart';

void main() {
  group('TransmutationUtil', () {
    group('transmute', () {
      test('returns 60 for raw score 0', () {
        expect(TransmutationUtil.transmute(0), equals(60));
      });

      test('returns 60 for negative raw scores', () {
        expect(TransmutationUtil.transmute(-10), equals(60));
        expect(TransmutationUtil.transmute(-100), equals(60));
      });

      test('returns 100 for raw score exactly 100', () {
        expect(TransmutationUtil.transmute(100), equals(100));
      });

      test('returns 100 for raw scores above 100', () {
        expect(TransmutationUtil.transmute(101), equals(100));
        expect(TransmutationUtil.transmute(150), equals(100));
      });

      group('below 60 range (0-59.99) - floor(raw/4) + 60', () {
        test('transmutes boundary 0 correctly', () {
          expect(TransmutationUtil.transmute(0), equals(60));
        });

        test('transmutes 4 points to 1 grade point increment', () {
          expect(TransmutationUtil.transmute(4), equals(61));  // floor(4/4) + 60 = 61
          expect(TransmutationUtil.transmute(8), equals(62));  // floor(8/4) + 60 = 62
          expect(TransmutationUtil.transmute(20), equals(65)); // floor(20/4) + 60 = 65
        });

        test('transmutes 50 correctly (mid-range)', () {
          // floor(50/4) + 60 = floor(12.5) + 60 = 72
          expect(TransmutationUtil.transmute(50), equals(72));
        });

        test('transmutes just below 60 correctly', () {
          expect(TransmutationUtil.transmute(59), equals(74));  // floor(59/4) + 60 = 74
          expect(TransmutationUtil.transmute(59.9), equals(74)); // floor(59.9/4) + 60 = 74
        });
      });

      group('60-100 range - floor(75 + (raw-60)/1.6)', () {
        test('transmutes boundary 60 correctly (passing threshold)', () {
          // floor(75 + (60-60)/1.6) = floor(75) = 75
          expect(TransmutationUtil.transmute(60), equals(75));
        });

        test('transmutes typical passing grades correctly', () {
          // floor(75 + (70-60)/1.6) = floor(75 + 6.25) = 81
          expect(TransmutationUtil.transmute(70), equals(81));
          // floor(75 + (80-60)/1.6) = floor(75 + 12.5) = 87
          expect(TransmutationUtil.transmute(80), equals(87));
          // floor(75 + (90-60)/1.6) = floor(75 + 18.75) = 93
          expect(TransmutationUtil.transmute(90), equals(93));
        });

        test('transmutes 99.99 to a high grade', () {
          // floor(75 + (99.99-60)/1.6) = floor(75 + 24.99) = 99
          expect(TransmutationUtil.transmute(99.99), equals(99));
        });

        test('each ~1.6 points = 1 grade point above 60', () {
          expect(TransmutationUtil.transmute(61.6), equals(76));  // ~1.6 points = 1 grade
          expect(TransmutationUtil.transmute(63.2), equals(77)); // ~3.2 points = 2 grades
        });
      });
    });

    group('getDescriptor', () {
      test('returns Did Not Meet Expectations for grades below 75', () {
        expect(TransmutationUtil.getDescriptor(60), equals('Did Not Meet Expectations'));
        expect(TransmutationUtil.getDescriptor(74), equals('Did Not Meet Expectations'));
      });

      test('returns Fairly Satisfactory for grades 75-79', () {
        expect(TransmutationUtil.getDescriptor(75), equals('Fairly Satisfactory'));
        expect(TransmutationUtil.getDescriptor(77), equals('Fairly Satisfactory'));
        expect(TransmutationUtil.getDescriptor(79), equals('Fairly Satisfactory'));
      });

      test('returns Satisfactory for grades 80-84', () {
        expect(TransmutationUtil.getDescriptor(80), equals('Satisfactory'));
        expect(TransmutationUtil.getDescriptor(82), equals('Satisfactory'));
        expect(TransmutationUtil.getDescriptor(84), equals('Satisfactory'));
      });

      test('returns Very Satisfactory for grades 85-89', () {
        expect(TransmutationUtil.getDescriptor(85), equals('Very Satisfactory'));
        expect(TransmutationUtil.getDescriptor(87), equals('Very Satisfactory'));
        expect(TransmutationUtil.getDescriptor(89), equals('Very Satisfactory'));
      });

      test('returns Outstanding for grades 90-100', () {
        expect(TransmutationUtil.getDescriptor(90), equals('Outstanding'));
        expect(TransmutationUtil.getDescriptor(95), equals('Outstanding'));
        expect(TransmutationUtil.getDescriptor(100), equals('Outstanding'));
      });

      test('handles edge case 0 correctly', () {
        expect(TransmutationUtil.getDescriptor(0), equals('Did Not Meet Expectations'));
      });
    });

    group('getDescriptorColor', () {
      test('returns red for grades below 75', () {
        expect(TransmutationUtil.getDescriptorColor(60), equals(0xFFE57373));
        expect(TransmutationUtil.getDescriptorColor(74), equals(0xFFE57373));
      });

      test('returns amber for grades 75-79', () {
        expect(TransmutationUtil.getDescriptorColor(75), equals(0xFFFFC107));
        expect(TransmutationUtil.getDescriptorColor(79), equals(0xFFFFC107));
      });

      test('returns blue for grades 80-84', () {
        expect(TransmutationUtil.getDescriptorColor(80), equals(0xFF4A90D9));
        expect(TransmutationUtil.getDescriptorColor(84), equals(0xFF4A90D9));
      });

      test('returns blue for grades 85-89', () {
        expect(TransmutationUtil.getDescriptorColor(85), equals(0xFF2196F3));
        expect(TransmutationUtil.getDescriptorColor(89), equals(0xFF2196F3));
      });

      test('returns green for grades 90-100', () {
        expect(TransmutationUtil.getDescriptorColor(90), equals(0xFF4CAF50));
        expect(TransmutationUtil.getDescriptorColor(100), equals(0xFF4CAF50));
      });
    });

    group('computeRawScore', () {
      final baseAssignment = Assignment(
        id: 'test-id',
        classId: 'class-id',
        title: 'Test',
        instructions: 'Instructions',
        totalPoints: 100,
        allowsTextSubmission: true,
        allowsFileSubmission: false,
        dueAt: DateTime.now(),
        isPublished: true,
        orderIndex: 0,
        submissionCount: 1,
        gradedCount: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      test('returns 0 for empty assignments list', () {
        expect(TransmutationUtil.computeRawScore([]), equals(0));
      });

      test('returns 0 when no graded/returned assignments', () {
        final assignments = [
          baseAssignment.copyWith(submissionStatus: 'submitted', score: 90),
          baseAssignment.copyWith(submissionStatus: 'pending', score: 80),
        ];
        expect(TransmutationUtil.computeRawScore(assignments), equals(0));
      });

      test('calculates average for graded assignments', () {
        final assignments = [
          baseAssignment.copyWith(submissionStatus: 'graded', score: 80, totalPoints: 100),
          baseAssignment.copyWith(submissionStatus: 'graded', score: 90, totalPoints: 100),
        ];
        // (80 + 90) / 200 * 100 = 85%
        expect(TransmutationUtil.computeRawScore(assignments), equals(85));
      });

      test('calculates average for returned assignments', () {
        final assignments = [
          baseAssignment.copyWith(submissionStatus: 'returned', score: 70, totalPoints: 100),
          baseAssignment.copyWith(submissionStatus: 'returned', score: 80, totalPoints: 100),
        ];
        // (70 + 80) / 200 * 100 = 75%
        expect(TransmutationUtil.computeRawScore(assignments), equals(75));
      });

      test('handles mixed graded and returned assignments', () {
        final assignments = [
          baseAssignment.copyWith(submissionStatus: 'graded', score: 80, totalPoints: 100),
          baseAssignment.copyWith(submissionStatus: 'returned', score: 90, totalPoints: 100),
          baseAssignment.copyWith(submissionStatus: 'submitted', score: 70, totalPoints: 100),
        ];
        // (80 + 90) / 200 * 100 = 85%
        expect(TransmutationUtil.computeRawScore(assignments), equals(85));
      });

      test('handles different total points', () {
        final assignments = [
          baseAssignment.copyWith(submissionStatus: 'graded', score: 40, totalPoints: 50),
          baseAssignment.copyWith(submissionStatus: 'graded', score: 45, totalPoints: 50),
        ];
        // (40 + 45) / 100 * 100 = 85%
        expect(TransmutationUtil.computeRawScore(assignments), equals(85));
      });

      test('handles zero total points gracefully', () {
        final assignments = [
          baseAssignment.copyWith(submissionStatus: 'graded', score: 0, totalPoints: 0),
        ];
        expect(TransmutationUtil.computeRawScore(assignments), equals(0));
      });

      test('handles null scores', () {
        final assignments = [
          baseAssignment.copyWith(submissionStatus: 'graded', score: null, totalPoints: 100),
        ];
        expect(TransmutationUtil.computeRawScore(assignments), equals(0));
      });
    });
  });
}
