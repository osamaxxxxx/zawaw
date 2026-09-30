import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/short_video.dart';
import '../../../services/shorts_service.dart';
import '../../../services/shorts_video_cache_service.dart';

class ShortPlayerWidget extends StatefulWidget {
  final ShortVideo short;
  final bool isActive;

  const ShortPlayerWidget({
    super.key,
    required this.short,
    required this.isActive,
  });

  @override
  State<ShortPlayerWidget> createState() => _ShortPlayerWidgetState();
}

class _ShortPlayerWidgetState extends State<ShortPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = true;
  bool _viewCounted = false;
  final ShortsVideoCacheService _cacheService = ShortsVideoCacheService();

  static const Color primaryGold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final cachedFile = await _cacheService.getCachedFile(widget.short.videoUrl);
      if (!mounted) return;

      _controller = cachedFile == null
          ? VideoPlayerController.networkUrl(Uri.parse(widget.short.videoUrl))
          : VideoPlayerController.file(cachedFile);

      if (cachedFile == null) {
        unawaited(_cacheService.cacheVideo(widget.short.videoUrl));
      }

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        if (widget.isActive) {
          await _controller!.setLooping(true);
          await _controller!.play();
          _incrementViewCount();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
      debugPrint('Error initializing video: $e');
    }
  }

  void _incrementViewCount() {
    if (!_viewCounted) {
      _viewCounted = true;
      ShortsService().incrementViews(widget.short.id);
    }
  }

  @override
  void didUpdateWidget(ShortPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller?.setLooping(true);
        _controller?.play();
        setState(() => _isPlaying = true);
        _incrementViewCount();
      } else {
        _controller?.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  void _shareVideo() {
    Share.share(
      'شاهد هذا الفيديو: ${widget.short.title}\n${widget.short.videoUrl}',
      subject: widget.short.title,
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          if (_isInitialized && !_hasError)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ في تحميل الفيديو',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: primaryGold),
            ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Play/Pause indicator
          if (!_isPlaying && _isInitialized)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

          // Right side actions
          Positioned(
            left: 16,
            bottom: 100,
            child: Column(
              children: [
                // Share button
                _ActionButton(
                  icon: Icons.share,
                  label: 'مشاركة',
                  onTap: _shareVideo,
                ),
                const SizedBox(height: 24),

                // Views
                _ActionButton(
                  icon: Icons.remove_red_eye_outlined,
                  label: _formatViews(widget.short.viewsCount),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Bottom info
          Positioned(
            right: 16,
            left: 80,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                if (widget.short.categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryGold.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.short.categoryName!,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Title
                Text(
                  widget.short.title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 28),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
