import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

class FileService {
  static const String _attachmentsDir = 'attachments';
  static const int _maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> _allowedExtensions = [
    'pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'gif'
  ];
  
  late Directory? _attachmentsDirectory;
  final _uuid = const Uuid();

  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // Web platform - no local directory needed
        print('File service initialized for web');
        return;
      }
      
      // Mobile platforms
      final appDocDir = await getApplicationDocumentsDirectory();
      _attachmentsDirectory = Directory(path.join(appDocDir.path, _attachmentsDir));
      
      if (!await _attachmentsDirectory!.exists()) {
        await _attachmentsDirectory!.create(recursive: true);
      }
      
      print('File service initialized for mobile');
    } catch (e) {
      print('Error initializing file service: $e');
    }
  }

  // Pick files from device
  Future<List<FilePickerResult>> pickFiles({
    bool allowMultiple = true,
    List<String> allowedExtensions = const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'gif'],
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        // maxFileSize parameter removed in newer versions
      );
      
      if (result != null) {
        return [result];
      }
      return [];
    } catch (e) {
      print('Error picking files: $e');
      return [];
    }
  }

  // Save file to local storage
  Future<String?> saveFileToLocal(PlatformFile platformFile) async {
    try {
      if (platformFile.bytes == null) return null;
      
      if (kIsWeb) {
        // For web, we'll store the file in memory or use a different approach
        // For now, return a web-compatible identifier
        return 'web_file_${_uuid.v4()}_${platformFile.name}';
      }
      
      // Mobile platforms
      final fileName = '${_uuid.v4()}_${platformFile.name}';
      final filePath = path.join(_attachmentsDirectory!.path, fileName);
      final file = File(filePath);
      
      await file.writeAsBytes(platformFile.bytes!);
      print('File saved locally: $filePath');
      
      return filePath;
    } catch (e) {
      print('Error saving file: $e');
      return null;
    }
  }

  // Generate thumbnail for image files
  Future<String?> generateThumbnail(String filePath) async {
    try {
      if (kIsWeb) {
        // Web platform - no thumbnail generation for now
        return null;
      }
      
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      final extension = path.extension(filePath).toLowerCase();
      if (!['.jpg', '.jpeg', '.png', '.gif'].contains(extension)) return null;
      
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;
      
      // Resize to thumbnail size
      final thumbnail = img.copyResize(image, width: 150, height: 150);
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);
      
      final thumbnailName = 'thumb_${path.basename(filePath)}';
      final thumbnailPath = path.join(_attachmentsDirectory!.path, thumbnailName);
      final thumbnailFile = File(thumbnailPath);
      
      await thumbnailFile.writeAsBytes(thumbnailBytes);
      print('Thumbnail generated: $thumbnailPath');
      
      return thumbnailPath;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  // Get file preview data
  Future<FilePreviewData?> getFilePreview(String filePath) async {
    try {
      if (kIsWeb) {
        // Web platform - return basic file info
        final fileName = path.basename(filePath);
        return FilePreviewData(
          filePath: filePath,
          fileName: fileName,
          fileSize: 0, // Size not available on web
          fileType: LocalFileType.other,
          thumbnailPath: null,
        );
      }
      
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      final extension = path.extension(filePath).toLowerCase();
      final fileName = path.basename(filePath);
      final fileSize = await file.length();
      
      // Determine file type
      LocalFileType fileType;
      String? thumbnailPath;
      
      if (['.jpg', '.jpeg', '.png', '.gif'].contains(extension)) {
        fileType = LocalFileType.image;
        thumbnailPath = await generateThumbnail(filePath);
      } else if (extension == '.pdf') {
        fileType = LocalFileType.pdf;
      } else if (['.doc', '.docx'].contains(extension)) {
        fileType = LocalFileType.document;
      } else {
        fileType = LocalFileType.other;
      }
      
      return FilePreviewData(
        filePath: filePath,
        fileName: fileName,
        fileSize: fileSize,
        fileType: fileType,
        thumbnailPath: thumbnailPath,
      );
    } catch (e) {
      print('Error getting file preview: $e');
      return null;
    }
  }

  // Delete file from local storage
  Future<bool> deleteFile(String filePath) async {
    try {
      if (kIsWeb) {
        // Web platform - no local file deletion needed
        return true;
      }
      
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('File deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Get file size in human readable format
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Validate file
  bool isValidFile(PlatformFile file) {
    if (kIsWeb) {
      // Web platform - basic validation
      final extension = path.extension(file.name).toLowerCase().replaceAll('.', '');
      return _allowedExtensions.contains(extension);
    }
    
    if (file.size > _maxFileSize) return false;
    
    final extension = path.extension(file.name).toLowerCase().replaceAll('.', '');
    return _allowedExtensions.contains(extension);
  }

  // Get file icon based on type
  String getFileIcon(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    
    switch (extension) {
      case '.pdf':
        return '📄';
      case '.doc':
      case '.docx':
        return '📝';
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return '🖼️';
      default:
        return '📎';
    }
  }
}

enum LocalFileType { image, pdf, document, other }

class FilePreviewData {
  final String filePath;
  final String fileName;
  final int fileSize;
  final LocalFileType fileType;
  final String? thumbnailPath;

  FilePreviewData({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    this.thumbnailPath,
  });
}
