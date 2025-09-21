import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class LocalFileService {
  static const String _chatDir = 'chat_attachments';
  
  /// Get the directory for storing chat attachments
  Future<Directory> _getChatDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final chatDir = Directory(path.join(appDir.path, _chatDir));
    if (!await chatDir.exists()) {
      await chatDir.create(recursive: true);
    }
    return chatDir;
  }
  
  /// Save file to local storage and return the local path
  Future<String> saveFile({
    required String customerId,
    required String fileName,
    required Uint8List fileData,
  }) async {
    try {
      final chatDir = await _getChatDirectory();
      final customerDir = Directory(path.join(chatDir.path, customerId));
      if (!await customerDir.exists()) {
        await customerDir.create(recursive: true);
      }
      
      final filePath = path.join(customerDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(fileData);
      
      debugPrint('[LocalFileService] File saved: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('[LocalFileService] Error saving file: $e');
      rethrow;
    }
  }
  
  /// Get file from local storage
  Future<File?> getFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('[LocalFileService] Error getting file: $e');
      return null;
    }
  }
  
  /// Check if file exists locally
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('[LocalFileService] Error checking file existence: $e');
      return false;
    }
  }
  
  /// Delete file from local storage
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[LocalFileService] Error deleting file: $e');
      return false;
    }
  }
  
  /// Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      debugPrint('[LocalFileService] Error getting file size: $e');
      return 0;
    }
  }
  
  /// Get MIME type from file extension
  String getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt': return 'text/plain';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'mp4': return 'video/mp4';
      case 'mp3': return 'audio/mpeg';
      default: return 'application/octet-stream';
    }
  }
}

