import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  static const _items = [
    _GuideItem(
      'المصحف الشريف بين يديك',
      'اضغط على بطاقة «المصحف» من الصفحة الرئيسية لتواصل القراءة من آخر موضع وصلت إليه بتنسيق المصحف الشريف.',
      Icons.menu_book_rounded,
      _PreviewType.home,
    ),
    _GuideItem(
      'الفهرس والبحث بالضغط على اسم السورة',
      'أثناء قراءة المصحف، اضغط مباشرةً على «اسم السورة» في أعلى الصفحة لفتح الفهرس الكامل، والتنقل بين السور والأجزاء، والبحث السريع في الآيات.',
      Icons.manage_search_rounded,
      _PreviewType.readerTools,
    ),
    _GuideItem(
      'التفسير والحفظ والتلاوة',
      'اضغط مطولًا على أي آية لتظهر لك خيارات الاستماع بصوت الشيخ عبدالرحمن الزواوي، قراءة التفسير الميسر، أو حفظ الآية.',
      Icons.auto_stories_rounded,
      _PreviewType.ayah,
    ),
    _GuideItem(
      'مواقيت الصلاة والأذكار',
      'تابع أوقات الصلاة والعد التنازلي للأذان بدقة حسب موقعك، واستمتع بالأذكار اليومية وأدعية الختم.',
      Icons.access_time_filled_rounded,
      _PreviewType.prayer,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);
    const darkGreen = Color(0xFF1B4332);
    final last = _page == _items.length - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFBF8F1),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: goldColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: goldColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'دليل الاستخدام (${_page + 1}/${_items.length})',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? goldColor : darkGreen,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _finishing ? null : _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                      child: Text(
                        'تخطي الشرح',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) =>
                      _GuidePage(item: _items[index]),
                ),
              ),
              // Dots indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _page ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? goldColor
                          : (isDark ? Colors.white24 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: darkGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: goldColor, width: 1.2),
                      ),
                    ),
                    onPressed: _finishing
                        ? null
                        : last
                        ? _finish
                        : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                    child: _finishing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: goldColor,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                last ? 'ابدأ استخدام التطبيق' : 'التالي',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                last
                                    ? Icons.check_circle_rounded
                                    : Icons.arrow_forward_rounded,
                                color: goldColor,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidePage extends StatelessWidget {
  final _GuideItem item;
  const _GuidePage({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);
    const darkGreen = Color(0xFF1B4332);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AppPreview(type: item.preview),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: goldColor, size: 24),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : darkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14.5,
                height: 1.65,
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppPreview extends StatelessWidget {
  final _PreviewType type;
  const _AppPreview({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);

    final body = switch (type) {
      _PreviewType.home => _homePreview(context),
      _PreviewType.readerTools => _toolsPreview(context),
      _PreviewType.ayah => _ayahPreview(context),
      _PreviewType.prayer => _prayerPreview(context),
    };

    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: goldColor.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: body,
    );
  }

  Widget _homePreview(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    const darkGreen = Color(0xFF1B4332);
    return Column(
      children: [
        const _PreviewBar(title: 'تلاوات الشيخ الزواوي'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: goldColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: goldColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'الصلاة القادمة: المغرب • 00:25:40',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _TargetCard(
          label: 'المصحف الشريف',
          subtitle: 'متابعة القراءة من آخر صفحة',
          icon: Icons.menu_book_rounded,
          primary: darkGreen,
        ),
      ],
    );
  }

  Widget _toolsPreview(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    const darkGreen = Color(0xFF1B4332);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top reader bar simulation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : const Color(0xFFF6F2E8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: goldColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Surah Name (Target interactive button)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: goldColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: goldColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'سورة الفاتحة',
                      style: GoogleFonts.amiri(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : darkGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down_rounded, color: goldColor, size: 20),
                  ],
                ),
              ),
              // Bookmark icon
              const Icon(Icons.bookmark_border_rounded, color: goldColor, size: 22),
              // Juz
              Text(
                'الجزء الأول',
                style: GoogleFonts.amiri(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: goldColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Visual indicator pointing to the Surah name
        Row(
          children: [
            const Icon(Icons.north_rounded, color: goldColor, size: 20),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'اضغط هنا لفتح الفهرس والبحث',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? goldColor : darkGreen,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Decorative Quran text representation
        Center(
          child: Column(
            children: [
              Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 21,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ (١)',
                style: TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 18,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Index & Search feature highlights
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: darkGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: darkGreen.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _featureChip(Icons.format_list_bulleted_rounded, 'فهرس السور'),
              _featureChip(Icons.menu_book_rounded, 'فهرس الأجزاء'),
              _featureChip(Icons.search_rounded, 'البحث في الآيات'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureChip(IconData icon, String label) {
    const goldColor = Color(0xFFD4AF37);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: goldColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _ayahPreview(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    const darkGreen = Color(0xFF1B4332);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const _PreviewBar(title: 'المصحف الشريف'),
        const Spacer(),
        const _TargetCard(
          label: 'اضغط مطولًا على أي آية',
          subtitle: 'لعرض الخيارات المتاحة للآية',
          icon: Icons.touch_app_rounded,
          primary: darkGreen,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3EFE6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: goldColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionItem(Icons.play_circle_filled_rounded, 'تلاوة الشيخ'),
              _actionItem(Icons.menu_book_rounded, 'التفسير الميسر'),
              _actionItem(Icons.bookmark_add_rounded, 'حفظ الآية'),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _actionItem(IconData icon, String label) {
    const goldColor = Color(0xFFD4AF37);
    return Row(
      children: [
        Icon(icon, size: 16, color: goldColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _prayerPreview(BuildContext context) {
    const darkGreen = Color(0xFF1B4332);
    return const Column(
      children: [
        _PreviewBar(title: 'الرئيسية والمواقيت'),
        SizedBox(height: 12),
        _TargetCard(
          label: 'مواقيت الصلاة والأذان',
          subtitle: 'حساب دقيق حسب موقعك الحالي تلقائيًا',
          icon: Icons.access_time_rounded,
          primary: darkGreen,
        ),
        SizedBox(height: 12),
        _PlainCard(
          label: 'ويدجت للشاشة الرئيسية للأذكار والآيات',
          icon: Icons.widgets_rounded,
        ),
      ],
    );
  }
}

class _PreviewBar extends StatelessWidget {
  final String title;
  const _PreviewBar({required this.title});
  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    return Row(
      children: [
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: goldColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const Icon(Icons.settings_outlined, size: 18, color: Colors.grey),
      ],
    );
  }
}

class _TargetCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color primary;
  const _TargetCard({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.primary,
  });
  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: goldColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: goldColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainCard extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PlainCard({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PreviewType { home, readerTools, ayah, prayer }

class _GuideItem {
  final String title;
  final String description;
  final IconData icon;
  final _PreviewType preview;
  const _GuideItem(this.title, this.description, this.icon, this.preview);
}
