import 'dart:io';

Future<void> saveAndDownloadFile(List<int> bytes, String fileName) async {
  String dir = Directory.current.path;
  final userProfile = Platform.environment['USERPROFILE'];
  if (userProfile != null) {
    final downloadsDir = Directory('$userProfile\\Downloads');
    if (downloadsDir.existsSync()) {
      dir = downloadsDir.path;
    }
  }
  final file = File('$dir\\$fileName');
  await file.writeAsBytes(bytes);
}
