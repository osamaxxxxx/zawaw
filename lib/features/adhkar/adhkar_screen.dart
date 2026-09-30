import 'package:flutter/material.dart';

/// This Mushaf-style font supports Arabic diacritics consistently throughout
/// the adhkar experience.
const _adhkarFontFamily = 'UthmanicHafs';

String _toArabicNumerals(int number) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var result = number.toString();
  for (var index = 0; index < english.length; index++) {
    result = result.replaceAll(english[index], arabic[index]);
  }
  return result;
}

/// Turns the old ۝ separators into readable numbered ayah markers. Each
/// paragraph is a separate surah, so numbering restarts after a blank line.
String _withNumberedAyahs(String text, {int firstAyahNumber = 1}) {
  if (!text.contains('۝')) return text;

  return text
      .split('\n\n')
      .map((paragraph) {
        var normalized = paragraph.trim();
        if (normalized.startsWith('( ')) normalized = normalized.substring(2);
        if (normalized.endsWith(' )')) {
          normalized = normalized.substring(0, normalized.length - 2);
        }

        final ayahs = normalized
            .split('۝')
            .map((ayah) => ayah.trim())
            .where((ayah) => ayah.isNotEmpty)
            .toList();
        return ayahs
            .asMap()
            .entries
            .map(
              (entry) =>
                  '${entry.value} ﴿${_toArabicNumerals(firstAyahNumber + entry.key)}﴾',
            )
            .join(' ');
      })
      .join('\n\n');
}

class AdhkarScreen extends StatefulWidget {
  final int? initialCategoryIndex;
  const AdhkarScreen({super.key, this.initialCategoryIndex});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryIndex != null) {
      final index = widget.initialCategoryIndex!;
      if (index >= 0 && index < AdhkarData.categories.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AdhkarReaderScreen(category: AdhkarData.categories[index]),
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const categories = AdhkarData.categories;
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(
          context,
        ).textTheme.apply(fontFamily: _adhkarFontFamily),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('الأذكار والأدعية')),
          body: ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _AdhkarCategoryCard(category: category);
            },
          ),
        ),
      ),
    );
  }
}

class _AdhkarCategoryCard extends StatelessWidget {
  final AdhkarCategory category;

  const _AdhkarCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdhkarReaderScreen(category: category),
          ),
        );
      },
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
          border: Border(
            right: BorderSide(color: category.colors.first, width: 5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: category.colors.first.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                color: category.colors.first,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.title,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 19),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.items.length} أذكار',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: category.colors.first,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class AdhkarReaderScreen extends StatefulWidget {
  final AdhkarCategory category;

  const AdhkarReaderScreen({super.key, required this.category});

  @override
  State<AdhkarReaderScreen> createState() => _AdhkarReaderScreenState();
}

class _AdhkarReaderScreenState extends State<AdhkarReaderScreen> {
  int _index = 0;
  late int _remainingCount = widget.category.items.first.count;
  bool _isAutoAdvancing = false;

  void _goToNext() {
    if (!mounted) return;
    final isLast = _index == widget.category.items.length - 1;
    if (isLast) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _index++;
      _remainingCount = widget.category.items[_index].count;
      _isAutoAdvancing = false;
    });
  }

  void _goToPrevious() {
    if (!mounted || _index == 0) return;
    setState(() {
      _index--;
      _remainingCount = widget.category.items[_index].count;
      _isAutoAdvancing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.category.items[_index];
    final isLast = _index == widget.category.items.length - 1;
    final primaryColor = widget.category.colors.first;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(
          context,
        ).textTheme.apply(fontFamily: _adhkarFontFamily),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: Text(widget.category.title), centerTitle: true),
          body: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: (_index + 1) / widget.category.items.length,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 14),
                Text(
                  'الذكر ${_toArabicNumbers(_index + 1)} من أصل ${_toArabicNumbers(widget.category.items.length)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: Text(
                                  item.displayText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: _adhkarFontFamily,
                                    fontSize: 24,
                                    height: 2.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (item.note != null) ...[
                            const Divider(height: 24),
                            Text(
                              item.note!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: 0.75),
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: _DhikrCounter(
                      total: item.count,
                      remaining: _remainingCount,
                      primaryColor: primaryColor,
                      onTap: () {
                        if (_remainingCount <= 0 || _isAutoAdvancing) return;
                        setState(() {
                          _remainingCount--;
                        });
                        if (_remainingCount == 0) {
                          _isAutoAdvancing = true;
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (mounted && _isAutoAdvancing) {
                              _goToNext();
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
                // Navigation Buttons: Previous and Next
                Row(
                  children: [
                    if (_index > 0)
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: _goToPrevious,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text(
                            'السابق',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (_index > 0) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _goToNext,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? 'إنهاء الأذكار' : 'التالي',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _toArabicNumbers(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = number.toString();
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }
}

class _DhikrCounter extends StatelessWidget {
  final int total;
  final int remaining;
  final VoidCallback onTap;
  final Color primaryColor;

  const _DhikrCounter({
    required this.total,
    required this.remaining,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final completed = total - remaining;
    final progress = total == 0 ? 0.0 : completed / total;
    final isDone = remaining == 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isDone ? 'اكتمل التكرار ✓' : 'المتبقي $remaining من أصل $total',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDone ? Colors.green : primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? Colors.green.withValues(alpha: 0.1)
                  : primaryColor.withValues(alpha: 0.08),
              border: Border.all(
                color: (isDone ? Colors.green : primaryColor).withValues(
                  alpha: 0.3,
                ),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDone ? Colors.green : primaryColor).withValues(
                    alpha: 0.12,
                  ),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? Colors.green : primaryColor,
                    ),
                    backgroundColor: (isDone ? Colors.green : primaryColor)
                        .withValues(alpha: 0.15),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDone
                            ? Colors.green
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      child: Text('$remaining'),
                    ),
                    Text(
                      isDone ? 'أحسنت' : 'اضغط للعد',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDone ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AdhkarCategory {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final List<AdhkarItem> items;

  const AdhkarCategory({
    required this.title,
    required this.icon,
    required this.colors,
    required this.items,
  });
}

class AdhkarItem {
  final String text;
  final int count;
  final String? note;
  final int firstAyahNumber;

  const AdhkarItem({
    required this.text,
    this.count = 1,
    this.note,
    this.firstAyahNumber = 1,
  });

  String get displayText =>
      _withNumberedAyahs(text, firstAyahNumber: firstAyahNumber);
}

class AdhkarData {
  static const categories = [
    AdhkarCategory(
      title: 'أذكار الصباح',
      icon: Icons.wb_sunny_outlined,
      colors: [Color(0xFF1FB6FF), Color(0xFF0052A3)],
      items: [
        AdhkarItem(
          text:
              'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.',
          note:
              'سيد الاستغفار — من قالها موقناً بها حين يصبح فمات من يومه دخل الجنة.',
        ),
        AdhkarItem(
          text:
              '( اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ )',
          note: 'آية الكرسي — من قرأها حين يصبح أُجير من الجن حتى يمسي.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ )',
          count: 3,
          note: 'سورة الإخلاص (٣ مرات) — تكفي من كل شيء.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ )',
          count: 3,
          note: 'سورة الفلق (٣ مرات) — تكفي من كل شيء.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَـٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ )',
          count: 3,
          note: 'سورة الناس (٣ مرات) — تكفي من كل شيء.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ.',
        ),
        AdhkarItem(
          text:
              'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا.',
          count: 3,
          note:
              'من قالها ثلاثاً حين يصبح كان حقاً على الله أن يرضيه يوم القيامة.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ إِنِّي أَصْبَحْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ.',
          count: 4,
          note: 'من قالها حين يصبح ٤ مرات أعتقه الله من النار.',
        ),
        AdhkarItem(
          text:
              'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ.',
          count: 7,
          note: 'من قالها ٧ مرات كفاه الله ما أهمه من أمر الدنيا والآخرة.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.',
          count: 3,
          note: 'لم يضره شيء.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَهَ إِلَّا أَنْتَ.',
          count: 3,
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ وَمِنْ خَلْفِي وَعَنْ يَمِينِي وَعَنْ شِمَالِي وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي.',
        ),
        AdhkarItem(
          text:
              'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.',
        ),
        AdhkarItem(
          text:
              'أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ.',
        ),
        AdhkarItem(
          text:
              'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ.',
          count: 3,
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا.',
        ),
        AdhkarItem(
          text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.',
          count: 100,
          note: 'حُطت خطاياه وإن كانت مثل زبد البحر.',
        ),
        AdhkarItem(
          text:
              'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
          count: 100,
          note:
              'كانت له عدل عشر رقاب وكُتبت له مائة حسنة ومُحيت عنه مائة سيئة.',
        ),
        AdhkarItem(
          text: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ.',
          count: 100,
        ),
      ],
    ),
    AdhkarCategory(
      title: 'أذكار المساء',
      icon: Icons.nights_stay_outlined,
      colors: [Color(0xFF6A1B9A), Color(0xFF210047)],
      items: [
        AdhkarItem(
          text:
              'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.',
          note:
              'سيد الاستغفار — من قالها موقناً بها حين يمسي فمات من ليلته دخل الجنة.',
        ),
        AdhkarItem(
          text:
              '( اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ )',
          note: 'آية الكرسي — من قرأها حين يمسي أُجير من الجن حتى يصبح.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ )',
          count: 3,
          note: 'سورة الإخلاص (٣ مرات) — تكفي من كل شيء.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ )',
          count: 3,
          note: 'سورة الفلق (٣ مرات) — تكفي من كل شيء.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَـٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ )',
          count: 3,
          note: 'سورة الناس (٣ مرات) — تكفي من كل شيء.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ.',
        ),
        AdhkarItem(
          text:
              'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.',
          count: 3,
          note: 'لم يضره شيء في تلك الليلة.',
        ),
        AdhkarItem(
          text:
              'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا.',
          count: 3,
          note: 'كان حقاً على الله أن يرضيه يوم القيامة.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ.',
          count: 4,
          note: 'من قالها ٤ مرات حين يمسي أعتقه الله من النار.',
        ),
        AdhkarItem(
          text:
              'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ.',
          count: 7,
          note: 'كفاه الله ما أهمه من أمر الدنيا والآخرة.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.',
          count: 3,
          note: 'لم يضره شيء.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَهَ إِلَّا أَنْتَ.',
          count: 3,
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ وَمِنْ خَلْفِي وَعَنْ يَمِينِي وَعَنْ شِمَالِي وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي.',
        ),
        AdhkarItem(
          text:
              'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.',
        ),
        AdhkarItem(
          text:
              'أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ.',
        ),
        AdhkarItem(text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.', count: 100),
        AdhkarItem(
          text:
              'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
          count: 100,
        ),
        AdhkarItem(
          text: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ.',
          count: 10,
          note:
              'من صلى عليّ حين يصبح عشراً وحين يمسي عشراً أدركته شفاعتي يوم القيامة.',
        ),
      ],
    ),
    AdhkarCategory(
      title: 'أذكار النوم',
      icon: Icons.bedtime_outlined,
      colors: [Color(0xFFB5179E), Color(0xFF560BAD)],
      items: [
        AdhkarItem(text: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا.'),
        AdhkarItem(
          text:
              'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ.',
          note: 'إذا أخذت مضجعك وتوفيت من ليلتك مت على الفطرة.',
        ),
        AdhkarItem(
          text: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ.',
          count: 3,
        ),
        AdhkarItem(
          text:
              '( اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ )',
          note:
              'آية الكرسي قبل النوم — لن يزال عليك من الله حافظ ولا يقربك شيطان حتى تصبح.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ )\n\nبِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ )\n\nبِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَـٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ )',
          count: 3,
          note:
              'تُقرأ المعوذات ٣ مرات مع النفث في الكفين ومسح ما استطاع من الجسد.',
        ),
        AdhkarItem(
          text:
              '( آمَنَ الرَّسُولُ بِمَا أُنزِلَ إِلَيْهِ مِن رَّبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِّن رُّسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ ۝ لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنتَ مَوْلَانَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ )',
          firstAyahNumber: 285,
          note: 'الآيتان من آخر سورة البقرة — من قرأهما في ليلة كفتاه.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ يَا أَيُّهَا الْكَافِرُونَ ۝ لَا أَعْبُدُ مَا تَعْبُدُونَ ۝ وَلَا أَنتُمْ عَابِدُونَ مَا أَعْبُدُ ۝ وَلَا أَنَا عَابِدٌ مَّا عَبَدتُّمْ ۝ وَلَا أَنتُمْ عَابِدُونَ مَا أَعْبُدُ ۝ لَكُمْ دِينُكُمْ وَلِيَ دِينِ )',
          note: 'سورة الكافرون — براءة من الشرك.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ ۝ الَّذِي خَلَقَ الْمَوْتَ وَالْحَيَاةَ لِيَبْلُوَكُمْ أَيُّكُمْ أَحْسَنُ عَمَلًا ۚ وَهُوَ الْعَزِيزُ الْغَفُورُ )',
          note: 'سورة الملك — آيات من بدايتها.',
        ),
        AdhkarItem(
          text:
              'سُبْحَانَ اللَّهِ (٣٣)، وَالْحَمْدُ لِلَّهِ (٣٣)، وَاللَّهُ أَكْبَرُ (٣٤).',
          note: 'التسبيح قبل النوم خير من خادم.',
        ),
        AdhkarItem(
          text:
              'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا، وَكَفَانَا وَآوَانَا، فَكَمْ مِمَّنْ لَا كَافِيَ لَهُ وَلَا مُؤْوِيَ.',
        ),
        AdhkarItem(
          text:
              'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ.',
          count: 3,
        ),
      ],
    ),
    AdhkarCategory(
      title: 'بعد الصلاة',
      icon: Icons.mosque_outlined,
      colors: [Color(0xFF20BF55), Color(0xFF0B6623)],
      items: [
        AdhkarItem(text: 'أَسْتَغْفِرُ اللَّهَ.', count: 3),
        AdhkarItem(
          text:
              'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.',
        ),
        AdhkarItem(
          text:
              'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ.',
        ),
        AdhkarItem(
          text:
              'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَلَا نَعْبُدُ إِلَّا إِيَّاهُ، لَهُ النِّعْمَةُ وَلَهُ الْفَضْلُ وَلَهُ الثَّنَاءُ الْحَسَنُ، لَا إِلَهَ إِلَّا اللَّهُ مُخْلِصِينَ لَهُ الدِّينَ وَلَوْ كَرِهَ الْكَافِرُونَ.',
        ),
        AdhkarItem(
          text:
              'سُبْحَانَ اللَّهِ (٣٣)، وَالْحَمْدُ لِلَّهِ (٣٣)، وَاللَّهُ أَكْبَرُ (٣٣).',
          note:
              'ثم تمام المائة: لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
        ),
        AdhkarItem(
          text:
              '( اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ )',
          note:
              'آية الكرسي دبر كل صلاة مكتوبة — لم يمنعه من دخول الجنة إلا أن يموت.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ )\n\nبِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ )\n\nبِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n( قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَـٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ )',
          note:
              'تُقرأ المعوذات مرة بعد كل صلاة، وثلاث مرات بعد صلاتي الفجر والمغرب.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ.',
        ),
      ],
    ),
    AdhkarCategory(
      title: 'الاستيقاظ',
      icon: Icons.wb_twilight_outlined,
      colors: [Color(0xFF22C1C3), Color(0xFF0B7189)],
      items: [
        AdhkarItem(
          text:
              'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ.',
        ),
        AdhkarItem(
          text:
              'الْحَمْدُ لِلَّهِ الَّذِي عَافَانِي فِي جَسَدِي، وَرَدَّ عَلَيَّ رُوحِي، وَأَذِنَ لِي بِذِكْرِهِ.',
        ),
        AdhkarItem(
          text:
              'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ، رَبِّ اغْفِرْ لِي.',
          note:
              'دعاء الاستيقاظ والتعارّ من الليل — غُفر له فإن دعا استُجيب له.',
        ),
      ],
    ),
    AdhkarCategory(
      title: 'أذكار المسجد',
      icon: Icons.account_balance_outlined,
      colors: [Color(0xFFFF7B00), Color(0xFFC2410C)],
      items: [
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى رَسُولِ اللَّهِ، اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ.',
          note: 'دعاء دخول المسجد بالقدم اليمنى.',
        ),
        AdhkarItem(
          text:
              'أَعُوذُ بِاللَّهِ الْعَظِيمِ، وَبِوَجْهِهِ الْكَرِيمِ، وَسُلْطَانِهِ الْقَدِيمِ، مِنَ الشَّيْطَانِ الرَّجِيمِ.',
          note: 'عند دخول المسجد.',
        ),
        AdhkarItem(
          text:
              'بِسْمِ اللَّهِ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى رَسُولِ اللَّهِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ، اللَّهُمَّ اعْصِمْنِي مِنَ الشَّيْطَانِ الرَّجِيمِ.',
          note: 'دعاء الخروج من المسجد بالقدم اليسرى.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا، وَفِي لِسَانِي نُورًا، وَفِي سَمْعِي نُورًا، وَفِي بَصَرِي نُورًا، وَمِنْ فَوْقِي نُورًا، وَمِنْ تَحْتِي نُورًا، وَعَنْ يَمِينِي نُورًا، وَعَنْ شِمَالِي نُورًا، وَمِنْ أَمَامِي نُورًا، وَمِنْ خَلْفِي نُورًا، وَاجْعَلْ لِي نُورًا.',
          note: 'دعاء الذهاب إلى المسجد.',
        ),
      ],
    ),
    AdhkarCategory(
      title: 'أدعية قرآنية',
      icon: Icons.menu_book_outlined,
      colors: [Color(0xFFF9C80E), Color(0xFF9A6700)],
      items: [
        AdhkarItem(
          text:
              '( رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ )',
        ),
        AdhkarItem(
          text:
              '( رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنتَ مَوْلَانَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ )',
        ),
        AdhkarItem(
          text:
              '( رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ )',
        ),
        AdhkarItem(
          text:
              '( رَبِّ اشْرَحْ لِي صَدْرِي ۝ وَيَسِّرْ لِي أَمْرِي ۝ وَاحْلُلْ عُقْدَةً مِّن لِّسَانِي ۝ يَفْقَهُوا قَوْلِي )',
        ),
        AdhkarItem(
          text:
              '( رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا )',
        ),
        AdhkarItem(text: '( رَّبِّ زِدْنِي عِلْمًا )'),
        AdhkarItem(
          text:
              '( رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً ۚ إِنَّكَ أَنتَ الْوَهَّابُ )',
        ),
        AdhkarItem(
          text:
              '( رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِن ذُرِّيَّتِي ۚ رَبَّنَا وَتَقَبَّلْ دُعَاءِ ۝ رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ )',
        ),
        AdhkarItem(
          text:
              '( رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَىٰ وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ وَأَدْخِلْنِي بِرَحْمَتِكَ فِي عِبَادِكَ الصَّالِحِينَ )',
        ),
        AdhkarItem(
          text:
              '( لَّا إِلَـٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ )',
        ),
      ],
    ),
    AdhkarCategory(
      title: 'أدعية مأثورة',
      icon: Icons.auto_awesome_outlined,
      colors: [Color(0xFF7AC70C), Color(0xFF2B7A0B)],
      items: [
        AdhkarItem(
          text: 'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ، وَغَلَبَةِ الرِّجَالِ.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي، وَاجْعَلِ الْحَيَاةَ زِيَادَةً لِي فِي كُلِّ خَيْرٍ، وَاجْعَلِ الْمَوْتَ رَاحَةً لِي مِنْ كُلِّ شَرٍّ.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ زَوَالِ نِعْمَتِكَ، وَتَحَوُّلِ عَافِيَتِكَ، وَفُجَاءَةِ نِقْمَتِكَ، وَجَمِيعِ سَخَطِكَ.',
        ),
        AdhkarItem(
          text:
              'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا.',
        ),
      ],
    ),
    AdhkarCategory(
      title: 'تسابيح واستغفار',
      icon: Icons.wb_sunny_rounded,
      colors: [Color(0xFF00897B), Color(0xFF00695C)],
      items: [
        AdhkarItem(text: 'سُبْحَانَ اللَّهِ.', count: 33),
        AdhkarItem(text: 'الْحَمْدُ لِلَّهِ.', count: 33),
        AdhkarItem(text: 'اللَّهُ أَكْبَرُ.', count: 34),
        AdhkarItem(
          text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ.',
          count: 100,
        ),
        AdhkarItem(
          text:
              'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ.',
          count: 100,
        ),
        AdhkarItem(
          text: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ.',
          count: 100,
        ),
        AdhkarItem(
          text: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ.',
          count: 100,
        ),
      ],
    ),
  ];
}
