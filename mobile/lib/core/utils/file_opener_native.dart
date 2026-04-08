import 'package:open_file/open_file.dart';

Future<void> openLocalFile(String path) async {
  await OpenFile.open(path);
}

Future<void> openFileInBrowser(List<int> bytes, String fileName) async {}
