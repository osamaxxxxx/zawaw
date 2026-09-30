import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  int _rating = 5;
  bool _sending = false;

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color darkGreen = Color(0xFF1B4332);
  static const String contactEmail = 'shoosh2003m@gmail.com';

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _formatFeedbackBody() {
    final name = _nameController.text.trim();
    final message = _messageController.text.trim();
    final stars = '⭐' * _rating;

    return 'تقييم تطبيق تلاوات الشيخ عبدالرحمن الزواوي:\n'
        'التقييم: $stars ($_rating من 5)\n'
        '${name.isNotEmpty ? "الاسم: $name\n" : ""}\n'
        'الملاحظات والاقتراحات:\n'
        '${message.isEmpty ? "تطبيق رائع ومميز، جزاكم الله خيرًا." : message}';
  }

  Future<void> _sendFeedback() async {
    setState(() => _sending = true);
    final uri = Uri(
      scheme: 'mailto',
      path: contactEmail,
      queryParameters: {
        'subject': 'رأي مستخدم في تطبيق الزواوي — $_rating/5',
        'body': _formatFeedbackBody(),
      },
    );

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched && mounted) {
        _messageController.clear();
        _nameController.clear();
        setState(() {
          _rating = 5;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم فتح تطبيق البريد لإرسال ملاحظاتكم، جزاكم الله خيرًا!',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: darkGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر فتح تطبيق البريد تلقائيًا. يُرجى مراسلتنا على: $contactEmail',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'يرجى إرسال رسالتكم مباشرة إلى: $contactEmail',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFBF8F1),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFBF8F1),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'شاركنا رأيك ومقترحاتك',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? primaryGold : darkGreen,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1E1E), const Color(0xFF161616)]
                      : [Colors.white, const Color(0xFFFAF7EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: primaryGold.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.email_rounded, color: primaryGold, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'رأيكم يهمنا ويسعدنا دائماً',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تصل رسائلكم مباشرة إلى فريق التطوير لتحسين تجربة الاستخدام وإضافة الميزات المطلوبة.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rating Stars
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white10 : primaryGold.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'كيف تقيّم تجربتك مع التطبيق؟',
                    style: GoogleFonts.cairo(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        iconSize: 36,
                        tooltip: '$value من 5',
                        onPressed: () => setState(() => _rating = value),
                        icon: Icon(
                          value <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: primaryGold,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Text Inputs
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white10 : primaryGold.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الاسم (اختياري)',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.cairo(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'اكتب اسمك الكريم...',
                      hintStyle: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF282828) : const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'اكتب رأيك أو اقتراحك بالتفصيل',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _messageController,
                    minLines: 4,
                    maxLines: 7,
                    style: GoogleFonts.cairo(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'ما الميزات التي تقترح إضافتها؟ وما الذي يمكننا تحسينه؟',
                      hintStyle: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF282828) : const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Send via Email Button
            FilledButton.icon(
              onPressed: _sending ? null : _sendFeedback,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              label: Text(
                'إرسال الرأي عبر البريد الإلكتروني',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'سيتم فتح تطبيق البريد لديك برسالة مجهزة تلقائيًا إلى:\n$contactEmail',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
