import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter_app/features/capture/state/daily_flow_provider.dart';

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
      
      _controller = CameraController(
        _cameras![_currentCameraIndex],
        ResolutionPreset.medium, 
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera Init Error: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    await _controller?.dispose();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) return;
      final image = await _controller!.takePicture();
      if (mounted) setState(() => _image = image);
    } catch (e) {
      debugPrint('Take Photo Error: $e');
    }
  }

  Future<void> _uploadPhoto() async {
    if (_image == null) return;
    setState(() { _isUploading = true; _uploadProgress = 0.0; });
    
    try {
      final dailyFlowProvider = DailyFlowProvider.of(context);
      for (int i = 0; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 15));
        if (mounted) setState(() => _uploadProgress = i / 100);
      }
      dailyFlowProvider.markAsUploaded();
      dailyFlowProvider.markAsMatching();
    } catch (e) {
      debugPrint('Upload Error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyFlowProvider = Provider.of<DailyFlowProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const SizedBox(height: 40), // 保持顶部间距

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double frameWidth = constraints.maxWidth * 0.82;
                final double frameHeight = frameWidth * 1.5; 
                final double photoWidth = frameWidth - 32;
                final double photoHeight = photoWidth * (4 / 3);
                
                return Center(
                  child: _buildPolaroidFrame(
                    width: frameWidth,
                    height: frameHeight,
                    photoWidth: photoWidth,
                    photoHeight: photoHeight,
                  ),
                );
              },
            ),
          ),

          if (_isUploading) _buildProgressBar(),

          _buildControlPanel(dailyFlowProvider),
        ],
      ),
    );
  }



  Widget _buildPolaroidFrame({
    required double width,
    required double height,
    required double photoWidth,
    required double photoHeight,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16), 
          SizedBox(
            width: photoWidth,
            height: photoHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: Container(
                color: Colors.black,
                child: _image == null ? _buildCameraPreview() : _buildTakenImage(),
              ),
            ),
          ),
          const Spacer(),
          if (_image != null)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'MEMORIES // 2026',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.black12,
                  fontWeight: FontWeight.bold
                ),
              ),
            )
          else
            const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_initializeControllerFuture == null) return const SizedBox();
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.previewSize?.height ?? 1080,
              height: _controller!.value.previewSize?.width ?? 1440,
              child: CameraPreview(_controller!),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
      },
    );
  }

  Widget _buildTakenImage() {
    return Image.file(
      File(_image!.path),
      fit: BoxFit.cover,
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              minHeight: 6,
              backgroundColor: Colors.black12,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'UPLOADING ${(_uploadProgress * 100).toInt()}%',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(DailyFlowProvider provider) {
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. 中央主要按鈕
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: _isUploading ? null : (_image != null ? _uploadPhoto : _takePhoto),
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  border: Border.all(color: Colors.black12, width: 4),
                ),
                child: Center(
                  child: _image != null
                      ? const Icon(Icons.check_rounded, size: 40, color: Colors.green)
                      : Text(
                          '${provider.countdown % 60}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
                        ),
                ),
              ),
            ),
          ),

          // 2. 右側按鈕 - 使用更安全的定位方式，防止重疊
          Positioned(
            right: 10, // 縮小邊距
            child: GestureDetector(
              onTap: _isUploading ? null : (_image != null ? () => setState(() => _image = null) : _toggleCamera),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                ),
                child: Icon(
                  _image != null ? Icons.refresh_rounded : Icons.cameraswitch_rounded,
                  color: Colors.black54,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}