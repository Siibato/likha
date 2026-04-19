import 'package:flutter_test/flutter_test.dart';
import 'package:likha/core/constants/file_types.dart';

void main() {
  group('FileTypeCategory', () {
    test('has correct structure with label and types', () {
      const category = FileTypeCategory('Test', ['pdf', 'doc']);
      expect(category.label, equals('Test'));
      expect(category.types, equals(['pdf', 'doc']));
    });
  });

  group('kFileTypeCategories', () {
    test('contains expected number of categories', () {
      expect(kFileTypeCategories.length, equals(9));
    });

    test('contains Documents category', () {
      final docs = kFileTypeCategories.firstWhere((c) => c.label == 'Documents');
      expect(docs.types, contains('pdf'));
      expect(docs.types, contains('doc'));
      expect(docs.types, contains('docx'));
      expect(docs.types, contains('txt'));
    });

    test('contains Spreadsheets category', () {
      final sheets = kFileTypeCategories.firstWhere((c) => c.label == 'Spreadsheets');
      expect(sheets.types, contains('xls'));
      expect(sheets.types, contains('xlsx'));
      expect(sheets.types, contains('csv'));
    });

    test('contains Presentations category', () {
      final prez = kFileTypeCategories.firstWhere((c) => c.label == 'Presentations');
      expect(prez.types, contains('ppt'));
      expect(prez.types, contains('pptx'));
    });

    test('contains Images category', () {
      final images = kFileTypeCategories.firstWhere((c) => c.label == 'Images');
      expect(images.types, contains('jpg'));
      expect(images.types, contains('jpeg'));
      expect(images.types, contains('png'));
      expect(images.types, contains('gif'));
      expect(images.types, contains('svg'));
      expect(images.types, contains('webp'));
    });

    test('contains Audio category', () {
      final audio = kFileTypeCategories.firstWhere((c) => c.label == 'Audio');
      expect(audio.types, contains('mp3'));
      expect(audio.types, contains('wav'));
      expect(audio.types, contains('m4a'));
      expect(audio.types, contains('flac'));
    });

    test('contains Video category', () {
      final video = kFileTypeCategories.firstWhere((c) => c.label == 'Video');
      expect(video.types, contains('mp4'));
      expect(video.types, contains('avi'));
      expect(video.types, contains('mov'));
      expect(video.types, contains('mkv'));
      expect(video.types, contains('webm'));
    });

    test('contains Archives category', () {
      final archives = kFileTypeCategories.firstWhere((c) => c.label == 'Archives');
      expect(archives.types, contains('zip'));
      expect(archives.types, contains('rar'));
      expect(archives.types, contains('7z'));
      expect(archives.types, contains('tar'));
    });

    test('contains Data category', () {
      final data = kFileTypeCategories.firstWhere((c) => c.label == 'Data');
      expect(data.types, contains('json'));
      expect(data.types, contains('xml'));
      expect(data.types, contains('yaml'));
      expect(data.types, contains('sql'));
    });

    test('contains eBooks category', () {
      final ebooks = kFileTypeCategories.firstWhere((c) => c.label == 'eBooks');
      expect(ebooks.types, contains('pdf'));
      expect(ebooks.types, contains('epub'));
      expect(ebooks.types, contains('mobi'));
    });

    test('pdf appears in both Documents and eBooks', () {
      final docs = kFileTypeCategories.firstWhere((c) => c.label == 'Documents');
      final ebooks = kFileTypeCategories.firstWhere((c) => c.label == 'eBooks');
      expect(docs.types, contains('pdf'));
      expect(ebooks.types, contains('pdf'));
    });

    test('all categories have non-empty labels', () {
      for (final category in kFileTypeCategories) {
        expect(category.label, isNotEmpty);
      }
    });

    test('all categories have at least one type', () {
      for (final category in kFileTypeCategories) {
        expect(category.types, isNotEmpty);
      }
    });

    test('all file extensions are lowercase', () {
      for (final category in kFileTypeCategories) {
        for (final type in category.types) {
          expect(type, equals(type.toLowerCase()),
              reason: 'Extension $type in ${category.label} should be lowercase');
        }
      }
    });

    test('common assignment file types are supported', () {
      // Students typically submit these
      final allTypes = kFileTypeCategories.expand((c) => c.types).toSet();

      expect(allTypes, contains('pdf'));
      expect(allTypes, contains('doc'));
      expect(allTypes, contains('docx'));
      expect(allTypes, contains('jpg'));
      expect(allTypes, contains('png'));
      expect(allTypes, contains('mp4'));
    });
  });
}
