import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
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
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  XFile? _image;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;
      
      final firstCamera = _cameras![0];
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
      );

      _initializeControllerFuture = _controller!.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;

    try {
      await _controller?.dispose();
      _controller = CameraController(
        _cameras![_currentCameraIndex],
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _controller!.initialize();
      setState(() {});
    } catch (e) {
      print('Error toggling camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      if (_controller == null || _initializeControllerFuture == null) return;
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      setState(() {
        _image = image;
      });
    } catch (e) {
      print('Error taking photo: $e');
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
      for (int i = 0; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        setState(() {
          _uploadProgress = i / 100;
        });
      }
      await Future.delayed(const Duration(seconds: 1));
      dailyFlowProvider.markAsUploaded();
      dailyFlowProvider.markAsMatching();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上傳失敗：$e')),
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
        // 頂部標題和圖標
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.settings, size: 24),
              const Text(
                'ANALOG',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.notifications, size: 24),
            ],
          ),
        ),

        // 拍立得風格的拍攝區域 (比例修正重點)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Center(
              child: AspectRatio(
                aspectRatio: 2 / 3, // 外層白色相框比例
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  // 上、左、右留白，下方留空較多用於呈現拍立得質感
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                  child: Container(
                    color: Colors.black, // 背景黑色，防止加載閃白
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 3 / 4, // 內層實時畫面比例 (4:3 直式)
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: _image == null
                              ? _initializeControllerFuture == null
                                  ? const Center(child: CircularProgressIndicator())
                                  : FutureBuilder<void>(
                                      future: _initializeControllerFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.done) {
                                          return CameraPreview(_controller!);
                                        } else {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                      },
                                    )
                              : Image.file(
                                  File(_image!.path),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 上傳進度條
        if (_isUploading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 8),
                Text('上傳中：${(_uploadProgress * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ),

        // 拍攝按鈕和操作按鈕
        SizedBox(
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. 快門/上傳按鈕 (居中)
              Center(
                child: GestureDetector(
                  onTap: _isUploading
                      ? null
                      : _image != null
                          ? _uploadPhoto
                          : _takePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 3),
                    ),
                    child: Center(
                      child: _image != null
                          ? const Icon(Icons.cloud_upload, size: 32)
                          : Text(
                              '${dailyFlowProvider.countdown % 60}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // 2. 切換/重拍按鈕 (靠右)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 40.0),
                  child: GestureDetector(
                    onTap: _isUploading
                        ? null
                        : _image != null
                            ? () => setState(() => _image = null)
                            : _toggleCamera,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.9),
                        border: Border.all(color: Colors.grey, width: 2),
                      ),
                      child: Center(
                        child: _image != null
                            ? const Icon(Icons.refresh, size: 24)
                            : const Icon(Icons.cameraswitch, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}