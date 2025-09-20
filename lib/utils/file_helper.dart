import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File?> getInventoryImage(String? filename) async {
  if (filename == null || filename.isEmpty) return null;
  final appDir = await getApplicationDocumentsDirectory();
  final fullPath = '${appDir.path}/$filename';
  final file = File(fullPath);
  if (await file.exists()) return file;
  return null;
}
