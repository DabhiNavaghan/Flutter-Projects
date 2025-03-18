
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Player Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: YoutubePlayerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class YoutubePlayerScreen extends StatefulWidget {
  @override
  _YoutubePlayerScreenState createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  // Sample YouTube video ID - you can change this
  final String videoId = 'dQw4w9WgXcQ';
  late YoutubePlayerController _controller;
  bool _isMuted = false;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: _isMuted,
        disableDragSeek: false,
        loop: false,
        enableCaption: true,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted) {
        _controller.mute();
      } else {
        _controller.unMute();
      }
    });
  }

  void _enterFullScreen() {
    // Store current playback time
    final currentTime = _controller.value.position.inSeconds;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenPage(
          videoId: videoId,
          startSeconds: currentTime,
          isMuted: _isMuted,
          onExitFullscreen: (seconds, isMute) {
            Future.delayed(Duration(milliseconds: 500), () {
              _controller.load(videoId, startAt: seconds);
              if (isMute != _isMuted) {
                _isMuted = isMute;
                isMute ? _controller.mute() : _controller.unMute();
              }
              _controller.play();
            });
          },
        ),
      ),
    );

    // Pause the current player
    _controller.pause();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('YouTube Player'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
              progressColors: ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
              ),
              onReady: () {
                _isPlayerReady = true;
              },
            ),
            builder: (context, player) {
              return Column(
                children: [
                  player,
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isPlayerReady ? _toggleMute : null,
                          icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                          label: Text(_isMuted ? 'Unmute' : 'Mute'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isPlayerReady ? _enterFullScreen : null,
                          icon: Icon(Icons.fullscreen),
                          label: Text('Fullscreen'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Video Player Example',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class FullscreenPage extends StatefulWidget {
  final String videoId;
  final int startSeconds;
  final bool isMuted;
  final Function(int, bool) onExitFullscreen;

  const FullscreenPage({super.key, required this.videoId, required this.startSeconds, required this.isMuted, required this.onExitFullscreen});

  @override
  _FullscreenPageState createState() => _FullscreenPageState();
}

class _FullscreenPageState extends State<FullscreenPage> {
  late YoutubePlayerController _controller;
  bool _isMuted = false;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.isMuted;

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: _isMuted,
        disableDragSeek: false,
        loop: false,
        enableCaption: true,
        startAt: widget.startSeconds,
      ),
    )..addListener(_listener);

    // Set to landscape mode when entering fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _listener() {
    if (_isPlayerReady && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Callback with current position to resume in main screen
    final currentPosition = _controller.value.position.inSeconds;
    widget.onExitFullscreen(currentPosition, _isMuted);

    // Return to portrait mode when exiting fullscreen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _controller.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted) {
        _controller.mute();
      } else {
        _controller.unMute();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: YoutubePlayerBuilder(
                  player: YoutubePlayer(
                    controller: _controller,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.red,
                    progressColors: ProgressBarColors(
                      playedColor: Colors.red,
                      handleColor: Colors.redAccent,
                    ),
                    onReady: () {
                      _isPlayerReady = true;
                      // Ensure video starts at the correct position
                      if (widget.startSeconds > 0) {
                        _controller.seekTo(Duration(seconds: widget.startSeconds));
                      }
                    },
                  ),
                  builder: (context, player) {
                    return Stack(
                      children: [
                        player,
                        Positioned(
                          top: 10,
                          left: 10,
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton(
                            icon: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: _isPlayerReady ? _toggleMute : null,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
