import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class KhatmDuaScreen extends StatefulWidget {
  const KhatmDuaScreen({super.key});

  @override
  State<KhatmDuaScreen> createState() => _KhatmDuaScreenState();
}

class _KhatmDuaScreenState extends State<KhatmDuaScreen> {
  double _fontSize = 22.0;

  static const List<String> _duaLines = [
    'اللهم ارحمني بالقرآن، واجعله لي إمامًا ونورًا وهدى ورحمة.',
    'اللهم ذكّرني منه ما نسيت، وعلّمني منه ما جهلت، وارزقني تلاوته آناء الليل وأطراف النهار على الوجه الذي يرضيك عني.',
    'اللهم اجعل القرآن العظيم ربيع قلبي، ونور صدري، وجلاء حزني، وذهاب همّي.',
    'اللهم اجعله حجة لنا لا علينا، وارزقنا العمل بما فيه، واجعلنا من أهل القرآن الذين هم أهلك وخاصتك.',
    'اللهم أصلح لي ديني الذي هو عصمة أمري، وأصلح لي دنياي التي فيها معاشي، وأصلح لي آخرتي التي فيها معادي، واجعل الحياة زيادة لي في كل خير، واجعل الموت راحة لي من كل شر.',
    'اللهم اجعل خير عمري آخره، وخير عملي خواتمه، وخير أيامي يوم ألقاك فيه.',
    'اللهم إني أسألك عيشة هنية، وميتة سوية، ومردًا غير مخزٍ ولا فاضح.',
    'اللهم إني أسألك خير المسألة، وخير الدعاء، وخير النجاح، وخير العلم، وخير العمل، وخير الثواب، وخير الحياة، وخير الممات، وثبتني وثقل موازيني، وحقق إيماني، وارفع درجاتي، وتقبل صلاتي، واغفر خطيئاتي، وأسألك الدرجات العلى من الجنة.',
    'اللهم لا تدع لنا ذنبًا إلا غفرته، ولا همًا إلا فرجته، ولا دينًا إلا قضيته، ولا حاجة من حوائج الدنيا والآخرة إلا قضيتها يا أرحم الراحمين.',
    'اللهم تقبل ختمتنا، واغفر لنا ولوالدينا ولجميع موتى المسلمين، الأحياء منهم والأموات.',
    'اللهم انفعنا وارفعنا بالقرآن العظيم، واجعله شفيعًا لنا وشاهدًا لنا يوم القيامة.',
    'وصلِّ اللهم وسلم وبارك على عبدك ونبيك سيدنا محمد، وعلى آله وصحبه أجمعين، والحمد لله رب العالمين.',
  ];

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color darkGreen = Color(0xFF1B4332);

  void _copyAllDua(BuildContext context) {
    final fullText = _duaLines.join('\n\n');
    Clipboard.setData(ClipboardData(text: fullText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ دعاء ختم القرآن بنجاح',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFFBF8F1),
        appBar: AppBar(
          backgroundColor: isDark
              ? const Color(0xFF121212)
              : const Color(0xFFFBF8F1),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'دعاء ختم المصحف الشريف',
            style: GoogleFonts.cairo(
              color: isDark ? primaryGold : darkGreen,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'نسخ الدعاء',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () => _copyAllDua(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // Quick Font Size Slider Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.format_size_rounded, color: primaryGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'حجم الخط',
                    style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 18.0,
                      max: 32.0,
                      divisions: 7,
                      activeColor: primaryGold,
                      inactiveColor: isDark ? Colors.grey[800] : Colors.grey[300],
                      onChanged: (val) {
                        setState(() {
                          _fontSize = val;
                        });
                      },
                    ),
                  ),
                  Text(
                    '${_fontSize.toInt()}',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: primaryGold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Ornate Manuscript Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF242424), const Color(0xFF1A1A1A)]
                            : [const Color(0xFFFFFDF7), const Color(0xFFF7F2E4)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: primaryGold.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGold.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '۞',
                              style: TextStyle(
                                color: primaryGold,
                                fontSize: 24,
                                fontFamily: 'Amiri',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'دُعَاءُ خَتْمِ القُرْآنِ الكَرِيمِ',
                              style: GoogleFonts.amiri(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryGold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '۞',
                              style: TextStyle(
                                color: primaryGold,
                                fontSize: 24,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryGold.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                            style: TextStyle(
                              fontFamily: 'UthmanicHafs',
                              fontSize: 19,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Dua items in decorated cards
                  ..._duaLines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final line = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : primaryGold.withValues(alpha: 0.22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(top: 4, left: 12),
                            decoration: BoxDecoration(
                              color: primaryGold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryGold.withValues(alpha: 0.5),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? primaryGold : darkGreen,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              line,
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: _fontSize,
                                height: 1.85,
                                color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
