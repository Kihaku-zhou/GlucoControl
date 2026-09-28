import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/database/database.dart';

/// 以底部弹窗展示单条体测记录的完整详情。
///
/// 值为 null 或空字符串的字段不会渲染；[BodyMeasurement.imagePath] 指向本地
/// 文件时读取并展示缩略图，文件缺失时回退为占位图标。
///
/// [context] 用于定位弹窗的宿主页面；[record] 为待展示的体测记录。
void showBodyMeasurementDetail(BuildContext context, BodyMeasurement record) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _BodyMeasurementDetailSheet(record: record),
  );
}

class _BodyMeasurementDetailSheet extends StatelessWidget {
  const _BodyMeasurementDetailSheet({required this.record});

  final BodyMeasurement record;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年M月d日 HH:mm');
    final imagePath = record.imagePath;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.straighten, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '体测记录详情',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailRow('记录时间', dateFormat.format(record.measuredAt)),
            if (record.weight != null) _DetailRow('体重', '${record.weight} kg'),
            if (record.height != null) _DetailRow('身高', '${record.height} cm'),
            if (record.bmi != null)
              _DetailRow('BMI', record.bmi!.toStringAsFixed(1)),
            if (record.bodyFat != null) _DetailRow('体脂率', '${record.bodyFat}%'),
            if (record.muscleMass != null)
              _DetailRow('肌肉量', '${record.muscleMass} kg'),
            if (record.chest != null) _DetailRow('胸围', '${record.chest} cm'),
            if (record.waist != null) _DetailRow('腰围', '${record.waist} cm'),
            if (record.hip != null) _DetailRow('臀围', '${record.hip} cm'),
            if (record.neck != null) _DetailRow('颈围', '${record.neck} cm'),
            if (record.waistHipRatio != null)
              _DetailRow('腰臀比', record.waistHipRatio!.toStringAsFixed(2)),
            if (imagePath != null && imagePath.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('图片',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.grey, size: 48),
                    ),
                  ),
                ),
              ),
            ],
            if (record.note != null && record.note!.isNotEmpty)
              _DetailRow('备注', record.note!),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child:
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
