import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:likha/presentation/widgets/shared/dialogs/upload_progress_dialog.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders file name and 0% progress', (tester) async {
    await tester.pumpWidget(_wrap(
      const UploadProgressDialog(fileName: 'report.pdf', progress: 0.0),
    ));
    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows correct percentage at 50%', (tester) async {
    await tester.pumpWidget(_wrap(
      const UploadProgressDialog(fileName: 'photo.jpg', progress: 0.5),
    ));
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('shows 100% when complete', (tester) async {
    await tester.pumpWidget(_wrap(
      const UploadProgressDialog(fileName: 'video.mp4', progress: 1.0),
    ));
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('shows cancel button when onCancel provided', (tester) async {
    await tester.pumpWidget(_wrap(
      UploadProgressDialog(
        fileName: 'file.zip',
        progress: 0.3,
        onCancel: () {},
      ),
    ));
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('hides cancel button when onCancel is null', (tester) async {
    await tester.pumpWidget(_wrap(
      const UploadProgressDialog(fileName: 'file.zip', progress: 0.3),
    ));
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('cancel button triggers callback', (tester) async {
    var cancelled = false;
    await tester.pumpWidget(_wrap(
      UploadProgressDialog(
        fileName: 'file.zip',
        progress: 0.3,
        onCancel: () => cancelled = true,
      ),
    ));
    await tester.tap(find.text('Cancel'));
    expect(cancelled, isTrue);
  });
}
