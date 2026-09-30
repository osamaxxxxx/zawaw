import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/ayah.dart';
import '../../models/surah.dart';
import '../../services/local_quran_service.dart';
import '../../services/tafsir_service.dart';
import '../quran/quran_reader_screen.dart';

enum DailyContentType { ayah, hadith }

class HadithData {
  final String text;
  final String source;
  final String explanation;

  const HadithData({
    required this.text,
    required this.source,
    required this.explanation,
  });
}

class DailyContentScreen extends StatefulWidget {
  final DailyContentType type;
  const DailyContentScreen({super.key, required this.type});

  static const List<HadithData> hadiths = [
    HadithData(
      text: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى.',
      source: 'متفق عليه',
      explanation: 'صلاح الأعمال وقبولها وثوابها مرتبط بإخلاص النية لله وحده في كل قول وعمل.',
    ),
    HadithData(
      text: 'أَحَبُّ الأَعْمَالِ إِلَى اللهِ أَدْوَمُهَا وَإِنْ قَلَّ.',
      source: 'متفق عليه',
      explanation: 'المداومة على الطاعة القليلة والعمل الصالح خير من العمل الكثير المنقطع.',
    ),
    HadithData(
      text: 'خَيْرُكُمْ مَنْ تَعَلَّمَ القُرْآنَ وَعَلَّمَهُ.',
      source: 'رواه البخاري',
      explanation: 'أفضل الناس وأرفعهم قدراً من يعتني بكتاب الله حفظاً وتلاوة وتعلماً وتعليماً.',
    ),
    HadithData(
      text: 'كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي المِيزَانِ، حَبِيبَتَانِ إِلَى الرَّحْمَنِ: سُبْحَانَ اللهِ وَبِحَمْدِهِ، سُبْحَانَ اللهِ العَظِيمِ.',
      source: 'متفق عليه',
      explanation: 'عظيم فضل ذكر الله وتسبيحه وتنزيهه، وأثره الكبير في مضاعفة الحسنات.',
    ),
    HadithData(
      text: 'لَا تَحْقِرَنَّ مِنَ المَعْرُوفِ شَيْئًا، وَلَوْ أَنْ تَلْقَى أَخَاكَ بِوَجْهٍ طَلْقٍ.',
      source: 'رواه مسلم',
      explanation: 'لا تستصغر أي عمل خير تقدمه؛ فلكل إحسان أجر عظيم، حتى طلاقة الوجه والبشاشة.',
    ),
    HadithData(
      text: 'الكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ.',
      source: 'متفق عليه',
      explanation: 'الكلام الحسن، والدعاء، وإدخال السرور على قلوب الناس من أعظم أنواع الصدقات.',
    ),
    HadithData(
      text: 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ.',
      source: 'رواه الترمذي',
      explanation: 'إظهار الود والابتسامة في وجوه الناس عمل يسير يؤجر عليه المؤمن كأجر الصدقة.',
    ),
    HadithData(
      text: 'مَنْ لَا يَرْحَمِ النَّاسَ لَا يَرْحَمْهُ اللهُ.',
      source: 'متفق عليه',
      explanation: 'الرحمة بالخلق والإحسان إليهم سبب رئيسي لاستنزال رحمة الخالق سبحانه وتعالى.',
    ),
    HadithData(
      text: 'المُسْلِمُ مَنْ سَلِمَ المُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ.',
      source: 'متفق عليه',
      explanation: 'كمال الإسلام يتحقق بكف الأذى عن الناس وحفظ اللسان والجوارح عن كل سوء.',
    ),
    HadithData(
      text: 'مَنْ كَانَ يُؤْمِنُ بِاللهِ وَاليَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ.',
      source: 'متفق عليه',
      explanation: 'الحث على ضبط اللسان والكلام بما ينفع ويثمر خيراً، أو لزوم الصمت طلباً للسلامة.',
    ),
    HadithData(
      text: 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا، سَهَّلَ اللهُ لَهُ بِهِ طَرِيقًا إِلَى الجَنَّةِ.',
      source: 'رواه مسلم',
      explanation: 'فضل طلب العلم الشرعي والنافع وأنه من أعظم الأسباب الموصلة لمرضاة الله والجنة.',
    ),
    HadithData(
      text: 'إِنَّ اللهَ رَفِيقٌ يُحِبُّ الرِّفْقَ، وَيُعْطِي عَلَى الرِّفْقِ مَا لَا يُعْطِي عَلَى العُنْفِ.',
      source: 'رواه مسلم',
      explanation: 'الرفق واللين في الأمور كلها يورث البركة والتيسير والقبول.',
    ),
    HadithData(
      text: 'اتَّقِ اللهَ حَيْثُمَا كُنْتَ، وَأَتْبِعِ السَّيِّئَةَ الحَسَنَةَ تَمْحُهَا، وَخَالِقِ النَّاسَ بِخُلُقٍ حَسَنٍ.',
      source: 'رواه الترمذي',
      explanation: 'وصية نبوية جامعة لحسن العلاقة مع الله بالتقوى، ومع النفس بالتوبة، ومع الخلق بالأخلاق.',
    ),
    HadithData(
      text: 'المُؤْمِنُ القَوِيُّ خَيْرٌ وَأَحَبُّ إِلَى اللهِ مِنَ المُؤْمِنِ الضَّعِيفِ، وَفِي كُلٍّ خَيْرٌ.',
      source: 'رواه مسلم',
      explanation: 'قوة الإيمان والعزيمة والعمل النافع والاستعانة بالله أحب إلى الله تعالى.',
    ),
    HadithData(
      text: 'احْفَظِ اللهَ يَحْفَظْكَ، احْفَظِ اللهَ تَجِدْهُ تُجَاهَكَ.',
      source: 'رواه الترمذي',
      explanation: 'من راعى أوامر الله واجتنب نواهيه تولاه الله بالرعاية والتوفيق والحفظ في كل شأنه.',
    ),
    HadithData(
      text: 'عَجَبًا لِأَمْرِ المُؤْمِنِ، إِنَّ أَمْرَهُ كُلَّهُ خَيْرٌ؛ إِنْ أَصَابَتْهُ سَرَّاءُ شَكَرَ فَكَانَ خَيْرًا لَهُ، وَإِنْ أَصَابَتْهُ ضَرَّاءُ صَبَرَ فَكَانَ خَيْرًا لَهُ.',
      source: 'رواه مسلم',
      explanation: 'شأن المؤمن كله بركة؛ فهو يتقلب بين شكر النعم وصبر الابتلاء فينال الأجر في الحالين.',
    ),
    HadithData(
      text: 'الدُّعَاءُ هُوَ العِبَادَةُ.',
      source: 'رواه الترمذي',
      explanation: 'الدعاء جوهر العبادة ومخها لما فيه من تمام التوكل والافتقار إلى الله الغني الحميد.',
    ),
    HadithData(
      text: 'مَنْ صَلَّى عَلَيَّ صَلَاةً صَلَّى اللهُ عَلَيْهِ بِهَا عَشْرًا.',
      source: 'رواه مسلم',
      explanation: 'عظيم بركة وفضل الصلاة على النبي ﷺ في مغفرة الذنوب ومضاعفة الأجور ورفع الدرجات.',
    ),
    HadithData(
      text: 'اليَدُ العُلْيَا خَيْرٌ مِنَ اليَدِ السُّفْلَى.',
      source: 'متفق عليه',
      explanation: 'اليد المنفقة المعطية خير وأفضل من اليد الآخذة السائلة، حثاً على العمل والكرم.',
    ),
    HadithData(
      text: 'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ.',
      source: 'متفق عليه',
      explanation: 'تمام الإيمان وكماله في سلامة الصدر ومحبة الخير والنفع للآخرين كما يحبه لنفسه.',
    ),
    HadithData(
      text: 'مَنْ نَفَّسَ عَنْ مُؤْمِنٍ كُرْبَةً مِنْ كُرَبِ الدُّنْيَا نَفَّسَ اللهُ عَنْهُ كُرْبَةً مِنْ كُرَبِ يَوْمِ القِيَامَةِ.',
      source: 'رواه مسلم',
      explanation: 'الجزاء من جنس العمل، فمن فرج هموم الناس وسعى في كشف ضيقهم فرج الله كروبه يوم القيامة.',
    ),
    HadithData(
      text: 'وَاللهُ فِي عَوْنِ العَبْدِ مَا كَانَ العَبْدُ فِي عَوْنِ أَخِيهِ.',
      source: 'رواه مسلم',
      explanation: 'من أعان إخوانه المسلمين وبذل لهم المساعدة، شمله عون الله وتوفيقه وتيسيره.',
    ),
    HadithData(
      text: 'مَنْ قَرَأَ حَرْفًا مِنْ كِتَابِ اللهِ فَلَهُ بِهِ حَسَنَةٌ، وَالحَسَنَةُ بِعَشْرِ أَمْثَالِهَا.',
      source: 'رواه الترمذي',
      explanation: 'عظيم مضاعفة الأجر والثواب في تلاوة آيات القرآن الكريم وحروفه المباركة.',
    ),
    HadithData(
      text: 'اقْرَؤُوا القُرْآنَ فَإِنَّهُ يَأْتِي يَوْمَ القِيَامَةِ شَفِيعًا لِأَصْحَابِهِ.',
      source: 'رواه مسلم',
      explanation: 'القرآن الكريم يشفع لأهله التالين له المتمسكين به يوم العرض على الله تعالى.',
    ),
    HadithData(
      text: 'الصَّلَاةُ نُورٌ، وَالصَّدَقَةُ بُرْهَانٌ، وَالصَّبْرُ ضِيَاءٌ.',
      source: 'رواه مسلم',
      explanation: 'أنوار الطاعات تضيء دروب المؤمن في الدنيا وتؤنسه في قبره وتنير صراطه يوم القيامة.',
    ),
    HadithData(
      text: 'مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ، وَمَا زَادَ اللهُ عَبْدًا بِعَفْوٍ إِلَّا عِزًّا.',
      source: 'رواه مسلم',
      explanation: 'الصدقة تبارك في المال وتنميه، والعفو عن المسيء يورث صاحبه الرفعة والشرف عند الله.',
    ),
    HadithData(
      text: 'إِنَّ الصِّدْقَ يَهْدِي إِلَى البِرِّ، وَإِنَّ البِرَّ يَهْدِي إِلَى الجَنَّةِ.',
      source: 'متفق عليه',
      explanation: 'التحلي بالصدق في الأقوال والأفعال يفتح أبواب الخير والبر المؤدية إلى الفوز بالجنة.',
    ),
    HadithData(
      text: 'لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الغَضَبِ.',
      source: 'متفق عليه',
      explanation: 'القوة الحقيقية في قوة الإرادة وضبط الانفعالات والحلم عند دواعي الغضب.',
    ),
    HadithData(
      text: 'أَفْشُوا السَّلَامَ، وَأَطْعِمُوا الطَّعَامَ، وَصَلُّوا بِاللَّيْلِ وَالنَّاسُ نِيَامٌ، تَدْخُلُوا الجَنَّةَ بِسَلَامٍ.',
      source: 'رواه الترمذي',
      explanation: 'طرق يسيرة وثوابها عظيم لدخول الجنة: نشر السلام وإطعام المحتاجين وقيام الليل.',
    ),
    HadithData(
      text: 'رِضَا الرَّبِّ فِي رِضَا الوَالِدِ، وَسَخَطُ الرَّبِّ فِي سَخَطِ الوَالِدِ.',
      source: 'رواه الترمذي',
      explanation: 'عظم مكانة بر الوالدين والإحسان إليهما، وأنه من أعظم موجبات رضوان الله تعالى.',
    ),
    HadithData(
      text: 'أَنَا وَكَافِلُ اليَتِيمِ فِي الجَنَّةِ هَكَذَا، وَأَشَارَ بِالسَّبَّابَةِ وَالوُسْطَى.',
      source: 'رواه البخاري',
      explanation: 'عظيم منزلة كافل اليتيم والمنفق عليه ومرافقته للنبي ﷺ في أعلى درجات الجنة.',
    ),
    HadithData(
      text: 'مَنْ أَحَبَّ أَنْ يُبْسَطَ لَهُ فِي رِزْقِهِ، وَيُنْسَأَ لَهُ فِي أَثَرِهِ، فَلْيَصِلْ رَحِمَهُ.',
      source: 'متفق عليه',
      explanation: 'صلة الرحم والإحسان إلى الأقارب سبب لسعة الرزق والبركة في العمر والذكر الطيب.',
    ),
    HadithData(
      text: 'اسْتَوْصُوا بِالنِّسَاءِ خَيْرًا.',
      source: 'متفق عليه',
      explanation: 'الوصية النبوية الجامعة بالإحسان إلى الأهل والنساء ورعايتهن وحسن معاشرتهن بالمعروف.',
    ),
    HadithData(
      text: 'إِنَّ مِنْ أَحَبِّكُمْ إِلَيَّ وَأَقْرَبِكُمْ مِنِّي مَجْلِسًا يَوْمَ القِيَامَةِ أَحَاسِنَكُمْ أَخْلَاقًا.',
      source: 'رواه الترمذي',
      explanation: 'حسن الخلق مع الناس من أعظم أسباب القرب والمحبة من رسول الله ﷺ يوم القيامة.',
    ),
    HadithData(
      text: 'مَنْ غَشَّنَا فَلَيْسَ مِنَّا.',
      source: 'رواه مسلم',
      explanation: 'تحريم الغش والخديعة في البيع والشراء والتعاملات وسائر شؤون الحياة.',
    ),
    HadithData(
      text: 'لَا يَدْخُلُ الجَنَّةَ مَنْ كَانَ فِي قَلْبِهِ مِثْقَالُ ذَرَّةٍ مِنْ كِبْرٍ.',
      source: 'رواه مسلم',
      explanation: 'التحذير الشديد من الكبر والتعالي على الخلق، والحث على التواضع وخفض الجناح.',
    ),
    HadithData(
      text: 'مَنْ تَوَاضَعَ لِلَّهِ رَفَعَهُ.',
      source: 'رواه الطبراني',
      explanation: 'التواضع لله ولعباده يورث العبد الرفعة والشرف والقبول في قلوب الخلق وفي ميزان الحق.',
    ),
    HadithData(
      text: 'إِنَّ اللهَ تَعَالَى طَيِّبٌ لَا يَقْبَلُ إِلَّا طَيِّبًا.',
      source: 'رواه مسلم',
      explanation: 'الحث على طلب الحلال في المأكل والمشرب والعمل الصالح الخالص الذي يقبله الله.',
    ),
    HadithData(
      text: 'دَعْ مَا يَرِيبُكَ إِلَى مَا لَا يَرِيبُكَ.',
      source: 'رواه الترمذي والنسائي',
      explanation: 'قاعدة جليلة في الورع وترك الشبهات واختيار ما تطمئن إليه النفس المؤمنة في دينها.',
    ),
    HadithData(
      text: 'مِنْ حُسْنِ إِسْلَامِ المَرْءِ تَرْكُهُ مَا لَا يَعْنِيهِ.',
      source: 'رواه الترمذي',
      explanation: 'حفظ الوقت ونقاء النفس بالانشغال بما ينفع في الدنيا والآخرة والبعد عن الفضول.',
    ),
    HadithData(
      text: 'أَفْضَلُ الذِّكْرِ لَا إِلَهَ إِلَّا اللهُ، وَأَفْضَلُ الدُّعَاءِ الحَمْدُ لِلَّهِ.',
      source: 'رواه الترمذي',
      explanation: 'عظمة كلمة التوحيد وفضل الثناء على الله وحمده على نعمه الظاهرة والباطنة.',
    ),
    HadithData(
      text: 'مَنْ قَالَ سُبْحَانَ اللهِ وَبِحَمْدِهِ فِي يَوْمٍ مِائَةَ مَرَّةٍ حُطَّتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ البَحْرِ.',
      source: 'متفق عليه',
      explanation: 'سعة مغفرة الله تعالى وفضل الذكر السهل المداوم عليه في محو الذنوب والخطايا.',
    ),
    HadithData(
      text: 'البِرُّ حُسْنُ الخُلُقِ، وَالإِثْمُ مَا حَاكَ فِي نَفْسِكَ وَكَرِهْتَ أَنْ يَطَّلِعَ عَلَيْهِ النَّاسُ.',
      source: 'رواه مسلم',
      explanation: 'البر يجمع كل خصال الخير والأخلاق، والإثم ما قلق منه القلب واستتر به صاحبه.',
    ),
    HadithData(
      text: 'خَيْرُكُمْ خَيْرُكُمْ لِأَهْلِهِ، وَأَنَا خَيْرُكُمْ لِأَهْلِي.',
      source: 'رواه الترمذي',
      explanation: 'حسن الخلق والوفاء يبدأ من البيت والأسرة والإحسان إلى الأهل والأقربين.',
    ),
    HadithData(
      text: 'مَا مِنْ شَيْءٍ أَثْقَلُ فِي مِيزَانِ المُؤْمِنِ يَوْمَ القِيَامَةِ مِنْ حُسْنِ الخُلُقِ.',
      source: 'رواه الترمذي',
      explanation: 'عظيم رجحان كفة حسن الخلق وطيب المعاملة في ميزان العبد يوم الحساب.',
    ),
    HadithData(
      text: 'إِنَّ اللهَ يُحِبُّ إِذَا عَمِلَ أَحَدُكُمْ عَمَلًا أَنْ يُتْقِنَهُ.',
      source: 'رواه البيهقي',
      explanation: 'الحث على الإتقان والإخلاص في كل عمل ومسؤولية دينية أو دنيوية يؤديها المسلم.',
    ),
    HadithData(
      text: 'تَهَادَوْا تَحَابُّوا.',
      source: 'رواه البخاري في الأدب المفرد',
      explanation: 'تبادل الهدايا واللطف ينشر المودة ويزيل الشحناء والضغائن من القلوب.',
    ),
    HadithData(
      text: 'المُؤْمِنُ مِرْآةُ أَخِيهِ، إِذَا رَأَى فِيهَا عَيْبًا أَصْلَحَهُ.',
      source: 'رواه البخاري في الأدب المفرد',
      explanation: 'التناصح بالمعروف والستر والمحبة الصادقة بين المؤمنين لتقويم بعضهم بعضاً.',
    ),
  ];

  @override
  State<DailyContentScreen> createState() => _DailyContentScreenState();
}

class _DailyContentScreenState extends State<DailyContentScreen> {
  final LocalQuranService _quranService = LocalQuranService();
  final TafsirService _tafsirService = TafsirService();
  final Random _random = Random();

  // Quran Ayah State
  List<Surah> _surahs = [];
  List<Ayah> _allAyahs = [];
  Ayah? _currentAyah;
  Surah? _currentSurah;
  String? _currentTafsir;
  bool _isLoadingAyah = true;
  bool _isLoadingTafsir = false;

  // Hadith State
  int _currentHadithIndex = 0;

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color darkGreen = Color(0xFF1B4332);

  @override
  void initState() {
    super.initState();
    if (widget.type == DailyContentType.ayah) {
      _initQuranData();
    } else {
      // Pick hadith based on day of year by default
      final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
      _currentHadithIndex = dayOfYear % DailyContentScreen.hadiths.length;
    }
  }

  Future<void> _initQuranData() async {
    setState(() => _isLoadingAyah = true);
    try {
      final surahs = await _quranService.getSurahs();
      _surahs = surahs;

      final allAyahs = <Ayah>[];
      for (final surah in surahs) {
        final ayahs = await _quranService.getAyahsBySurah(surah.id);
        allAyahs.addAll(ayahs);
      }
      _allAyahs = allAyahs;

      if (_allAyahs.isNotEmpty) {
        _pickRandomAyah();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAyah = false);
    }
  }

  void _pickRandomAyah() {
    if (_allAyahs.isEmpty) return;
    final randomAyah = _allAyahs[_random.nextInt(_allAyahs.length)];
    final surah = _surahs.firstWhere(
      (s) => s.id == randomAyah.surahId,
      orElse: () => _surahs.first,
    );

    setState(() {
      _currentAyah = randomAyah;
      _currentSurah = surah;
      _currentTafsir = null;
      _isLoadingAyah = false;
    });

    _loadTafsirForCurrentAyah(randomAyah.surahId, randomAyah.ayahNumber);
  }

  Future<void> _loadTafsirForCurrentAyah(int surahId, int ayahNumber) async {
    setState(() => _isLoadingTafsir = true);
    try {
      final tafsir = await _tafsirService.getTafsir(
        surahId: surahId,
        ayahNumber: ayahNumber,
      );
      if (mounted && _currentAyah?.surahId == surahId && _currentAyah?.ayahNumber == ayahNumber) {
        setState(() {
          _currentTafsir = tafsir;
          _isLoadingTafsir = false;
        });
      }
    } catch (_) {
      if (mounted && _currentAyah?.surahId == surahId && _currentAyah?.ayahNumber == ayahNumber) {
        setState(() {
          _currentTafsir = 'التفسير متاح عند الاتصال بالإنترنت.';
          _isLoadingTafsir = false;
        });
      }
    }
  }

  void _pickRandomHadith() {
    setState(() {
      int nextIndex;
      do {
        nextIndex = _random.nextInt(DailyContentScreen.hadiths.length);
      } while (nextIndex == _currentHadithIndex && DailyContentScreen.hadiths.length > 1);
      _currentHadithIndex = nextIndex;
    });
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

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        duration: const Duration(seconds: 2),
        backgroundColor: primaryGold,
      ),
    );
  }

  void _shareContent(String text) {
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final isAyah = widget.type == DailyContentType.ayah;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFBF8F1),
        appBar: AppBar(
          title: Text(
            isAyah ? 'آية من القرآن الكريم' : 'حديث نبوي شريف',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: isDark ? primaryGold : darkGreen,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: isAyah ? 'آية أخرى' : 'حديث آخر',
              icon: const Icon(Icons.shuffle_rounded, color: primaryGold),
              onPressed: isAyah ? _pickRandomAyah : _pickRandomHadith,
            ),
          ],
        ),
        body: isAyah ? _buildAyahView(isDark) : _buildHadithView(isDark),
      ),
    );
  }

  Widget _buildAyahView(bool isDark) {
    if (_isLoadingAyah || _currentAyah == null) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGold),
      );
    }

    final ayah = _currentAyah!;
    final surah = _currentSurah;
    final surahName = surah?.nameArabic ?? 'سورة ${ayah.surahId}';
    final pageNumber = ayah.pageNumber;
    final shareText = '\u202B( ${ayah.textUthmani} )\u202C\n[سورة $surahName: ${ayah.ayahNumber}]'
        '${_currentTafsir != null ? '\n\nالتفسير الميسر:\n$_currentTafsir' : ''}\n\nتطبيق الشيخ عبدالرحمن الزواوي';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Main Ayah Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1B2E24), const Color(0xFF132019)]
                    : [Colors.white, const Color(0xFFFAF7F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: primaryGold.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryGold.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'سورة $surahName : الآية ${_toArabicNumbers(ayah.ayahNumber)}',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryGold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'صفحة ${_toArabicNumbers(pageNumber)}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Ayah Text with Quranic Brackets ( ... )
                Text(
                  '\u202B( ${ayah.textUthmani} )\u202C',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 26,
                    height: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: primaryGold, height: 1, thickness: 0.5),
                const SizedBox(height: 16),
                // Tafsir Section
                Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded, color: primaryGold, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'التفسير الميسر',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_isLoadingTafsir)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryGold),
                  )
                else
                  Text(
                    _currentTafsir ?? 'جاري تحميل التفسير...',
                    textAlign: TextAlign.justify,
                    style: GoogleFonts.cairo(
                      fontSize: 14.5,
                      height: 1.8,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuranReaderScreen(
                          initialPage: pageNumber,
                          initialHighlightSurahId: ayah.surahId,
                          initialHighlightAyahNumber: ayah.ayahNumber,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text('فتح في المصحف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: primaryGold,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'نسخ الآية والتفسير',
                icon: const Icon(Icons.copy_rounded, color: primaryGold),
                onPressed: () => _copyToClipboard(shareText, 'تم نسخ الآية والتفسير'),
                style: IconButton.styleFrom(
                  backgroundColor: primaryGold.withValues(alpha: 0.15),
                  padding: const EdgeInsets.all(13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'مشاركة الآية',
                icon: const Icon(Icons.share_rounded, color: primaryGold),
                onPressed: () => _shareContent(shareText),
                style: IconButton.styleFrom(
                  backgroundColor: primaryGold.withValues(alpha: 0.15),
                  padding: const EdgeInsets.all(13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Shuffle Ayah Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickRandomAyah,
              icon: const Icon(Icons.shuffle_rounded, color: primaryGold),
              label: Text(
                'آية عشوائية أخرى',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? primaryGold : darkGreen,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryGold.withValues(alpha: 0.6), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHadithView(bool isDark) {
    final hadith = DailyContentScreen.hadiths[_currentHadithIndex];
    final hadithCount = DailyContentScreen.hadiths.length;
    final shareText = 'قال رسول الله ﷺ:\n«${hadith.text}»\n[${hadith.source}]\n\nالفائدة والشرح:\n${hadith.explanation}\n\nتطبيق الشيخ عبدالرحمن الزواوي';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Main Hadith Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF282318), const Color(0xFF1A170F)]
                    : [Colors.white, const Color(0xFFFAF7F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: primaryGold.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryGold.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        hadith.source,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryGold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'الحديث ${_toArabicNumbers(_currentHadithIndex + 1)} من ${_toArabicNumbers(hadithCount)}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // Hadith Text
                Text(
                  '« ${hadith.text} »',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    height: 1.9,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : darkGreen,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: primaryGold, height: 1, thickness: 0.5),
                const SizedBox(height: 16),
                // Explanation Section
                Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: primaryGold, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'المعنى والفائدة النبوية',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  hadith.explanation,
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    height: 1.8,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickRandomHadith,
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: Text('حديث آخر', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'نسخ الحديث والشرح',
                icon: const Icon(Icons.copy_rounded, color: primaryGold),
                onPressed: () => _copyToClipboard(shareText, 'تم نسخ الحديث والشرح'),
                style: IconButton.styleFrom(
                  backgroundColor: primaryGold.withValues(alpha: 0.15),
                  padding: const EdgeInsets.all(13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'مشاركة الحديث',
                icon: const Icon(Icons.share_rounded, color: primaryGold),
                onPressed: () => _shareContent(shareText),
                style: IconButton.styleFrom(
                  backgroundColor: primaryGold.withValues(alpha: 0.15),
                  padding: const EdgeInsets.all(13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
