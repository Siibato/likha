import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:likha/core/errors/failures.dart';
import 'package:likha/core/events/data_event_bus.dart';
import 'package:likha/domain/learning_materials/usecases/create_material.dart';
import 'package:likha/domain/learning_materials/usecases/delete_file.dart' as material;
import 'package:likha/domain/learning_materials/usecases/delete_material.dart';
import 'package:likha/domain/learning_materials/usecases/download_file.dart' as material;
import 'package:likha/domain/learning_materials/usecases/get_material_detail.dart';
import 'package:likha/domain/learning_materials/usecases/get_materials.dart';
import 'package:likha/domain/learning_materials/usecases/reorder_material.dart' as material;
import 'package:likha/domain/learning_materials/usecases/update_material.dart';
import 'package:likha/domain/learning_materials/usecases/upload_file.dart' as material;
import 'package:likha/presentation/providers/learning_material_provider.dart';

import '../../../helpers/fake_entities.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockCreateMaterial extends Mock implements CreateMaterial {}
class MockGetMaterials extends Mock implements GetMaterials {}
class MockGetMaterialDetail extends Mock implements GetMaterialDetail {}
class MockUpdateMaterial extends Mock implements UpdateMaterial {}
class MockDeleteMaterial extends Mock implements DeleteMaterial {}
class MockReorderMaterial extends Mock implements material.ReorderMaterial {}
class MockReorderAllMaterials extends Mock implements material.ReorderAllMaterials {}
class MockUploadFile extends Mock implements material.UploadFile {}
class MockDeleteFile extends Mock implements material.DeleteFile {}
class MockDownloadFile extends Mock implements material.DownloadFile {}

// ── Helpers ───────────────────────────────────────────────────────────────────

LearningMaterialNotifier _buildNotifier({
  MockGetMaterials? getMaterials,
  MockCreateMaterial? createMaterial,
  MockDeleteMaterial? deleteMaterial,
}) {
  return LearningMaterialNotifier(
    createMaterial ?? MockCreateMaterial(),
    getMaterials ?? MockGetMaterials(),
    MockGetMaterialDetail(),
    MockUpdateMaterial(),
    deleteMaterial ?? MockDeleteMaterial(),
    MockReorderMaterial(),
    MockReorderAllMaterials(),
    MockUploadFile(),
    MockDeleteFile(),
    MockDownloadFile(),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final tMaterial = FakeEntities.learningMaterial();

  setUpAll(() async {
    dotenv.testLoad(fileInput: '');
    GetIt.instance.registerSingleton<DataEventBus>(DataEventBus());
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('LearningMaterialNotifier', () {
    group('loadMaterials', () {
      test('populates materials on success', () async {
        final mockGet = MockGetMaterials();
        final notifier = _buildNotifier(getMaterials: mockGet);

        when(() => mockGet.call(any()))
            .thenAnswer((_) async => Right([tMaterial]));

        final states = <LearningMaterialState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.loadMaterials('c-1');

        expect(states.last.isLoading, isFalse);
        expect(states.last.materials.length, 1);
        expect(states.last.error, isNull);
      });

      test('sets error on failure', () async {
        final mockGet = MockGetMaterials();
        final notifier = _buildNotifier(getMaterials: mockGet);

        when(() => mockGet.call(any()))
            .thenAnswer((_) async => const Left(ServerFailure('server error')));

        final states = <LearningMaterialState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.loadMaterials('c-1');

        expect(states.last.isLoading, isFalse);
        expect(states.last.error, isNotNull);
      });
    });

    group('createMaterial', () {
      test('appends new material and sets success message', () async {
        final mockCreate = MockCreateMaterial();
        final notifier = _buildNotifier(createMaterial: mockCreate);

        when(() => mockCreate.call(
              classId: any(named: 'classId'),
              title: any(named: 'title'),
              description: any(named: 'description'),
              contentText: any(named: 'contentText'),
            )).thenAnswer((_) async => Right(tMaterial));

        final states = <LearningMaterialState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.createMaterial(classId: 'c-1', title: 'Lesson 1');

        expect(states.last.materials, contains(tMaterial));
        expect(states.last.successMessage, isNotNull);
        expect(states.last.error, isNull);
      });

      test('sets error when create fails', () async {
        final mockCreate = MockCreateMaterial();
        final notifier = _buildNotifier(createMaterial: mockCreate);

        when(() => mockCreate.call(
              classId: any(named: 'classId'),
              title: any(named: 'title'),
              description: any(named: 'description'),
              contentText: any(named: 'contentText'),
            )).thenAnswer((_) async => const Left(ServerFailure('create failed')));

        final states = <LearningMaterialState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.createMaterial(classId: 'c-1', title: 'Lesson 1');

        expect(states.last.error, isNotNull);
        expect(states.last.successMessage, isNull);
      });
    });

    group('deleteMaterial', () {
      test('removes material from list on success', () async {
        final mockDelete = MockDeleteMaterial();
        final notifier = _buildNotifier(deleteMaterial: mockDelete);

        notifier.state = notifier.state.copyWith(materials: [tMaterial]);

        when(() => mockDelete.call(any()))
            .thenAnswer((_) async => const Right(null));

        final states = <LearningMaterialState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.deleteMaterial(tMaterial.id);

        expect(states.last.materials, isEmpty);
        expect(states.last.successMessage, isNotNull);
      });

      test('sets error when delete fails', () async {
        final mockDelete = MockDeleteMaterial();
        final notifier = _buildNotifier(deleteMaterial: mockDelete);

        notifier.state = notifier.state.copyWith(materials: [tMaterial]);

        when(() => mockDelete.call(any()))
            .thenAnswer((_) async => const Left(ServerFailure('delete failed')));

        final states = <LearningMaterialState>[];
        notifier.addListener((s) => states.add(s), fireImmediately: false);

        await notifier.deleteMaterial(tMaterial.id);

        expect(states.last.error, isNotNull);
        expect(states.last.materials.length, 1);
      });
    });
  });
}
