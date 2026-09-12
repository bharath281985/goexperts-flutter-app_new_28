import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../app/constants/app_colors.dart';

class NetworkVideoWidget extends StatefulWidget {
  final String videoUrl;
  final BoxFit fit;

  const NetworkVideoWidget({
    super.key,
    required this.videoUrl,
    this.fit = BoxFit.cover,
  });

  @override
  State<NetworkVideoWidget> createState() => _NetworkVideoWidgetState();
}

class _NetworkVideoWidgetState extends State<NetworkVideoWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: AppColors.white,
        child: const Center(
          child: Icon(Icons.error_outline, color: AppColors.danger, size: 40),
        ),
      );
    }
    
    if (!_isInitialized) {
      return Container(
        color: AppColors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.white),
        ),
      );
    }
    
    return FittedBox(
      fit: widget.fit,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
