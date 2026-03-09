import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 体测图片服务
class BodyImageService {
  static final BodyImageService _instance = BodyImageService._internal();
  factory BodyImageService() => _instance;
  BodyImageService._internal();
  
  final ImagePicker _picker = ImagePicker();
  
  /// 选择图片（拍照或相册）
  Future<String?> pickAndCompressImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      
      if (pickedFile == null) return null;
      
      return await saveCompressedImage(pickedFile);
    } catch (e) {
      debugPrint('选择体测图片失败: $e');
      return null;
    }
  }
  
  /// 拍照
  Future<String?> takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      
      if (pickedFile == null) return null;
      
      return await saveCompressedImage(pickedFile);
    } catch (e) {
      debugPrint('拍照失败: $e');
      return null;
    }
  }
  
  /// 压缩并保存图片
  Future<String?> saveCompressedImage(XFile file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'body_images'));
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = p.extension(file.path).toLowerCase();
      final fileName = 'body_$timestamp$extension';
      final savedPath = p.join(imagesDir.path, fileName);
      
      await File(file.path).copy(savedPath);
      
      debugPrint('体测图片已保存: $savedPath');
      return savedPath;
    } catch (e) {
      debugPrint('保存体测图片失败: $e');
      return null;
    }
  }
  
  /// 删除图片
  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('已删除体测图片: $imagePath');
      }
    } catch (e) {
      debugPrint('删除体测图片失败: $e');
    }
  }
  
  /// 获取图片文件
  File? getImageFile(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    final file = File(imagePath);
    if (file.existsSync()) {
      return file;
    }
    return null;
  }
}
