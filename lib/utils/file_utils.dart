import 'dart:io';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:path_provider/path_provider.dart';

Future<String> path(CaptureMode captureMode) async {
  final Directory extDir = await getTemporaryDirectory();
  final testDir = await Directory(
    '${extDir.path}/camerawesome',
  ).create(recursive: true);

  final String filePath = captureMode == CaptureMode.photo
      ? '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg'
      : '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

  return filePath;
}

