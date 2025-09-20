import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:desktop_drop/desktop_drop.dart';

import '../../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  const ChatScreen({super.key, required this.customerId, required this.customerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirestoreCrmService _crm = FirestoreCrmService();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _showAttachmentBar = false;

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
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snap.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isMe = m['sender'] == 'staff';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xff1d7df7) : const Color(0xffeef0f5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _messageContent(isMe, m),
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
          final mime = _getMimeTypeFromExtension(ext);
          final name = path.split('/').last.split('\\').last;
          final bool asImage = mime.startsWith('image/');
          await _uploadAndSend(file, fileName: name, mimeType: mime, asImage: asImage);
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
      return GestureDetector(
        onTap: () async {
          final url = Uri.parse(m['url']);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            m['url'],
            width: 180,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Image load error: $error');
              return Container(
                width: 180,
                height: 180,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              );
            },
          ),
        ),
      );
    }
    // default to file tile preview
    return InkWell(
      onTap: () async {
        final url = Uri.parse(m['url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.white),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: Text(
              m['fileName'] ?? 'Attachment',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
  }

  Future<void> _captureFromCamera() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (file == null) return;
      
      setState(() => _showAttachmentBar = false);
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading image...')),
      );
      
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await _uploadAndSendBytes(bytes, fileName: file.name, mimeType: 'image/jpeg', asImage: true);
      } else {
        await _uploadAndSend(File(file.path), mimeType: 'image/jpeg', asImage: true);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
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
        const SnackBar(content: Text('Uploading image...')),
      );
      
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await _uploadAndSendBytes(bytes, fileName: file.name, mimeType: 'image/jpeg', asImage: true);
      } else {
        await _uploadAndSend(File(file.path), mimeType: 'image/jpeg', asImage: true);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: kIsWeb, // Use bytes on web, path on mobile
        type: FileType.custom, 
        allowedExtensions: ['pdf','docx']
      );
      if (result == null || result.files.isEmpty) return;
      
      final f = result.files.first;
      
      setState(() => _showAttachmentBar = false);
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading file...')),
      );
      
      // Get mime type from file extension since PlatformFile.mimeType might not be available
      final extension = f.extension?.toLowerCase() ?? '';
      final mimeType = _getMimeTypeFromExtension(extension);
      
      if (kIsWeb && f.bytes != null) {
        await _uploadAndSendBytes(f.bytes!, fileName: f.name, mimeType: mimeType, asImage: false);
      } else if (!kIsWeb && f.path != null) {
        await _uploadAndSend(File(f.path!), fileName: f.name, mimeType: mimeType, asImage: false);
      } else {
        throw Exception('Unable to read file data');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    }
  }

  String _getMimeTypeFromExtension(String extension) {
    switch (extension) {
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

  Future<void> _uploadAndSend(File file, {String? fileName, required String mimeType, required bool asImage}) async {
    try {
      final name = fileName ?? file.uri.pathSegments.last;
      final ref = FirebaseStorage.instance.ref().child('chat/${widget.customerId}/$name');
      
      print('Uploading file: $name, type: $mimeType, asImage: $asImage');
      
      // Upload file to Firebase Storage
      await ref.putFile(file, SettableMetadata(contentType: mimeType));
      final url = await ref.getDownloadURL();
      
      print('File uploaded successfully, URL: $url');
      
      // Send message to Firestore
      await _crm.sendAttachmentMessage(
        customerId: widget.customerId,
        sender: 'staff',
        url: url,
        fileName: name,
        mimeType: mimeType,
        messageType: asImage ? 'image' : 'file',
      );
      
      print('Message saved to Firestore successfully');
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  Future<void> _uploadAndSendBytes(Uint8List bytes, {required String fileName, required String mimeType, required bool asImage}) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('chat/${widget.customerId}/$fileName');
      
      print('Uploading bytes: $fileName, type: $mimeType, asImage: $asImage');
      
      // Upload bytes to Firebase Storage
      await ref.putData(bytes, SettableMetadata(contentType: mimeType));
      final url = await ref.getDownloadURL();
      
      print('Bytes uploaded successfully, URL: $url');
      
      // Send message to Firestore
      await _crm.sendAttachmentMessage(
        customerId: widget.customerId,
        sender: 'staff',
        url: url,
        fileName: fileName,
        mimeType: mimeType,
        messageType: asImage ? 'image' : 'file',
      );
      
      print('Message saved to Firestore successfully');
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }
}


