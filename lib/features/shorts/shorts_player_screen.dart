import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/short_category.dart';
import '../../models/short_video.dart';
import '../../services/shorts_service.dart';
import '../../services/shorts_video_cache_service.dart';
import 'widgets/short_player_widget.dart';

class ShortsPlayerScreen extends StatefulWidget {
  final ShortCategory category;

  const ShortsPlayerScreen({
    super.key,
    required this.category,
  });

  @override
  State<ShortsPlayerScreen> createState() => _ShortsPlayerScreenState();
}

class _ShortsPlayerScreenState extends State<ShortsPlayerScreen> {
  final PageController _pageController = PageController();
  final ShortsService _shortsService = ShortsService();
  final ShortsVideoCacheService _cacheService = ShortsVideoCacheService();

  List<ShortVideo> _shorts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  int _currentApiPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadShorts();
    _pageController.addListener(_onPageChanged);
  }

  Future<void> _loadShorts() async {
    if (!_hasMore || _isLoadingMore) return;

    try {
      setState(() {
        if (_currentApiPage == 1) {
          _isLoading = true;
        } else {
          _isLoadingMore = true;
        }
      });

      final result = await _shortsService.getCategoryShorts(
        categoryId: widget.category.id,
        page: _currentApiPage,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _shorts.addAll(result.items);
          _hasMore = result.hasMore;
          _currentApiPage++;
          _isLoading = false;
          _isLoadingMore = false;
        });
        unawaited(_cacheNextShort());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ في تحميل الفيديوهات',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    }
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() => _currentPage = page);
      unawaited(_cacheNextShort());

      // تحميل المزيد عند الاقتراب من النهاية
      if (page >= _shorts.length - 2 && _hasMore && !_isLoadingMore) {
        _loadShorts();
      }
    }
  }

  Future<void> _cacheNextShort() async {
    final nextIndex = _currentPage + 1;
    if (nextIndex < _shorts.length) {
      await _cacheService.cacheVideo(_shorts[nextIndex].videoUrl);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    if (_shorts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'لا توجد فيديوهات في هذه الفئة',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Player
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _shorts.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _shorts.length) {
                // Loading indicator at the end
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                );
              }

              return ShortPlayerWidget(
                short: _shorts[index],
                isActive: index == _currentPage,
              );
            },
          ),

          // Back button (top right)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
