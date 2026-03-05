import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 饮食图片服务
class MealImageService {
  static final MealImageService _instance = MealImageService._internal();
  factory MealImageService() => _instance;
  MealImageService._internal();
  
  final ImagePicker _picker = ImagePicker();
  
  /// 选择图片（拍照或相册）
  Future<String?> pickAndCompressImage() async {
    try {
      // 弹出选择对话框
      final source = await _showSourceDialog();
      if (source == null) return null;
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,  // 最大宽度 1024px
        maxHeight: 1024, // 最大高度 1024px
        imageQuality: 70, // 压缩质量 70%
      );
      
      if (pickedFile == null) return null;
      
      // 压缩并保存到应用目录
      return await saveCompressedImage(pickedFile);
    } catch (e) {
      debugPrint('选择图片失败: $e');
      return null;
    }
  }
  
  /// 选择图片来源
  Future<ImageSource?> _showSourceDialog() async {
    // 这里返回默认来源，实际使用时可以通过参数指定
    return ImageSource.gallery;
  }
  
  /// 压缩并保存图片（供外部调用）
  Future<String?> saveCompressedImage(XFile file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'meal_images'));
      
      // 创建图片目录
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // 生成唯一文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = p.extension(file.path).toLowerCase();
      final fileName = 'meal_$timestamp$extension';
      final savedPath = p.join(imagesDir.path, fileName);
      
      // 复制文件（image_picker 已经做了压缩）
      await File(file.path).copy(savedPath);
      
      debugPrint('图片已保存: $savedPath');
      return savedPath;
    } catch (e) {
      debugPrint('保存图片失败: $e');
      return null;
    }
  }
  
  /// 清理超过一个月的图片
  Future<int> cleanupOldImages() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'meal_images'));
      
      if (!await imagesDir.exists()) {
        return 0;
      }
      
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      int deletedCount = 0;
      
      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          // 检查文件修改时间
          if (stat.modified.isBefore(oneMonthAgo)) {
            await entity.delete();
            deletedCount++;
            debugPrint('删除旧图片: ${entity.path}');
          }
        }
      }
      
      debugPrint('共清理 $deletedCount 张旧图片');
      return deletedCount;
    } catch (e) {
      debugPrint('清理旧图片失败: $e');
      return 0;
    }
  }
  
  /// 删除指定图片
  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('已删除图片: $imagePath');
      }
    } catch (e) {
      debugPrint('删除图片失败: $e');
    }
  }
  
  /// 获取图片文件（如果存在）
  File? getImageFile(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    final file = File(imagePath);
    if (file.existsSync()) {
      return file;
    }
    return null;
  }
}
