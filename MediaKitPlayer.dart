import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MediaKitPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const MediaKitPlayerScreen({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<MediaKitPlayerScreen> createState() => _MediaKitPlayerScreenState();
}

class _MediaKitPlayerScreenState extends State<MediaKitPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    try {
      _player = Player();
      _controller = VideoController(_player);

      // Open the media
      await _player.open(Media(widget.videoUrl));

      // Listen for errors
      _player.stream.error.listen((error) {
        setState(() {
          _hasError = true;
          _errorMessage = error;
        });
        debugPrint('Video player error: $error');
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      debugPrint('Error initializing player: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text('Video Player', style: TextStyle(color: Colors.white)),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9, // Default aspect ratio
        child: Video(
          controller: _controller,
          controls: MaterialVideoControls, // Use material design controls
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading video...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            if (widget.thumbnailUrl != null)
              Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 240,
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 240,
                  color: Colors.grey[800],
                  child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


//add these packages
//   media_kit: ^1.2.0
//   media_kit_video: ^1.2.5
//   media_kit_libs_video: ^1.0.5