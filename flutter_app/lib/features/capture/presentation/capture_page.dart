import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_app/features/capture/state/daily_flow_provider.dart';
import 'package:flutter_app/shared/services/api_service.dart';
import 'package:flutter_app/shared/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // 进入页面时自动调用相机
    _takePhoto();
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _image = photo;
      });
    }
  }

  Future<void> _uploadPhoto() async {
    if (_image == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final dailyFlowProvider = DailyFlowProvider.of(context);

      // 模拟上传进度
      for (int i = 0; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        setState(() {
          _uploadProgress = i / 100;
        });
      }

      // 模拟上传成功
      await Future.delayed(const Duration(seconds: 1));
      
      // 上传成功，更新状态
      dailyFlowProvider.markAsUploaded();
      dailyFlowProvider.markAsMatching();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败：$e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyFlowProvider = Provider.of<DailyFlowProvider>(context);

    return Column(
      children: [
        // 倒计时显示
        Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: Text(
            '${(dailyFlowProvider.countdown ~/ 60).toString().padLeft(2, '0')}:${(dailyFlowProvider.countdown % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ),

        // 拍摄区域
        Expanded(
          child: _image == null
              ? const Center(
                  child: Text('点击下方按钮拍摄照片'),
                )
              : Image.file(
                  File(_image!.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
        ),

        // 操作按钮
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (_isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 10),
                    Text('上传中：${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isUploading ? null : _takePhoto,
                    child: const Text('重新拍摄'),
                  ),
                  ElevatedButton(
                    onPressed: _isUploading || _image == null ? null : _uploadPhoto,
                    child: const Text('上传'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
