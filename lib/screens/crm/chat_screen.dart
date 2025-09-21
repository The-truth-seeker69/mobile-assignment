import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firestore_service.dart';
import '../../services/local_file_service.dart';

class ChatScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  const ChatScreen({super.key, required this.customerId, required this.customerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirestoreCrmService _crm = FirestoreCrmService();
  final LocalFileService _fileService = LocalFileService();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  bool _showAttachmentBar = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        centerTitle: true,
        title: Text(widget.customerName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _crm.streamChatMessages(widget.customerId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  print('Chat error: ${snap.error}');
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  print('No chat data available');
                  return const Center(child: Text('No messages found'));
                }
                final messages = snap.data!;
                print('Raw messages from Firestore: $messages');
                
                // Sort messages by timestamp to ensure oldest to newest order
                final sortedMessages = List<Map<String, dynamic>>.from(messages);
                sortedMessages.sort((a, b) {
                  final timestampA = _parseTimestamp(a['timestamp']);
                  final timestampB = _parseTimestamp(b['timestamp']);
                  
                  if (timestampA == null && timestampB == null) return 0;
                  if (timestampA == null) return 1;
                  if (timestampB == null) return -1;
                  
                  return timestampA.compareTo(timestampB);
                });
                
                // Debug: Print message order
                print('Messages count: ${sortedMessages.length}');
                for (int i = 0; i < sortedMessages.length; i++) {
                  final msg = sortedMessages[i];
                  final timestamp = _parseTimestamp(msg['timestamp']);
                  print('Message $i: ${msg['text'] ?? msg['type']} - ${timestamp?.toString() ?? 'no timestamp'}');
                }
                
                // Auto-scroll to bottom when new messages arrive (messages are now sorted oldest to newest)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && sortedMessages.isNotEmpty) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: sortedMessages.length,
                  reverse: false, // Ensure messages display from top to bottom (oldest to newest)
                  itemBuilder: (context, i) {
                    final m = sortedMessages[i];
                    final isMe = m['sender'] == 'staff';
                    final timestamp = m['timestamp'];
                    final DateTime? messageTime = _parseTimestamp(timestamp);
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: isMe ? () => _showMessageOptions(m) : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xff1d7df7) : const Color(0xffeef0f5),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              _messageContent(isMe, m),
                              if (messageTime != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(messageTime),
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : Colors.black54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_showAttachmentBar)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 8),
              child: Row(
                children: [
                  _attachmentButton(Icons.image, () => _pickFromGallery()),
                  const SizedBox(width: 12),
                  _attachmentButton(Icons.camera_alt, () => _captureFromCamera()),
                  const SizedBox(width: 12),
                  _attachmentButton(Icons.insert_drive_file, () => _pickFile()),
                ],
              ),
            ),
          _inputBar(),
        ],
      ),
    );
    // Wrap with DropTarget for desktop platforms
    return DropTarget(
      onDragDone: (details) async {
        for (final item in details.files) {
          // desktop_drop gives XFile-like objects with path
          final path = item.path;
          if (path == null) continue;
          final file = File(path);
          final ext = path.split('.').last.toLowerCase();
          final mime = _fileService.getMimeTypeFromExtension(ext);
          final name = path.split('/').last.split('\\').last;
          final bool asImage = mime.startsWith('image/');
          await _saveAndSend(file, fileName: name, mimeType: mime, asImage: asImage);
        }
      },
      child: content,
    );
  }

  Widget _messageContent(bool isMe, Map<String, dynamic> m) {
    final type = (m['type'] ?? 'text') as String;
    print('Rendering message type: $type, data: $m');
    
    if (type == 'text') {
      return Text(
        m['text'] ?? '',
        style: TextStyle(color: isMe ? Colors.white : Colors.black87),
      );
    }
    if (type == 'image') {
      final localPath = m['localPath'] as String?;
      if (localPath != null) {
        return GestureDetector(
          onTap: () async {
            // Open image in external app
            try {
              await OpenFile.open(localPath);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cannot open image: $e')),
                );
              }
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidget(localPath),
          ),
        );
      }
      return Container(
        width: 180,
        height: 180,
        color: Colors.grey[300],
        child: const Icon(Icons.error),
      );
    }
    // default to file tile preview
    final localPath = m['localPath'] as String?;
    final fileName = m['fileName'] as String?;
    final mimeType = m['mimeType'] as String?;
    
    return InkWell(
      onTap: () async {
        if (localPath != null) {
          // Check if it's a PDF file
          if (mimeType == 'application/pdf' || (fileName?.toLowerCase().endsWith('.pdf') ?? false)) {
            await _showPdfPreview(localPath, fileName ?? 'Document');
          } else {
            // For other files, try to open them
            try {
              await OpenFile.open(localPath);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cannot open file: $e')),
                );
              }
            }
          }
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            mimeType == 'application/pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: Text(
              fileName ?? 'Attachment',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String localPath) {
    // Check if it's an asset path (starts with /assets/)
    if (localPath.startsWith('/assets/')) {
      // Remove the leading slash for asset path
      final assetPath = localPath.substring(1);
      return Image.asset(
        assetPath,
        width: 180,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Asset image load error: $error for path: $assetPath');
          return Container(
            width: 180,
            height: 180,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
        },
      );
    } else {
      // It's a file path, use Image.file
      return Image.file(
        File(localPath),
        width: 180,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('File image load error: $error for path: $localPath');
          return Container(
            width: 180,
            height: 180,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
        },
      );
    }
  }

  Widget _attachmentButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black54),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon),
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _showAttachmentBar = !_showAttachmentBar),
              icon: const Icon(Icons.add_circle_outline),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "You're the bes",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24)), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _sendText,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _crm.sendTextMessage(customerId: widget.customerId, sender: 'staff', text: text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      print('Timestamp is null');
      return null;
    }
    
    if (timestamp is Timestamp) {
      // Firestore Timestamp
      final date = timestamp.toDate();
      print('Parsed Firestore Timestamp: $date');
      return date;
    } else if (timestamp is String) {
      // String timestamp
      final date = DateTime.tryParse(timestamp);
      print('Parsed String Timestamp: $date');
      return date;
    } else if (timestamp is DateTime) {
      // Already a DateTime
      print('Already DateTime: $timestamp');
      return timestamp;
    }
    
    print('Unknown timestamp type: ${timestamp.runtimeType}');
    return null;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      // Today: show time only
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days: show date and time
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _showMessageOptions(Map<String, dynamic> message) async {
    final messageId = message['id'] as String?;
    if (messageId == null) return;

    final type = message['type'] as String?;
    final isFile = type == 'file' || type == 'image';

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Message'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(messageId);
              },
            ),
            if (isFile) ...[
              ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text('Download File'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadFile(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _crm.deleteMessage(widget.customerId, messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete message: $e')),
        );
      }
    }
  }

  Future<void> _showPdfPreview(String localPath, String fileName) async {
    // For now, we'll show a simple preview dialog
    // In a real app, you might want to use a PDF viewer package
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fileName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('PDF Document: $fileName'),
            const SizedBox(height: 8),
            Text('Path: $localPath'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _downloadFile({'localPath': localPath, 'fileName': fileName});
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await OpenFile.open(localPath);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cannot open PDF: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(Map<String, dynamic> message) async {
    try {
      final localPath = message['localPath'] as String?;
      final fileName = message['fileName'] as String?;
      
      if (localPath == null || fileName == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File not found')),
          );
        }
        return;
      }

      // Check if file exists
      final file = File(localPath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File not found on device')),
          );
        }
        return;
      }

      // Try to get the app's documents directory instead of Downloads
      // This doesn't require special permissions
      Directory? appDir;
      try {
        appDir = await getApplicationDocumentsDirectory();
      } catch (e) {
        // Fallback to temporary directory
        appDir = await getTemporaryDirectory();
      }

      if (appDir == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot access app directory')),
          );
        }
        return;
      }

      // Create a Downloads subfolder in the app directory
      final downloadsDir = Directory(path.join(appDir.path, 'Downloads'));
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final destinationPath = path.join(downloadsDir.path, fileName);
      await file.copy(destinationPath);

      if (mounted) {
        // Show success notification with more details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ File Downloaded Successfully!'),
                Text('📁 Location: App Documents/Downloads/$fileName'),
                Text('📊 Size: ${(await file.length() / 1024).toStringAsFixed(1)} KB'),
              ],
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open File',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  await OpenFile.open(destinationPath);
                } catch (e) {
                  print('Cannot open file: $e');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to download file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (file == null) return;
      
      setState(() => _showAttachmentBar = false);
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving image...')),
      );
      
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await _saveAndSendBytes(bytes, fileName: file.name, mimeType: 'image/jpeg', asImage: true);
      } else {
        await _saveAndSend(File(file.path), mimeType: 'image/jpeg', asImage: true);
      }
      
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image sent successfully!')),
            );
            _scrollToBottom();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save image: $e')),
            );
          }
        }
      }

      Future<void> _pickFromGallery() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      
      setState(() => _showAttachmentBar = false);
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving image...')),
      );
      
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await _saveAndSendBytes(bytes, fileName: file.name, mimeType: 'image/jpeg', asImage: true);
      } else {
        await _saveAndSend(File(file.path), mimeType: 'image/jpeg', asImage: true);
      }
      
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image sent successfully!')),
            );
            _scrollToBottom();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save image: $e')),
            );
          }
        }
      }

      Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: kIsWeb, // Use bytes on web, path on mobile
        type: FileType.custom, 
        allowedExtensions: ['pdf', 'docx']
      );
      if (result == null || result.files.isEmpty) return;
      
      final f = result.files.first;
      
      setState(() => _showAttachmentBar = false);
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving file...')),
      );
      
      // Get mime type from file extension since PlatformFile.mimeType might not be available
      final extension = f.extension?.toLowerCase() ?? '';
      final mimeType = _fileService.getMimeTypeFromExtension(extension);
      
      if (kIsWeb && f.bytes != null) {
        await _saveAndSendBytes(f.bytes!, fileName: f.name, mimeType: mimeType, asImage: false);
      } else if (!kIsWeb && f.path != null) {
        await _saveAndSend(File(f.path!), fileName: f.name, mimeType: mimeType, asImage: false);
      } else {
        throw Exception('Unable to read file data');
      }
      
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File sent successfully!')),
            );
            _scrollToBottom();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save file: $e')),
            );
          }
        }
      }

  Future<void> _saveAndSend(File file, {String? fileName, required String mimeType, required bool asImage}) async {
    try {
      final name = fileName ?? file.uri.pathSegments.last;
      final bytes = await file.readAsBytes();
      
      print('Saving file: $name, type: $mimeType, asImage: $asImage');
      
      // Save file to local storage
      final localPath = await _fileService.saveFile(
        customerId: widget.customerId,
        fileName: name,
        fileData: bytes,
      );
      
      print('File saved successfully, local path: $localPath');
      
      // Send message to Firestore with local path
      await _crm.sendAttachmentMessage(
        customerId: widget.customerId,
        sender: 'staff',
        localPath: localPath,
        fileName: name,
        mimeType: mimeType,
        messageType: asImage ? 'image' : 'file',
      );
      
      print('Message saved to Firestore successfully');
    } catch (e) {
      print('Save error: $e');
      rethrow;
    }
  }

  Future<void> _saveAndSendBytes(Uint8List bytes, {required String fileName, required String mimeType, required bool asImage}) async {
    try {
      print('Saving bytes: $fileName, type: $mimeType, asImage: $asImage');
      
      // Save bytes to local storage
      final localPath = await _fileService.saveFile(
        customerId: widget.customerId,
        fileName: fileName,
        fileData: bytes,
      );
      
      print('Bytes saved successfully, local path: $localPath');
      
      // Send message to Firestore with local path
      await _crm.sendAttachmentMessage(
        customerId: widget.customerId,
        sender: 'staff',
        localPath: localPath,
        fileName: fileName,
        mimeType: mimeType,
        messageType: asImage ? 'image' : 'file',
      );
      
      print('Message saved to Firestore successfully');
    } catch (e) {
      print('Save error: $e');
      rethrow;
    }
  }
}


