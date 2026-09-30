import SwiftUI
import WidgetKit

private let appGroup = "group.com.example.zawawyApp"
private let prayersKey = "widget_prayers"
private let savedAyahsKey = "widget_saved_ayahs"
private let dailyAyahKey = "widget_daily_ayah"

// MARK: - Color Palette & Styling
private let goldPrimary = Color(red: 0.96, green: 0.82, blue: 0.44)
private let goldSecondary = Color(red: 0.85, green: 0.70, blue: 0.32)
private let textPrimary = Color.white
private let textSecondary = Color.white.opacity(0.78)
private let textMuted = Color.white.opacity(0.60)

/// Keeps Qur'anic ornamental brackets on the correct visual sides in RTL text.
private func quranicText(_ text: String) -> String {
  "\u{202B}( \(text) )\u{202C}"
}

extension View {
  @ViewBuilder
  func widgetBackground(_ backgroundView: some View) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) {
        backgroundView
      }
    } else {
      background(backgroundView)
    }
  }
}

// MARK: - Common Header
struct ModernWidgetHeader: View {
  let title: String
  let subtitle: String?
  let iconName: String
  let accentColor: Color
  var compact: Bool = false

  var body: some View {
    HStack(alignment: .center, spacing: compact ? 6 : 8) {
      if compact {
        HStack(spacing: 5) {
          Image(systemName: iconName)
            .font(.system(size: 11.5, weight: .bold))
            .foregroundStyle(accentColor)
          Text(title)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(accentColor)
        }
      } else {
        ZStack {
          Circle()
            .fill(accentColor.opacity(0.18))
            .frame(width: 26, height: 26)
          Image(systemName: iconName)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(accentColor)
        }
        Text(title)
          .font(.system(size: 13, weight: .bold, design: .rounded))
          .foregroundStyle(accentColor)
      }

      Spacer(minLength: 4)

      if let subtitle = subtitle, !subtitle.isEmpty {
        Text(subtitle)
          .font(.system(size: compact ? 9.5 : 10, weight: .semibold, design: .rounded))
          .foregroundStyle(.white.opacity(0.95))
          .padding(.horizontal, compact ? 7 : 8)
          .padding(.vertical, compact ? 2.5 : 3.5)
          .background(accentColor.opacity(0.22), in: Capsule())
          .overlay(
            Capsule().stroke(accentColor.opacity(0.4), lineWidth: 0.5)
          )
      }
    }
  }
}

// MARK: - 1. DAILY AYAH WIDGET (آية اليوم مع التفسير والتدبّر)

struct QuranAyahItem {
  let surah: String
  let ayahNumber: Int
  let text: String
  let tafsir: String
}

private let curatedAyahs: [QuranAyahItem] = [
  QuranAyahItem(
    surah: "الفاتحة",
    ayahNumber: 5,
    text: "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ",
    tafsir: "نخصك وحدك بالعبادة، ونستعين بك وحدك في جميع أمورنا."
  ),
  QuranAyahItem(
    surah: "البقرة",
    ayahNumber: 152,
    text: "فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ",
    tafsir: "اذكروا الله بالطاعة والثناء يذكركم بالرحمة والثواب، واشكروا نعمه ولا تجحدوها."
  ),
  QuranAyahItem(
    surah: "البقرة",
    ayahNumber: 186,
    text: "وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ",
    tafsir: "الله قريب من عباده، يسمع تضرعهم ويستجيب لدعائهم إذا أقبلوا عليه مخلصين."
  ),
  QuranAyahItem(
    surah: "البقرة",
    ayahNumber: 255,
    text: "اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ",
    tafsir: "الله الذي لا إله بحق إلا هو، الحي القيوم القائم بتدبير خلقه، لا يلحقه نعاس ولا نوم."
  ),
  QuranAyahItem(
    surah: "البقرة",
    ayahNumber: 286,
    text: "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
    tafsir: "لا يكلف الله أحداً من خلقه إلا بما يطيقه ويقدر عليه رحمة وتيسيراً."
  ),
  QuranAyahItem(
    surah: "آل عمران",
    ayahNumber: 139,
    text: "وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ إِن كُنتُم مُّؤْمِنِينَ",
    tafsir: "لا تضعفوا ولا تستسلموا للحزن، فالعاقبة والنصر والعزة لأهل الإيمان الحق."
  ),
  QuranAyahItem(
    surah: "آل عمران",
    ayahNumber: 173,
    text: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ",
    tafsir: "كفانا الله في كل أمورنا، ونعم المولى والحافظ والوكيل لمن توكل عليه."
  ),
  QuranAyahItem(
    surah: "النساء",
    ayahNumber: 28,
    text: "يُرِيدُ اللَّهُ أَن يُخَفِّفَ عَنكُمْ وَخُلِقَ الْإِنسَانُ ضَعِيفًا",
    tafsir: "من رحمة الله بعباده التيسير والتخفيف في تشريعاته وأحكامه."
  ),
  QuranAyahItem(
    surah: "الأنعام",
    ayahNumber: 17,
    text: "وَإِن يَمْسَسْكَ اللَّهُ بِضُرٍّ فَلَا كَاشِفَ لَهُ إِلَّا هُوَ",
    tafsir: "لا كاشف للضر والشدائد إلا الله وحده، فإليه وحده يفزع العباد."
  ),
  QuranAyahItem(
    surah: "الأعراف",
    ayahNumber: 156,
    text: "وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ",
    tafsir: "رحمة الله وسعت كل المخلوقات، وسيختص بها المؤمنين المتقين."
  ),
  QuranAyahItem(
    surah: "الأنفال",
    ayahNumber: 70,
    text: "إِن يَعْلَمِ اللَّهُ فِي قُلُوبِكُمْ خَيْرًا يُؤْتِكُمْ خَيْرًا",
    tafsir: "من علم الله في قلبه صدق النية ومحبة الخير، آتاه الله فضلاً مضاعفاً."
  ),
  QuranAyahItem(
    surah: "التوبة",
    ayahNumber: 129,
    text: "فَإِن تَوَلَّوْا فَقُلْ حَسْبِيَ اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ",
    tafsir: "كفاني الله ربي متوكلاً عليه في كل أمري، وهو رب العرش العظيم."
  ),
  QuranAyahItem(
    surah: "يونس",
    ayahNumber: 62,
    text: "أَلَا إِنَّ أَوْلِيَاءَ اللَّهِ لَا خَوْفٌ عَلَيْهِمْ وَلَا هُمْ يَحْزَنُونَ",
    tafsir: "أهل الإيمان والتقوى في حفظ الله ورعايته وأمانه في الدنيا والآخرة."
  ),
  QuranAyahItem(
    surah: "هود",
    ayahNumber: 88,
    text: "وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ عَلَيْهِ تَوَكَّلْتُ وَإِلَيْهِ أُنِيبُ",
    tafsir: "التوفيق لكل خير بيد الله وحده، وبالتوكل عليه والإنابة إليه يتحقق المراد."
  ),
  QuranAyahItem(
    surah: "يوسف",
    ayahNumber: 86,
    text: "إِنَّمَا أَشْكُو بَثِّي وَحُزْنِي إِلَى اللَّهِ",
    tafsir: "بث الهموم والشكوى إلى الله وحده مفتاح الفرج وسكينة القلب."
  ),
  QuranAyahItem(
    surah: "يوسف",
    ayahNumber: 87,
    text: "وَلَا تَيْأَسُوا مِن رَّوْحِ اللَّهِ إِنَّهُ لَا يَيْأَسُ مِن رَّوْحِ اللَّهِ إِلَّا الْقَوْمُ الْكَافِرُونَ",
    tafsir: "لا تقطعوا الرجاء في فرج الله وتيسيره مهما اشتدت الكروب."
  ),
  QuranAyahItem(
    surah: "الرعد",
    ayahNumber: 28,
    text: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
    tafsir: "حقيقة طمأنينة القلب وسكينته وانشراح الصدر تكون بذكر الله تعالى وإفراده بالتوحيد."
  ),
  QuranAyahItem(
    surah: "إبراهيم",
    ayahNumber: 7,
    text: "لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ",
    tafsir: "شكر الله على نعمه بالقلب واللسان والعمل سبب لدوام النعم وزيادتها."
  ),
  QuranAyahItem(
    surah: "الحجر",
    ayahNumber: 99,
    text: "وَاعْبُدْ رَبَّكَ حَتَّىٰ يَأْتِيَكَ الْيَقِينُ",
    tafsir: "استمر في عبادة الله وطاعته والتقرب إليه حتى يأتيك الأجل وأنت على الصلاح."
  ),
  QuranAyahItem(
    surah: "النحل",
    ayahNumber: 128,
    text: "إِنَّ اللَّهَ مَعَ الَّذِينَ اتَّقَوْا وَّالَّذِينَ هُم مُّحْسِنُونَ",
    tafsir: "معية الله الخاصة بالتأييد والنصر والتوفيق هي لأهل التقوى والإحسان."
  ),
  QuranAyahItem(
    surah: "الإسراء",
    ayahNumber: 82,
    text: "وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ لِّلْمُؤْمِنِينَ",
    tafsir: "القرآن شفاء للقلوب والأبدان ورحمة وهداية للمؤمنين."
  ),
  QuranAyahItem(
    surah: "الكهف",
    ayahNumber: 10,
    text: "رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا",
    tafsir: "دعاء جامع لطلب الرحمة الخاصة من الله والتوفيق للصواب والرشد في كل أمر."
  ),
  QuranAyahItem(
    surah: "طه",
    ayahNumber: 46,
    text: "قَالَ لَا تَخَافَا إِنَّنِي مَعَكُمَا أَسْمَعُ وَأَرَىٰ",
    tafsir: "معية الله ورعايته تدفع كل خوف وتبث الطمأنينة واليقين في قلوب المؤمنين."
  ),
  QuranAyahItem(
    surah: "طه",
    ayahNumber: 114,
    text: "وَقُل رَّبِّ زِدْنِي عِلْمًا",
    tafsir: "ادعُ الله وسله دائماً الزيادة في العلم النافع بالدين والدنيا."
  ),
  QuranAyahItem(
    surah: "الأنبياء",
    ayahNumber: 87,
    text: "لَّا إِلَـٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ",
    tafsir: "دعاء ذي النون العظيم الذي ينجي الله به المؤمنين من كل ضيق وكرب."
  ),
  QuranAyahItem(
    surah: "الفرقان",
    ayahNumber: 74,
    text: "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا",
    tafsir: "دعاء عباد الرحمن بصلاح الأهل والذرية والسبق في ميادين التقوى والخير."
  ),
  QuranAyahItem(
    surah: "الشعراء",
    ayahNumber: 80,
    text: "وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ",
    tafsir: "يقين المؤمن وتوكله بأن الشفاء والعافية بيد الله وحده لا شريك له."
  ),
  QuranAyahItem(
    surah: "العنكبوت",
    ayahNumber: 69,
    text: "وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا وَإِنَّ اللَّهَ لَمَعَ الْمُحْسِنِينَ",
    tafsir: "من جاهد نفسه في طاعة الله، هداه الله وثبته على صراط الخير والتوفيق."
  ),
  QuranAyahItem(
    surah: "الروم",
    ayahNumber: 60,
    text: "فَاصْبِرْ إِنَّ وَعْدَ اللَّهِ حَقٌّ",
    tafsir: "الصبر واليقين بأن وعد الله بالنصر والفرج واقع لا محالة."
  ),
  QuranAyahItem(
    surah: "الزمر",
    ayahNumber: 53,
    text: "قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ",
    tafsir: "لا تيأسوا من مغفرة الله ورحمته مهما عظمت ذنوبكم، فإن الله يغفر الذنوب جميعاً لمن تاب."
  ),
  QuranAyahItem(
    surah: "غافر",
    ayahNumber: 60,
    text: "وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ",
    tafsir: "أمر الله عباده بالدعاء والتضرع إليه، ووعدهم بإجابة الدعاء وتفريج الهموم."
  ),
  QuranAyahItem(
    surah: "فصلت",
    ayahNumber: 34,
    text: "ادْفَعْ بِالَّتِي هِيَ أَحْسَنُ فَإِذَا الَّذِي بَيْنَكَ وَبَيْنَهُ عَدَاوَةٌ كَأَنَّهُ وَلِيٌّ حَمِيمٌ",
    tafsir: "قابل الإساءة بالإحسان والصفح الجميل، ليتحول العدو إلى صديق حميم مقرب."
  ),
  QuranAyahItem(
    surah: "الشورى",
    ayahNumber: 19,
    text: "اللَّهُ لَطِيفٌ بِعِبَادِهِ يَرْزُقُ مَن يَشَاءُ",
    tafsir: "لطف الله بعباده عظيم يسوق إليهم الخيرات والرحمات من حيث لا يشعرون."
  ),
  QuranAyahItem(
    surah: "الفتح",
    ayahNumber: 4,
    text: "هُوَ الَّذِي أَنزَلَ السَّكِينَةَ فِي قُلُوبِ الْمُؤْمِنِينَ لِيَزْدَادُوا إِيمَانًا مَّعَ إِيمَانِهِمْ",
    tafsir: "السكينة والطمأنينة فضل من الله يثبت به قلوب أوليائه في الشدائد."
  ),
  QuranAyahItem(
    surah: "الحجرات",
    ayahNumber: 10,
    text: "إِنَّمَا الْمُؤْمِنُونَ إِخْوَةٌ فَأَصْلِحُوا بَيْنَ أَخَوَيْكُمْ",
    tafsir: "أخوة الإيمان أسمى الروابط، وتوجب السعي الدائم للصلح والوئام والمحبة."
  ),
  QuranAyahItem(
    surah: "ق",
    ayahNumber: 16,
    text: "وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ الْوَرِيدِ",
    tafsir: "إحاطة علم الله وقدرته وقربه التام من كل نفس وسرها وخواطرها."
  ),
  QuranAyahItem(
    surah: "الذاريات",
    ayahNumber: 22,
    text: "وَفِي السَّمَاءِ رِزْقُكُمْ وَمَا تُوعَدُونَ",
    tafsir: "الأرزاق مقدرة ومكتوبة عند الله في السماء فلا قلق ولا خوف على الرزق."
  ),
  QuranAyahItem(
    surah: "الرحمن",
    ayahNumber: 60,
    text: "هَلْ جَزَاءُ الْإِحْسَانِ إِلَّا الْإِحْسَانُ",
    tafsir: "من أحسن في عبادته وأخلاقه وتعاملاته جازاه الله بأعظم الإحسان والنعيم."
  ),
  QuranAyahItem(
    surah: "الحديد",
    ayahNumber: 4,
    text: "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ",
    tafsir: "علم الله محيط بكم في كل زمان ومكان، يراقب أعمالكم ويسمع سركم ونجواكم."
  ),
  QuranAyahItem(
    surah: "الحشر",
    ayahNumber: 18,
    text: "يَا أَيُّهَا الَّذِينَ آمَنُوا اتَّقُوا اللَّهَ وَلْتَنظُرْ نَفْسٌ مَّا قَدَّمَتْ لِغَدٍ",
    tafsir: "أمر المؤمنين بمحاسبة النفس والاستعداد بالعمل الصالح ليوم المعاد."
  ),
  QuranAyahItem(
    surah: "الطلاق",
    ayahNumber: 2,
    text: "وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا ۝ وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ",
    tafsir: "من خاف الله وعمل بطاعته، جعل له مخرجاً من كل كرب، وساق له الرزق من جهة لا تخطر بباله."
  ),
  QuranAyahItem(
    surah: "الطلاق",
    ayahNumber: 7,
    text: "سَيَجْعَلُ اللَّهُ بَعْدَ عُسْرٍ يُسْرًا",
    tafsir: "وعد الله الأكيد بأن الضيق يتبعه الفرج وأن بعد الشدة اليسر والراحة."
  ),
  QuranAyahItem(
    surah: "الملك",
    ayahNumber: 2,
    text: "الَّذِي خَلَقَ الْمَوْتَ وَالْحَيَاةَ لِيَبْلُوَكُمْ أَيُّكُمْ أَحْسَنُ عَمَلًا",
    tafsir: "الغاية من خلق الحياة والموت اختبار العباد في إخلاص العمل وصوابه."
  ),
  QuranAyahItem(
    surah: "الضحى",
    ayahNumber: 5,
    text: "وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ",
    tafsir: "بشارة نبوية وإيمانية بعطاء الله الجزيل الذي يملأ القلب بالرضا والسرور."
  ),
  QuranAyahItem(
    surah: "الشرح",
    ayahNumber: 6,
    text: "إِنَّ مَعَ الْعُسْرِ يُسْرًا",
    tafsir: "مع كل ضيق ومشقة يأتيك فرج مضاعف وتيسير من الله يمحو الكرب."
  ),
  QuranAyahItem(
    surah: "العصر",
    ayahNumber: 3,
    text: "إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ",
    tafsir: "طريق النجاة والفوز بالإيمان الصادق والعمل الصالح والتناصح بالحق والصبر."
  ),
  QuranAyahItem(
    surah: "الإخلاص",
    ayahNumber: 1,
    text: "قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ",
    tafsir: "إفراد الله بالتوحيد والكمال، وهو السيد المقصود لقضاء كل الحوائج."
  ),
  QuranAyahItem(
    surah: "الناس",
    ayahNumber: 1,
    text: "قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَـٰهِ النَّاسِ",
    tafsir: "الاعتصام واللجوء إلى الله رب العالمين من كل وسواس وشر."
  )
]

struct DailyAyahEntry: TimelineEntry {
  let date: Date
  let surah: String
  let ayahNumber: Int
  let text: String
  let tafsir: String
  let benefit: String
}

private func reflectionForAyah(surah: String, text: String, tafsir: String) -> String {
  if text.contains("نَعْبُدُ") || text.contains("تَوَكَّلْ") || text.contains("نَسْتَعِينُ") || text.contains("تَوْفِيقِي") {
    return "الاستعانة بالله وتفويض الأمر إليه مفتاح كل بركة وتيسير في حياتك."
  } else if text.contains("فَاذْكُرُونِي") || text.contains("بِذِكْرِ اللَّهِ") || text.contains("تَطْمَئِنُّ") {
    return "الذكر قوت القلوب وجلاء الأحزان؛ داوم عليه تنعم بالسكينة وطمأنينة النفس."
  } else if text.contains("قَرِيبٌ") || text.contains("دَعْوَةَ") || text.contains("رَبَّنَا") || text.contains("أَشْكُو") {
    return "الله أقرب إليك من كل أحد، يسمع مناجاتك ويجيب دعاءك، فلا تحزن ولا تيأس."
  } else if text.contains("رَحْمَتِي") || text.contains("يُخَفِّفَ") || text.contains("رَوْحِ اللَّهِ") || text.contains("شِفَاءٌ") {
    return "رحمة الله واسعة تسع كل همومك وكروبك؛ تفاءل بروح الله وفرجه القريب."
  } else if text.contains("شَكَرْتُمْ") || text.contains("وَاشْكُرُوا") {
    return "الشكر يحفظ النعم الموجودة ويجلب النعم المفقودة؛ داوم على الحمد في كل حال."
  } else if text.contains("لَا يُكَلِّفُ") || text.contains("لَا تَخَافَا") || text.contains("وَلَا تَهِنُوا") {
    return "تأكد أن الله لا يحملك فوق طاقتك، ومعيته تدفع كل خوف وتمنحك القوة."
  } else if text.contains("الصَّالِحَاتِ") || text.contains("جَاهَدُوا") || text.contains("اتَّقَوْا") {
    return "اصدق مع الله في عملك وسعيك، وسيفتح لك أبواب التوفيق والهداية."
  } else {
    return "تدبّر هذه الآية الكريمة، واجعلها زاداً لقلبك ومنهجاً لنورك وسلوكك اليوم."
  }
}

struct DailyAyahProvider: TimelineProvider {
  func placeholder(in context: Context) -> DailyAyahEntry {
    let item = curatedAyahs[0]
    return DailyAyahEntry(
      date: Date(),
      surah: item.surah,
      ayahNumber: item.ayahNumber,
      text: item.text,
      tafsir: item.tafsir,
      benefit: "الاستعانة بالله في كل شأن تصرف العجز وتجلب البركة والتوفيق."
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (DailyAyahEntry) -> Void) {
    completion(entry(for: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DailyAyahEntry>) -> Void) {
    let now = Date()
    let entries = (0...8).map {
      entry(for: now.addingTimeInterval(TimeInterval($0 * 4 * 3600)))
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func entry(for date: Date) -> DailyAyahEntry {
    let slot = UInt64(date.timeIntervalSince1970 / (4 * 3600))
    let index = Int((slot &* 1103515245 &+ 12345) % UInt64(curatedAyahs.count))
    let item = curatedAyahs[index]
    let benefit = reflectionForAyah(surah: item.surah, text: item.text, tafsir: item.tafsir)
    return DailyAyahEntry(
      date: date,
      surah: item.surah,
      ayahNumber: item.ayahNumber,
      text: item.text,
      tafsir: item.tafsir,
      benefit: benefit
    )
  }
}

struct DailyAyahWidgetView: View {
  let entry: DailyAyahEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    Group {
      switch family {
      case .systemSmall:
        smallView
      case .systemLarge:
        largeView
      default:
        mediumView
      }
    }
    .widgetURL(URL(string: "zawawy://daily_ayah"))
    .widgetBackground(
      LinearGradient(
        colors: [
          Color(red: 0.04, green: 0.20, blue: 0.15),
          Color(red: 0.02, green: 0.11, blue: 0.08),
          Color(red: 0.01, green: 0.06, blue: 0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .environment(\.layoutDirection, .rightToLeft)
  }

  private var smallView: some View {
    VStack(alignment: .trailing, spacing: 5) {
      ModernWidgetHeader(
        title: "آية وتفسير",
        subtitle: "\(entry.surah)",
        iconName: "book.closed.fill",
        accentColor: goldPrimary,
        compact: true
      )

      Spacer(minLength: 1)

      Text(quranicText(entry.text))
        .font(.system(size: 13.5, weight: .bold, design: .serif))
        .lineLimit(3)
        .multilineTextAlignment(.trailing)
        .foregroundStyle(textPrimary)
        .minimumScaleFactor(0.72)

      Spacer(minLength: 1)

      VStack(alignment: .trailing, spacing: 2) {
        Text("التفسير:")
          .font(.system(size: 8.5, weight: .bold))
          .foregroundStyle(goldPrimary)
        Text(entry.tafsir)
          .font(.system(size: 9.5, weight: .medium, design: .rounded))
          .lineLimit(2)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(textSecondary)
          .minimumScaleFactor(0.75)
      }
      .padding(.horizontal, 7)
      .padding(.vertical, 4)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
    .padding(10)
  }

  private var mediumView: some View {
    VStack(alignment: .trailing, spacing: 6) {
      ModernWidgetHeader(
        title: "آية وتفسير",
        subtitle: "سورة \(entry.surah) • آية \(entry.ayahNumber)",
        iconName: "book.pages.fill",
        accentColor: goldPrimary,
        compact: true
      )

      Text(quranicText(entry.text))
        .font(.system(size: 15, weight: .bold, design: .serif))
        .lineLimit(3)
        .multilineTextAlignment(.trailing)
        .foregroundStyle(textPrimary)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .minimumScaleFactor(0.70)

      Spacer(minLength: 0)

      HStack(alignment: .top, spacing: 6) {
        Image(systemName: "sparkles")
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(goldPrimary)
          .padding(.top, 2)

        VStack(alignment: .trailing, spacing: 2) {
          Text("التفسير الميسر:")
            .font(.system(size: 9.5, weight: .bold))
            .foregroundStyle(goldPrimary)
          Text(entry.tafsir)
            .font(.system(size: 11, weight: .regular, design: .rounded))
            .lineLimit(3)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(textSecondary)
            .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
      }
      .padding(.horizontal, 9)
      .padding(.vertical, 5)
      .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(goldPrimary.opacity(0.18), lineWidth: 0.5)
      )
    }
    .padding(.horizontal, 13)
    .padding(.vertical, 9)
  }

  private var largeView: some View {
    VStack(alignment: .trailing, spacing: 8) {
      ModernWidgetHeader(
        title: "آية وتدبّر",
        subtitle: "سورة \(entry.surah) • الآية \(entry.ayahNumber)",
        iconName: "book.closed.fill",
        accentColor: goldPrimary,
        compact: false
      )

      VStack(spacing: 6) {
        HStack {
          Text("۞")
            .font(.system(size: 11))
            .foregroundStyle(goldPrimary.opacity(0.6))
          Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
            .font(.system(size: 12, weight: .medium, design: .serif))
            .foregroundStyle(goldPrimary.opacity(0.9))
          Text("۞")
            .font(.system(size: 11))
            .foregroundStyle(goldPrimary.opacity(0.6))
        }

        Text(quranicText(entry.text))
          .font(.system(size: 18.5, weight: .bold, design: .serif))
          .lineLimit(5)
          .multilineTextAlignment(.center)
          .foregroundStyle(textPrimary)
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 6)
          .minimumScaleFactor(0.72)
      }
      .padding(.vertical, 9)
      .padding(.horizontal, 8)
      .frame(maxWidth: .infinity)
      .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 13))
      .overlay(
        RoundedRectangle(cornerRadius: 13)
          .stroke(goldPrimary.opacity(0.22), lineWidth: 0.8)
      )

      VStack(alignment: .trailing, spacing: 4) {
        HStack {
          Image(systemName: "character.book.closed.fill")
            .font(.system(size: 10.5))
            .foregroundStyle(goldPrimary)
          Text("التفسير وبيان المعنى")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(goldPrimary)
          Spacer()
        }

        Text(entry.tafsir)
          .font(.system(size: 11.5, weight: .medium, design: .rounded))
          .lineLimit(4)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(textSecondary)
          .lineSpacing(2)
          .minimumScaleFactor(0.78)
      }
      .padding(9)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 11))
      .overlay(
        RoundedRectangle(cornerRadius: 11)
          .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
      )

      VStack(alignment: .trailing, spacing: 4) {
        HStack {
          Image(systemName: "sparkles")
            .font(.system(size: 10.5))
            .foregroundStyle(goldPrimary)
          Text("وقفة وهداية تدبرية")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(goldPrimary)
          Spacer()
        }

        Text(entry.benefit.isEmpty ? "اجعل هذه الآية منهجاً ليومك؛ استشعر معانيها، وتوكّل على الله في سائر أمورك." : entry.benefit)
          .font(.system(size: 11, weight: .regular, design: .rounded))
          .lineLimit(3)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(textSecondary.opacity(0.95))
          .minimumScaleFactor(0.78)
      }
      .padding(8)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .background(goldPrimary.opacity(0.09), in: RoundedRectangle(cornerRadius: 11))
      .overlay(
        RoundedRectangle(cornerRadius: 11)
          .stroke(goldPrimary.opacity(0.22), lineWidth: 0.6)
      )

      Spacer(minLength: 0)

      HStack {
        HStack(spacing: 5) {
          Image(systemName: "arrow.up.left.circle.fill")
            .font(.system(size: 10.5))
            .foregroundStyle(goldPrimary)
          Text("افتح المصحف والاستماع في تطبيق الزواوي")
            .font(.system(size: 9.5, weight: .medium))
            .foregroundStyle(textMuted)
        }
        Spacer()
        Text("مصحف الزواوي")
          .font(.system(size: 9, weight: .semibold))
          .foregroundStyle(goldPrimary.opacity(0.75))
      }
      .padding(.horizontal, 4)
    }
    .padding(13)
  }
}

struct DailyAyahWidget: Widget {
  let kind = "ZawawyDailyAyahWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DailyAyahProvider()) {
      DailyAyahWidgetView(entry: $0)
    }
    .configurationDisplayName("آية اليوم مع التفسير")
    .description("آية قرآنية مختارة مع التفسير الميسر وتدبر معانيها.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

// MARK: - 2. PRAYER TIMES WIDGET (مواقيت الصلاة الفاخر)

struct PrayerItem: Decodable {
  let name: String
  let time: Int64
}

struct PrayerEntry: TimelineEntry {
  let date: Date
  let nextName: String
  let nextTimeFormatted: String
  let nextPrayerDate: Date?
  let allPrayers: [(name: String, time: String, isNext: Bool)]
}

struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry {
    PrayerEntry(
      date: Date(),
      nextName: "الظهر",
      nextTimeFormatted: "١٢:٠٥ م",
      nextPrayerDate: Date().addingTimeInterval(90 * 60),
      allPrayers: [
        ("الفجر", "٤:٣٥ ص", false),
        ("الظهر", "١٢:٠٥ م", true),
        ("العصر", "٣:٢٠ م", false),
        ("المغرب", "٦:٠٥ م", false),
        ("العشاء", "٧:٢٥ م", false)
      ]
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(entry(for: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let now = Date()
    let entries = (0...12).map {
      entry(for: now.addingTimeInterval(TimeInterval($0 * 30 * 60)))
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func entry(for date: Date) -> PrayerEntry {
    let data = UserDefaults(suiteName: appGroup)?.data(forKey: prayersKey)
    let rawPrayers = (try? data.flatMap { try JSONDecoder().decode([PrayerItem].self, from: $0) }) ?? []

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ar")
    formatter.dateFormat = "h:mm a"

    guard let next = rawPrayers.first(where: { Date(timeIntervalSince1970: TimeInterval($0.time) / 1000) > date }) else {
      return PrayerEntry(
        date: date,
        nextName: "المواقيت",
        nextTimeFormatted: "افتح التطبيق",
        nextPrayerDate: nil,
        allPrayers: []
      )
    }

    let nextDate = Date(timeIntervalSince1970: TimeInterval(next.time) / 1000)

    // Filter only main 5 prayers for today
    let mainNames = ["الفجر", "الظهر", "العصر", "المغرب", "العشاء"]
    let calendar = Calendar.current
    let dayPrayers = rawPrayers.filter { prayer in
      let pDate = Date(timeIntervalSince1970: TimeInterval(prayer.time) / 1000)
      return calendar.isDate(pDate, inSameDayAs: date) && mainNames.contains(prayer.name)
    }

    let all = dayPrayers.map { prayer in
      let pDate = Date(timeIntervalSince1970: TimeInterval(prayer.time) / 1000)
      let isNext = prayer.name == next.name && abs(pDate.timeIntervalSince(nextDate)) < 60
      return (name: prayer.name, time: formatter.string(from: pDate), isNext: isNext)
    }

    return PrayerEntry(
      date: date,
      nextName: next.name,
      nextTimeFormatted: formatter.string(from: nextDate),
      nextPrayerDate: nextDate,
      allPrayers: all
    )
  }
}

struct PrayerWidgetView: View {
  let entry: PrayerEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    Group {
      switch family {
      case .systemSmall:
        smallView
      case .systemLarge:
        largeView
      default:
        mediumView
      }
    }
    .widgetURL(URL(string: "zawawy://prayer"))
    .widgetBackground(
      LinearGradient(
        colors: [
          Color(red: 0.05, green: 0.14, blue: 0.22),
          Color(red: 0.02, green: 0.07, blue: 0.14)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .environment(\.layoutDirection, .rightToLeft)
  }

  private var smallView: some View {
    VStack(alignment: .trailing, spacing: 6) {
      ModernWidgetHeader(
        title: "مواقيت الصلاة",
        subtitle: nil,
        iconName: "moon.stars.fill",
        accentColor: goldPrimary
      )

      Spacer(minLength: 2)

      VStack(alignment: .trailing, spacing: 2) {
        Text("الصلاة القادمة")
          .font(.system(size: 10, weight: .medium, design: .rounded))
          .foregroundStyle(textMuted)
        Text(entry.nextName)
          .font(.system(size: 20, weight: .bold, design: .rounded))
          .foregroundStyle(goldPrimary)
        Text(entry.nextTimeFormatted)
          .font(.system(size: 15, weight: .semibold, design: .rounded))
          .foregroundStyle(textPrimary)
      }

      Spacer(minLength: 2)

      HStack {
        VStack(alignment: .leading, spacing: 1) {
          Text("متبقي")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(textMuted)
          if let nextDate = entry.nextPrayerDate {
            Text(nextDate, style: .timer)
              .font(.system(size: 15, weight: .bold, design: .monospaced))
              .foregroundStyle(goldPrimary)
              .monospacedDigit()
          } else {
            Text("—")
              .font(.system(size: 15, weight: .bold))
              .foregroundStyle(.white)
          }
        }
        Spacer()
        Image(systemName: "clock.fill")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(goldPrimary.opacity(0.8))
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
      .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
    }
    .padding(12)
  }

  private var mediumView: some View {
    VStack(alignment: .trailing, spacing: 7) {
      ModernWidgetHeader(
        title: "مواقيت الصلاة",
        subtitle: "الصلاة القادمة: \(entry.nextName)",
        iconName: "moon.stars.fill",
        accentColor: goldPrimary,
        compact: true
      )

      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(entry.nextName)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(goldPrimary)
          Text(entry.nextTimeFormatted)
            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
            .foregroundStyle(textPrimary)
        }
        Spacer()
        if let nextDate = entry.nextPrayerDate {
          HStack(spacing: 5) {
            Image(systemName: "timer")
              .font(.system(size: 14))
              .foregroundStyle(goldPrimary)
            Text(nextDate, style: .timer)
              .font(.system(size: 18, weight: .bold, design: .monospaced))
              .foregroundStyle(goldPrimary)
              .monospacedDigit()
          }
          .padding(.horizontal, 9)
          .padding(.vertical, 4)
          .background(Color.black.opacity(0.20), in: Capsule())
          .overlay(Capsule().stroke(goldPrimary.opacity(0.3), lineWidth: 0.5))
        }
      }

      HStack(spacing: 5) {
        ForEach(Array(entry.allPrayers.enumerated()), id: \.offset) { _, prayer in
          VStack(spacing: 3) {
            Text(prayer.name)
              .font(.system(size: 10, weight: .semibold))
              .lineLimit(1)
              .minimumScaleFactor(0.8)
            Text(prayer.time)
              .font(.system(size: 9.5, weight: .medium, design: .rounded))
              .lineLimit(1)
              .minimumScaleFactor(0.8)
          }
          .foregroundStyle(prayer.isNext ? goldPrimary : textSecondary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 6)
          .background(prayer.isNext ? goldPrimary.opacity(0.18) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(prayer.isNext ? goldPrimary.opacity(0.35) : Color.clear, lineWidth: 0.5)
          )
        }
      }
    }
    .padding(.horizontal, 13)
    .padding(.vertical, 9)
  }

  private var largeView: some View {
    VStack(alignment: .trailing, spacing: 8) {
      ModernWidgetHeader(
        title: "مواقيت الصلاة اليوم",
        subtitle: "الصلاة القادمة: \(entry.nextName)",
        iconName: "moon.stars.fill",
        accentColor: goldPrimary,
        compact: false
      )

      if let nextDate = entry.nextPrayerDate {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text("الوقت المتبقي حتى أذان \(entry.nextName)")
              .font(.system(size: 10.5, weight: .medium))
              .foregroundStyle(textSecondary)
            Text(nextDate, style: .timer)
              .font(.system(size: 24, weight: .bold, design: .monospaced))
              .foregroundStyle(goldPrimary)
              .monospacedDigit()
          }
          Spacer()
          Image(systemName: "bell.badge.fill")
            .font(.system(size: 24))
            .foregroundStyle(goldPrimary)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(goldPrimary.opacity(0.25), lineWidth: 0.8)
        )
      }

      ForEach(Array(entry.allPrayers.enumerated()), id: \.offset) { _, prayer in
        HStack {
          Text(prayer.time)
            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
          Spacer()
          Text(prayer.name)
            .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .foregroundStyle(prayer.isNext ? goldPrimary : textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(prayer.isNext ? goldPrimary.opacity(0.18) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
        .overlay(
          RoundedRectangle(cornerRadius: 9)
            .stroke(prayer.isNext ? goldPrimary.opacity(0.35) : Color.clear, lineWidth: 0.6)
        )
      }

      Spacer(minLength: 0)

      HStack {
        Text("۞ أَقِمِ الصَّلَاةَ لِذِكْرِي • الصلاة نور وطمأنينة ۞")
          .font(.system(size: 10, weight: .medium, design: .serif))
          .foregroundStyle(goldPrimary.opacity(0.85))
          .frame(maxWidth: .infinity, alignment: .center)
      }
      .padding(.top, 2)
    }
    .padding(13)
  }
}

struct PrayerWidget: Widget {
  let kind = "ZawawyPrayerWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayerProvider()) {
      PrayerWidgetView(entry: $0)
    }
    .configurationDisplayName("مواقيت الصلاة")
    .description("مواقيت الصلاة والصلاة القادمة حسب موقعك.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

struct HadithItem {
  let text: String
  let source: String
  let meaning: String
}

private let curatedHadiths: [HadithItem] = [
  HadithItem(
    text: "إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى.",
    source: "متفق عليه",
    meaning: "صلاح الأعمال وقبولها وثوابها مرتبط بإخلاص النية لله وحده في كل قول وعمل."
  ),
  HadithItem(
    text: "أَحَبُّ الأَعْمَالِ إِلَى اللهِ أَدْوَمُهَا وَإِنْ قَلَّ.",
    source: "متفق عليه",
    meaning: "المداومة على الطاعة القليلة والعمل الصالح خير من العمل الكثير المنقطع."
  ),
  HadithItem(
    text: "خَيْرُكُمْ مَنْ تَعَلَّمَ القُرْآنَ وَعَلَّمَهُ.",
    source: "رواه البخاري",
    meaning: "أفضل الناس وأرفعهم قدراً من يعتني بكتاب الله حفظاً وتلاوة وتعلماً وتعليماً."
  ),
  HadithItem(
    text: "كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي المِيزَانِ، حَبِيبَتَانِ إِلَى الرَّحْمَنِ: سُبْحَانَ اللهِ وَبِحَمْدِهِ، سُبْحَانَ اللهِ العَظِيمِ.",
    source: "متفق عليه",
    meaning: "عظيم فضل ذكر الله وتسبيحه وتنزيهه، وأثره الكبير في مضاعفة الحسنات."
  ),
  HadithItem(
    text: "لَا تَحْقِرَنَّ مِنَ المَعْرُوفِ شَيْئًا، وَلَوْ أَنْ تَلْقَى أَخَاكَ بِوَجْهٍ طَلْقٍ.",
    source: "رواه مسلم",
    meaning: "لا تستصغر أي عمل خير تقدمه؛ فلكل إحسان أجر عظيم، حتى طلاقة الوجه والبشاشة."
  ),
  HadithItem(
    text: "الكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ.",
    source: "متفق عليه",
    meaning: "الكلام الحسن، والدعاء، وإدخال السرور على قلوب الناس من أعظم أنواع الصدقات."
  ),
  HadithItem(
    text: "تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ.",
    source: "رواه الترمذي",
    meaning: "إظهار الود والابتسامة في وجوه الناس عمل يسير يؤجر عليه المؤمن كأجر الصدقة."
  ),
  HadithItem(
    text: "مَنْ لَا يَرْحَمِ النَّاسَ لَا يَرْحَمْهُ اللهُ.",
    source: "متفق عليه",
    meaning: "الرحمة بالخلق والإحسان إليهم سبب رئيسي لاستنزال رحمة الخالق سبحانه وتعالى."
  ),
  HadithItem(
    text: "المُسْلِمُ مَنْ سَلِمَ المُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ.",
    source: "متفق عليه",
    meaning: "كمال الإسلام يتحقق بكف الأذى عن الناس وحفظ اللسان والجوارح عن كل سوء."
  ),
  HadithItem(
    text: "مَنْ كَانَ يُؤْمِنُ بِاللهِ وَاليَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ.",
    source: "متفق عليه",
    meaning: "الحث على ضبط اللسان والكلام بما ينفع ويثمر خيراً، أو لزوم الصمت طلباً للسلامة."
  ),
  HadithItem(
    text: "مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا، سَهَّلَ اللهُ لَهُ بِهِ طَرِيقًا إِلَى الجَنَّةِ.",
    source: "رواه مسلم",
    meaning: "فضل طلب العلم الشرعي والنافع وأنه من أعظم الأسباب الموصلة لمرضاة الله والجنة."
  ),
  HadithItem(
    text: "إِنَّ اللهَ رَفِيقٌ يُحِبُّ الرِّفْقَ، وَيُعْطِي عَلَى الرِّفْقِ مَا لَا يُعْطِي عَلَى العُنْفِ.",
    source: "رواه مسلم",
    meaning: "الرفق واللين في الأمور كلها يورث البركة والتيسير والقبول."
  ),
  HadithItem(
    text: "اتَّقِ اللهَ حَيْثُمَا كُنْتَ، وَأَتْبِعِ السَّيِّئَةَ الحَسَنَةَ تَمْحُهَا، وَخَالِقِ النَّاسَ بِخُلُقٍ حَسَنٍ.",
    source: "رواه الترمذي",
    meaning: "وصية نبوية جامعة لحسن العلاقة مع الله بالتقوى، ومع النفس بالتوبة، ومع الخلق بالأخلاق."
  ),
  HadithItem(
    text: "المُؤْمِنُ القَوِيُّ خَيْرٌ وَأَحَبُّ إِلَى اللهِ مِنَ المُؤْمِنِ الضَّعِيفِ، وَفِي كُلٍّ خَيْرٌ.",
    source: "رواه مسلم",
    meaning: "قوة الإيمان والعزيمة والعمل النافع والاستعانة بالله أحب إلى الله تعالى."
  ),
  HadithItem(
    text: "احْفَظِ اللهَ يَحْفَظْكَ، احْفَظِ اللهَ تَجِدْهُ تُجَاهَكَ.",
    source: "رواه الترمذي",
    meaning: "من راعى أوامر الله واجتنب نواهيه تولاه الله بالرعاية والتوفيق والحفظ في كل شأنه."
  ),
  HadithItem(
    text: "عَجَبًا لِأَمْرِ المُؤْمِنِ، إِنَّ أَمْرَهُ كُلَّهُ خَيْرٌ؛ إِنْ أَصَابَتْهُ سَرَّاءُ شَكَرَ فَكَانَ خَيْرًا لَهُ، وَإِنْ أَصَابَتْهُ ضَرَّاءُ صَبَرَ فَكَانَ خَيْرًا لَهُ.",
    source: "رواه مسلم",
    meaning: "شأن المؤمن كله بركة؛ فهو يتقلب بين شكر النعم وصبر الابتلاء فينال الأجر في الحالين."
  ),
  HadithItem(
    text: "الدُّعَاءُ هُوَ العِبَادَةُ.",
    source: "رواه الترمذي",
    meaning: "الدعاء جوهر العبادة ومخها لما فيه من تمام التوكل والافتقار إلى الله الغني الحميد."
  ),
  HadithItem(
    text: "مَنْ صَلَّى عَلَيَّ صَلَاةً صَلَّى اللهُ عَلَيْهِ بِهَا عَشْرًا.",
    source: "رواه مسلم",
    meaning: "عظيم بركة وفضل الصلاة على النبي ﷺ في مغفرة الذنوب ومضاعفة الأجور ورفع الدرجات."
  ),
  HadithItem(
    text: "اليَدُ العُلْيَا خَيْرٌ مِنَ اليَدِ السُّفْلَى.",
    source: "متفق عليه",
    meaning: "اليد المنفقة المعطية خير وأفضل من اليد الآخذة السائلة، حثاً على العمل والكرم."
  ),
  HadithItem(
    text: "لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ.",
    source: "متفق عليه",
    meaning: "تمام الإيمان وكماله في سلامة الصدر ومحبة الخير والنفع للآخرين كما يحبه لنفسه."
  ),
  HadithItem(
    text: "مَنْ نَفَّسَ عَنْ مُؤْمِنٍ كُرْبَةً مِنْ كُرَبِ الدُّنْيَا نَفَّسَ اللهُ عَنْهُ كُرْبَةً مِنْ كُرَبِ يَوْمِ القِيَامَةِ.",
    source: "رواه مسلم",
    meaning: "الجزاء من جنس العمل، فمن فرج هموم الناس وسعى في كشف ضيقهم فرج الله كروبه يوم القيامة."
  ),
  HadithItem(
    text: "وَاللهُ فِي عَوْنِ العَبْدِ مَا كَانَ العَبْدُ فِي عَوْنِ أَخِيهِ.",
    source: "رواه مسلم",
    meaning: "من أعان إخوانه المسلمين وبذل لهم المساعدة، شمله عون الله وتوفيقه وتيسيره."
  ),
  HadithItem(
    text: "مَنْ قَرَأَ حَرْفًا مِنْ كِتَابِ اللهِ فَلَهُ بِهِ حَسَنَةٌ، وَالحَسَنَةُ بِعَشْرِ أَمْثَالِهَا.",
    source: "رواه الترمذي",
    meaning: "عظيم مضاعفة الأجر والثواب في تلاوة آيات القرآن الكريم وحروفه المباركة."
  ),
  HadithItem(
    text: "اقْرَؤُوا القُرْآنَ فَإِنَّهُ يَأْتِي يَوْمَ القِيَامَةِ شَفِيعًا لِأَصْحَابِهِ.",
    source: "رواه مسلم",
    meaning: "القرآن الكريم يشفع لأهله التالين له المتمسكين به يوم العرض على الله تعالى."
  ),
  HadithItem(
    text: "الصَّلَاةُ نُورٌ، وَالصَّدَقَةُ بُرْهَانٌ، وَالصَّبْرُ ضِيَاءٌ.",
    source: "رواه مسلم",
    meaning: "أنوار الطاعات تضيء دروب المؤمن في الدنيا وتؤنسه في قبره وتنير صراطه يوم القيامة."
  ),
  HadithItem(
    text: "مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ، وَمَا زَادَ اللهُ عَبْدًا بِعَفْوٍ إِلَّا عِزًّا.",
    source: "رواه مسلم",
    meaning: "الصدقة تبارك في المال وتنميه، والعفو عن المسيء يورث صاحبه الرفعة والشرف عند الله."
  ),
  HadithItem(
    text: "إِنَّ الصِّدْقَ يَهْدِي إِلَى البِرِّ، وَإِنَّ البِرَّ يَهْدِي إِلَى الجَنَّةِ.",
    source: "متفق عليه",
    meaning: "التحلي بالصدق في الأقوال والأفعال يفتح أبواب الخير والبر المؤدية إلى الفوز بالجنة."
  ),
  HadithItem(
    text: "لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الغَضَبِ.",
    source: "متفق عليه",
    meaning: "القوة الحقيقية في قوة الإرادة وضبط الانفعالات والحلم عند دواعي الغضب."
  ),
  HadithItem(
    text: "أَفْشُوا السَّلَامَ، وَأَطْعِمُوا الطَّعَامَ، وَصَلُّوا بِاللَّيْلِ وَالنَّاسُ نِيَامٌ، تَدْخُلُوا الجَنَّةَ بِسَلَامٍ.",
    source: "رواه الترمذي",
    meaning: "طرق يسيرة وثوابها عظيم لدخول الجنة: نشر السلام وإطعام المحتاجين وقيام الليل."
  ),
  HadithItem(
    text: "رِضَا الرَّبِّ فِي رِضَا الوَالِدِ، وَسَخَطُ الرَّبِّ فِي سَخَطِ الوَالِدِ.",
    source: "رواه الترمذي",
    meaning: "عظم مكانة بر الوالدين والإحسان إليهما، وأنه من أعظم موجبات رضوان الله تعالى."
  ),
  HadithItem(
    text: "أَنَا وَكَافِلُ اليَتِيمِ فِي الجَنَّةِ هَكَذَا، وَأَشَارَ بِالسَّبَّابَةِ وَالوُسْطَى.",
    source: "رواه البخاري",
    meaning: "عظيم منزلة كافل اليتيم والمنفق عليه ومرافقته للنبي ﷺ في أعلى درجات الجنة."
  ),
  HadithItem(
    text: "مَنْ أَحَبَّ أَنْ يُبْسَطَ لَهُ فِي رِزْقِهِ، وَيُنْسَأَ لَهُ فِي أَثَرِهِ، فَلْيَصِلْ رَحِمَهُ.",
    source: "متفق عليه",
    meaning: "صلة الرحم والإحسان إلى الأقارب سبب لسعة الرزق والبركة في العمر والذكر الطيب."
  ),
  HadithItem(
    text: "اسْتَوْصُوا بِالنِّسَاءِ خَيْرًا.",
    source: "متفق عليه",
    meaning: "الوصية النبوية الجامعة بالإحسان إلى الأهل والنساء ورعايتهن وحسن معاشرتهن بالمعروف."
  ),
  HadithItem(
    text: "إِنَّ مِنْ أَحَبِّكُمْ إِلَيَّ وَأَقْرَبِكُمْ مِنِّي مَجْلِسًا يَوْمَ القِيَامَةِ أَحَاسِنَكُمْ أَخْلَاقًا.",
    source: "رواه الترمذي",
    meaning: "حسن الخلق مع الناس من أعظم أسباب القرب والمحبة من رسول الله ﷺ يوم القيامة."
  ),
  HadithItem(
    text: "مَنْ غَشَّنَا فَلَيْسَ مِنَّا.",
    source: "رواه مسلم",
    meaning: "تحريم الغش والخديعة في البيع والشراء والتعاملات وسائر شؤون الحياة."
  ),
  HadithItem(
    text: "لَا يَدْخُلُ الجَنَّةَ مَنْ كَانَ فِي قَلْبِهِ مِثْقَالُ ذَرَّةٍ مِنْ كِبْرٍ.",
    source: "رواه مسلم",
    meaning: "التحذير الشديد من الكبر والتعالي على الخلق، والحث على التواضع وخفض الجناح."
  ),
  HadithItem(
    text: "مَنْ تَوَاضَعَ لِلَّهِ رَفَعَهُ.",
    source: "رواه الطبراني",
    meaning: "التواضع لله ولعباده يورث العبد الرفعة والشرف والقبول في قلوب الخلق وفي ميزان الحق."
  ),
  HadithItem(
    text: "إِنَّ اللهَ تَعَالَى طَيِّبٌ لَا يَقْبَلُ إِلَّا طَيِّبًا.",
    source: "رواه مسلم",
    meaning: "الحث على طلب الحلال في المأكل والمشرب والعمل الصالح الخالص الذي يقبله الله."
  ),
  HadithItem(
    text: "دَعْ مَا يَرِيبُكَ إِلَى مَا لَا يَرِيبُكَ.",
    source: "رواه الترمذي والنسائي",
    meaning: "قاعدة جليلة في الورع وترك الشبهات واختيار ما تطمئن إليه النفس المؤمنة في دينها."
  ),
  HadithItem(
    text: "مِنْ حُسْنِ إِسْلَامِ المَرْءِ تَرْكُهُ مَا لَا يَعْنِيهِ.",
    source: "رواه الترمذي",
    meaning: "حفظ الوقت ونقاء النفس بالانشغال بما ينفع في الدنيا والآخرة والبعد عن الفضول."
  ),
  HadithItem(
    text: "أَفْضَلُ الذِّكْرِ لَا إِلَهَ إِلَّا اللهُ، وَأَفْضَلُ الدُّعَاءِ الحَمْدُ لِلَّهِ.",
    source: "رواه الترمذي",
    meaning: "عظمة كلمة التوحيد وفضل الثناء على الله وحمده على نعمه الظاهرة والباطنة."
  ),
  HadithItem(
    text: "مَنْ قَالَ سُبْحَانَ اللهِ وَبِحَمْدِهِ فِي يَوْمٍ مِائَةَ مَرَّةٍ حُطَّتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ البَحْرِ.",
    source: "متفق عليه",
    meaning: "سعة مغفرة الله تعالى وفضل الذكر السهل المداوم عليه في محو الذنوب والخطايا."
  ),
  HadithItem(
    text: "البِرُّ حُسْنُ الخُلُقِ، وَالإِثْمُ مَا حَاكَ فِي نَفْسِكَ وَكَرِهْتَ أَنْ يَطَّلِعَ عَلَيْهِ النَّاسُ.",
    source: "رواه مسلم",
    meaning: "البر يجمع كل خصال الخير والأخلاق، والإثم ما قلق منه القلب واستتر به صاحبه."
  ),
  HadithItem(
    text: "خَيْرُكُمْ خَيْرُكُمْ لِأَهْلِهِ، وَأَنَا خَيْرُكُمْ لِأَهْلِي.",
    source: "رواه الترمذي",
    meaning: "حسن الخلق والوفاء يبدأ من البيت والأسرة والإحسان إلى الأهل والأقربين."
  ),
  HadithItem(
    text: "مَا مِنْ شَيْءٍ أَثْقَلُ فِي مِيزَانِ المُؤْمِنِ يَوْمَ القِيَامَةِ مِنْ حُسْنِ الخُلُقِ.",
    source: "رواه الترمذي",
    meaning: "عظيم رجحان كفة حسن الخلق وطيب المعاملة في ميزان العبد يوم الحساب."
  ),
  HadithItem(
    text: "إِنَّ اللهَ يُحِبُّ إِذَا عَمِلَ أَحَدُكُمْ عَمَلًا أَنْ يُتْقِنَهُ.",
    source: "رواه البيهقي",
    meaning: "الحث على الإتقان والإخلاص في كل عمل ومسؤولية دينية أو دنيوية يؤديها المسلم."
  ),
  HadithItem(
    text: "تَهَادَوْا تَحَابُّوا.",
    source: "رواه البخاري في الأدب المفرد",
    meaning: "تبادل الهدايا واللطف ينشر المودة ويزيل الشحناء والضغائن من القلوب."
  ),
  HadithItem(
    text: "المُؤْمِنُ مِرْآةُ أَخِيهِ، إِذَا رَأَى فِيهَا عَيْبًا أَصْلَحَهُ.",
    source: "رواه البخاري في الأدب المفرد",
    meaning: "التناصح بالمعروف والستر والمحبة الصادقة بين المؤمنين لتقويم بعضهم بعضاً."
  )
]

struct ReminderEntry: TimelineEntry {
  let date: Date
  let text: String
  let source: String
  let meaning: String
  let lesson: String
}

private func lessonForHadith(text: String, meaning: String) -> String {
  if text.contains("النِّيَّاتِ") {
    return "جدّد إخلاصك لله في كل قول وعمل؛ فإنما يُبارك في العمل بقدر صفاء النية."
  } else if text.contains("أَدْوَمُهَا") {
    return "أحب الطاعات إلى الله ما ثبت عليه العبد، فداوم على وردك اليومي وإن كان يسيراً."
  } else if text.contains("القُرْآنَ") {
    return "رتّل كتاب الله، وتعلّم من أحكامه وآدابه، وبلّغ ما استطعت منه لأهلك ومحبيك."
  } else if text.contains("سُبْحَانَ اللهِ") || text.contains("الذِّكْرِ") {
    return "عطّر لسانك بالتسبيح والتحميد، فهي غراس الجنة وأثقل ما يوضع في ميزانك."
  } else if text.contains("المَعْرُوفِ") || text.contains("تَبَسُّمُكَ") || text.contains("صَدَقَةٌ") {
    return "بادر بالإحسان والكلمة الطيبة وبشاشة الوجه، فكل معروف تؤجر عليه صدقة."
  } else if text.contains("الخُلُقِ") || text.contains("لِأَهْلِهِ") {
    return "حسن الخلق مع الأهل والناس أثقل ما يوضع في ميزان المؤمن يوم القيامة."
  } else if text.contains("يُتْقِنَهُ") {
    return "الإتقان في العبادة والعمل دلالة على الإخلاص ومحبة الله للعبد العامل."
  } else {
    return "اقتدِ بهدي المصطفى ﷺ واجعل سنته نبراساً ينير دربك وحسن خلقك."
  }
}

struct ReminderProvider: TimelineProvider {
  func placeholder(in context: Context) -> ReminderEntry {
    let item = curatedHadiths[0]
    return ReminderEntry(
      date: Date(),
      text: item.text,
      source: item.source,
      meaning: item.meaning,
      lesson: "جدّد إخلاصك لله في كل قول وعمل؛ فإنما يُبارك في العمل بقدر صفاء النية."
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (ReminderEntry) -> Void) {
    completion(entry(for: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ReminderEntry>) -> Void) {
    let now = Date()
    let entries = (0...8).map {
      entry(for: now.addingTimeInterval(TimeInterval($0 * 4 * 3600)))
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func entry(for date: Date) -> ReminderEntry {
    let slot = UInt64(date.timeIntervalSince1970 / (4 * 3600))
    let index = Int((slot &* 1103515245 &+ 12345) % UInt64(curatedHadiths.count))
    let item = curatedHadiths[index]
    let lesson = lessonForHadith(text: item.text, meaning: item.meaning)
    return ReminderEntry(
      date: date,
      text: item.text,
      source: item.source,
      meaning: item.meaning,
      lesson: lesson
    )
  }
}

struct ReminderWidgetView: View {
  let entry: ReminderEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    Group {
      switch family {
      case .systemSmall:
        smallView
      case .systemLarge:
        largeView
      default:
        mediumView
      }
    }
    .widgetURL(URL(string: "zawawy://daily_hadith"))
    .widgetBackground(
      LinearGradient(
        colors: [
          Color(red: 0.28, green: 0.16, blue: 0.05),
          Color(red: 0.14, green: 0.07, blue: 0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .environment(\.layoutDirection, .rightToLeft)
  }

  private var smallView: some View {
    VStack(alignment: .trailing, spacing: 5) {
      ModernWidgetHeader(
        title: "حديث نبوي",
        subtitle: entry.source,
        iconName: "quote.bubble.fill",
        accentColor: goldPrimary,
        compact: true
      )

      Spacer(minLength: 1)

      Text("« \(entry.text) »")
        .font(.system(size: 13, weight: .bold, design: .serif))
        .lineLimit(3)
        .multilineTextAlignment(.trailing)
        .foregroundStyle(textPrimary)
        .minimumScaleFactor(0.72)

      Spacer(minLength: 1)

      VStack(alignment: .trailing, spacing: 2) {
        Text("الفائدة:")
          .font(.system(size: 8.5, weight: .bold))
          .foregroundStyle(goldPrimary)
        Text(entry.meaning)
          .font(.system(size: 9.5, weight: .medium, design: .rounded))
          .lineLimit(2)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(textSecondary)
          .minimumScaleFactor(0.75)
      }
      .padding(.horizontal, 7)
      .padding(.vertical, 4)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
    .padding(10)
  }

  private var mediumView: some View {
    VStack(alignment: .trailing, spacing: 6) {
      ModernWidgetHeader(
        title: "حديث شريف",
        subtitle: entry.source,
        iconName: "quote.bubble.fill",
        accentColor: goldPrimary,
        compact: true
      )

      Text("« \(entry.text) »")
        .font(.system(size: 15, weight: .bold, design: .serif))
        .lineLimit(3)
        .multilineTextAlignment(.trailing)
        .foregroundStyle(textPrimary)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .minimumScaleFactor(0.70)

      Spacer(minLength: 0)

      HStack(alignment: .top, spacing: 6) {
        Image(systemName: "sparkles")
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(goldPrimary)
          .padding(.top, 2)

        VStack(alignment: .trailing, spacing: 2) {
          Text("البيان والفائدة:")
            .font(.system(size: 9.5, weight: .bold))
            .foregroundStyle(goldPrimary)
          Text(entry.meaning)
            .font(.system(size: 11, weight: .regular, design: .rounded))
            .lineLimit(3)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(textSecondary)
            .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
      }
      .padding(.horizontal, 9)
      .padding(.vertical, 5)
      .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(goldPrimary.opacity(0.18), lineWidth: 0.5)
      )
    }
    .padding(.horizontal, 13)
    .padding(.vertical, 9)
  }

  private var largeView: some View {
    VStack(alignment: .trailing, spacing: 8) {
      ModernWidgetHeader(
        title: "حديث نبوي شريف",
        subtitle: entry.source,
        iconName: "quote.bubble.fill",
        accentColor: goldPrimary,
        compact: false
      )

      VStack(spacing: 6) {
        Text("قال رسول الله ﷺ:")
          .font(.system(size: 12, weight: .medium, design: .serif))
          .foregroundStyle(goldPrimary.opacity(0.9))

        Text("« \(entry.text) »")
          .font(.system(size: 18, weight: .bold, design: .serif))
          .lineLimit(5)
          .multilineTextAlignment(.center)
          .foregroundStyle(textPrimary)
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 6)
          .minimumScaleFactor(0.72)
      }
      .padding(.vertical, 9)
      .padding(.horizontal, 8)
      .frame(maxWidth: .infinity)
      .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 13))
      .overlay(
        RoundedRectangle(cornerRadius: 13)
          .stroke(goldPrimary.opacity(0.22), lineWidth: 0.8)
      )

      VStack(alignment: .trailing, spacing: 4) {
        HStack {
          Image(systemName: "book.fill")
            .font(.system(size: 10.5))
            .foregroundStyle(goldPrimary)
          Text("شرح الحديث والبيان")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(goldPrimary)
          Spacer()
        }

        Text(entry.meaning)
          .font(.system(size: 11.5, weight: .medium, design: .rounded))
          .lineLimit(4)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(textSecondary)
          .lineSpacing(2)
          .minimumScaleFactor(0.78)
      }
      .padding(9)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 11))
      .overlay(
        RoundedRectangle(cornerRadius: 11)
          .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
      )

      VStack(alignment: .trailing, spacing: 4) {
        HStack {
          Image(systemName: "lightbulb.fill")
            .font(.system(size: 10.5))
            .foregroundStyle(goldPrimary)
          Text("قبس وهدي نبوي")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(goldPrimary)
          Spacer()
        }

        Text(entry.lesson.isEmpty ? "اقتدِ بهدي المصطفى ﷺ واجعل سنته نبراساً ينير دربك وحسن خلقك." : entry.lesson)
          .font(.system(size: 11, weight: .regular, design: .rounded))
          .lineLimit(3)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(textSecondary.opacity(0.95))
          .minimumScaleFactor(0.78)
      }
      .padding(8)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .background(goldPrimary.opacity(0.09), in: RoundedRectangle(cornerRadius: 11))
      .overlay(
        RoundedRectangle(cornerRadius: 11)
          .stroke(goldPrimary.opacity(0.22), lineWidth: 0.6)
      )

      Spacer(minLength: 0)

      HStack {
        HStack(spacing: 5) {
          Image(systemName: "arrow.up.left.circle.fill")
            .font(.system(size: 10.5))
            .foregroundStyle(goldPrimary)
          Text("تطبيق الشيخ الزواوي • السنة النبوية")
            .font(.system(size: 9.5, weight: .medium))
            .foregroundStyle(textMuted)
        }
        Spacer()
      }
      .padding(.horizontal, 4)
    }
    .padding(13)
  }
}

struct ReminderWidget: Widget {
  let kind = "ZawawyReminderWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ReminderProvider()) {
      ReminderWidgetView(entry: $0)
    }
    .configurationDisplayName("حديث اليوم والفوائد")
    .description("أحاديث نبوية شريفة مع بيان معانيها وفوائدها المستفادة.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

// MARK: - 4. SAVED AYAHS WIDGET (مراجعة المحفوظات)

struct SavedAyah: Decodable {
  let text: String
  let tafsir: String?
  let surah: Int?
  let ayah: Int?
}

struct SavedAyahsEntry: TimelineEntry {
  let date: Date
  let text: String
  let meaning: String
  let hasItems: Bool
}

struct SavedAyahsProvider: TimelineProvider {
  func placeholder(in context: Context) -> SavedAyahsEntry {
    SavedAyahsEntry(
      date: Date(),
      text: "وَقُل رَّبِّ زِدْنِي عِلْمًا",
      meaning: "التفسير: نسأل الله الزيادة في العلم النافع.",
      hasItems: true
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (SavedAyahsEntry) -> Void) {
    completion(entry(for: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SavedAyahsEntry>) -> Void) {
    let now = Date()
    let entries = (0...5).map {
      entry(for: now.addingTimeInterval(TimeInterval($0 * 4 * 3600)))
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func entry(for date: Date) -> SavedAyahsEntry {
    let data = UserDefaults(suiteName: appGroup)?.data(forKey: savedAyahsKey)
    let ayahs = (try? data.flatMap { try JSONDecoder().decode([SavedAyah].self, from: $0) }) ?? []
    guard !ayahs.isEmpty else {
      return SavedAyahsEntry(
        date: date,
        text: "لا توجد آيات محفوظة بعد",
        meaning: "احفظ آياتك المفضلة من المصحف لتظهر لك وتراجعها هنا.",
        hasItems: false
      )
    }

    let slot = Int(date.timeIntervalSince1970 / (4 * 3600))
    let ayah = ayahs[slot % ayahs.count]
    let tafsir = ayah.tafsir?.trimmingCharacters(in: .whitespacesAndNewlines)
    return SavedAyahsEntry(
      date: date,
      text: ayah.text,
      meaning: (tafsir?.isEmpty == false)
        ? "التفسير: \(tafsir!)"
        : "افتح الآية من التطبيق لعرض التفسير.",
      hasItems: true
    )
  }
}

struct SavedAyahsWidgetView: View {
  let entry: SavedAyahsEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    Group {
      switch family {
      case .systemSmall:
        smallView
      case .systemLarge:
        largeView
      default:
        mediumView
      }
    }
    .widgetURL(URL(string: "zawawy://saved_ayahs"))
    .widgetBackground(
      LinearGradient(
        colors: [
          Color(red: 0.25, green: 0.10, blue: 0.27),
          Color(red: 0.12, green: 0.04, blue: 0.15)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .environment(\.layoutDirection, .rightToLeft)
  }

  private var smallView: some View {
    VStack(alignment: .trailing, spacing: 5) {
      ModernWidgetHeader(
        title: "المحفوظات",
        subtitle: entry.hasItems ? "مراجعة" : nil,
        iconName: "bookmark.fill",
        accentColor: goldPrimary,
        compact: true
      )

      Spacer(minLength: 1)

      Text(entry.hasItems ? "( \(entry.text) )" : entry.text)
        .font(.system(size: 13, weight: .bold, design: .serif))
        .lineLimit(3)
        .multilineTextAlignment(.trailing)
        .foregroundStyle(textPrimary)
        .minimumScaleFactor(0.72)

      Spacer(minLength: 1)

      Text(entry.meaning)
        .font(.system(size: 9.5, weight: .medium, design: .rounded))
        .lineLimit(2)
        .multilineTextAlignment(.trailing)
        .foregroundStyle(textSecondary)
        .minimumScaleFactor(0.75)
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
    .padding(10)
  }

  private var mediumView: some View {
    VStack(alignment: .trailing, spacing: 6) {
      ModernWidgetHeader(
        title: "مراجعة المحفوظات",
        subtitle: entry.hasItems ? "آية محفوظة" : "تلميح",
        iconName: "bookmark.fill",
        accentColor: goldPrimary,
        compact: true
      )

      Text(entry.hasItems ? "( \(entry.text) )" : entry.text)
        .font(.system(size: 15, weight: .bold, design: .serif))
        .lineLimit(3)
        .multilineTextAlignment(.trailing)
        .foregroundStyle(textPrimary)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .minimumScaleFactor(0.70)

      Spacer(minLength: 0)

      Text(entry.meaning)
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .lineLimit(3)
        .multilineTextAlignment(.trailing)
        .foregroundStyle(textSecondary)
        .minimumScaleFactor(0.72)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(goldPrimary.opacity(0.18), lineWidth: 0.5)
        )
    }
    .padding(.horizontal, 13)
    .padding(.vertical, 9)
  }

  private var largeView: some View {
    VStack(alignment: .trailing, spacing: 8) {
      ModernWidgetHeader(
        title: "مراجعة الآيات المحفوظة",
        subtitle: "مصحف الزواوي",
        iconName: "bookmark.fill",
        accentColor: goldPrimary,
        compact: false
      )

      VStack(spacing: 6) {
        Image(systemName: "bookmark.circle.fill")
          .font(.system(size: 20))
          .foregroundStyle(goldPrimary)

        Text(entry.hasItems ? "( \(entry.text) )" : entry.text)
          .font(.system(size: 18.5, weight: .bold, design: .serif))
          .lineLimit(5)
          .multilineTextAlignment(.center)
          .foregroundStyle(textPrimary)
          .padding(.horizontal, 6)
          .minimumScaleFactor(0.72)
      }
      .padding(.vertical, 10)
      .padding(.horizontal, 8)
      .frame(maxWidth: .infinity)
      .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 13))
      .overlay(
        RoundedRectangle(cornerRadius: 13)
          .stroke(goldPrimary.opacity(0.22), lineWidth: 0.8)
      )

      VStack(alignment: .trailing, spacing: 4) {
        HStack {
          Image(systemName: "text.book.closed.fill")
            .font(.system(size: 10.5))
            .foregroundStyle(goldPrimary)
          Text("البيان والتفسير")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(goldPrimary)
          Spacer()
        }

        Text(entry.meaning)
          .font(.system(size: 11.5, weight: .medium, design: .rounded))
          .lineLimit(4)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(textSecondary)
          .lineSpacing(2)
          .minimumScaleFactor(0.78)
      }
      .padding(9)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 11))
      .overlay(
        RoundedRectangle(cornerRadius: 11)
          .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
      )

      VStack(alignment: .trailing, spacing: 4) {
        HStack {
          Image(systemName: "repeat.circle.fill")
            .font(.system(size: 10.5))
            .foregroundStyle(goldPrimary)
          Text("تثبيت ومراجعة الحفظ")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(goldPrimary)
          Spacer()
        }

        Text("كرّر تلاوة الآية غيباً ٣ مرات ثم استمع إليها بصوت الشيخ الزواوي لإتقان مخارج الحروف وضبط الحفظ.")
          .font(.system(size: 11, weight: .regular, design: .rounded))
          .lineLimit(3)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(textSecondary.opacity(0.95))
          .minimumScaleFactor(0.78)
      }
      .padding(8)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .background(goldPrimary.opacity(0.09), in: RoundedRectangle(cornerRadius: 11))
      .overlay(
        RoundedRectangle(cornerRadius: 11)
          .stroke(goldPrimary.opacity(0.22), lineWidth: 0.6)
      )

      Spacer(minLength: 0)

      HStack {
        Image(systemName: "arrow.up.left.circle.fill")
          .font(.system(size: 10.5))
          .foregroundStyle(goldPrimary)
        Text("افتح المصحف لمتابعة الحفظ والتلاوة")
          .font(.system(size: 9.5, weight: .medium))
          .foregroundStyle(textMuted)
        Spacer()
      }
      .padding(.horizontal, 4)
    }
    .padding(13)
  }
}

struct SavedAyahsWidget: Widget {
  let kind = "ZawawySavedAyahsWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: SavedAyahsProvider()) {
      SavedAyahsWidgetView(entry: $0)
    }
    .configurationDisplayName("مراجعة المحفوظات")
    .description("آية من محفوظاتك لمراجعتها وتثبيت حفظها.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

// MARK: - 5. ADHKAR WIDGET (الأذكار الذكية حسب أوقات اليوم)

struct AdhkarWidgetEntry: TimelineEntry {
  let date: Date
  let title: String
  let text: String
  let note: String
  let iconName: String
  let target: String
  let accentColor: Color
  let bgGradient: [Color]
}

struct AdhkarWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> AdhkarWidgetEntry {
    entry(for: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (AdhkarWidgetEntry) -> Void) {
    completion(entry(for: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<AdhkarWidgetEntry>) -> Void) {
    let now = Date()
    var entries: [AdhkarWidgetEntry] = []

    // Generate entries for the next 24 hours (every 1 hour)
    for hourOffset in 0..<24 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: now) ?? now
      entries.append(entry(for: entryDate))
    }

    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func entry(for date: Date) -> AdhkarWidgetEntry {
    let hour = Calendar.current.component(.hour, from: date)

    if hour >= 5 && hour < 12 {
      // Morning Adhkar
      let morningList = [
        ("أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ.", "دعاء الصباح واستفتاح اليوم بالتوحيد والحمد."),
        ("اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ.", "سيد الاستغفار — يوجب الجنة لمن قاله موقناً به."),
        ("رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا.", "كان حقاً على الله أن يرضيه يوم القيامة."),
        ("بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ.", "حفظ ووقاية تامة من كل ضرر.")
      ]
      let index = (hour) % morningList.count
      let item = morningList[index]
      return AdhkarWidgetEntry(
        date: date,
        title: "أذكار الصباح",
        text: item.0,
        note: item.1,
        iconName: "sun.max.fill",
        target: "adhkar_morning",
        accentColor: Color(red: 0.20, green: 0.70, blue: 1.0),
        bgGradient: [Color(red: 0.05, green: 0.15, blue: 0.30), Color(red: 0.02, green: 0.08, blue: 0.18)]
      )
    } else if hour >= 15 && hour < 21 {
      // Evening Adhkar
      let eveningList = [
        ("أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ.", "استقبال المساء بالحمد والشكر والتوحيد."),
        ("اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ.", "سيد الاستغفار في المساء يوجب الجنة."),
        ("أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.", "حصن منيع في المساء لا يضرك معه شيء."),
        ("اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَإِلَيْكَ الْمَصِيرُ.", "تسليم الأمر لله واستشعار نعمه في ختام اليوم.")
      ]
      let index = (hour) % eveningList.count
      let item = eveningList[index]
      return AdhkarWidgetEntry(
        date: date,
        title: "أذكار المساء",
        text: item.0,
        note: item.1,
        iconName: "sunset.fill",
        target: "adhkar_evening",
        accentColor: Color(red: 0.90, green: 0.55, blue: 0.20),
        bgGradient: [Color(red: 0.25, green: 0.08, blue: 0.20), Color(red: 0.10, green: 0.03, blue: 0.12)]
      )
    } else if hour >= 21 || hour < 5 {
      // Sleep Adhkar
      let sleepList = [
        ("بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا.", "سنة النبي ﷺ قبل النوم."),
        ("بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ.", "توكل تام على الله عند أخذ المضجع."),
        ("اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ.", "دعاء مأثور يُقال ثلاث مرات قبل النوم.")
      ]
      let index = (hour) % sleepList.count
      let item = sleepList[index]
      return AdhkarWidgetEntry(
        date: date,
        title: "أذكار النوم",
        text: item.0,
        note: item.1,
        iconName: "moon.stars.fill",
        target: "adhkar_sleep",
        accentColor: Color(red: 0.75, green: 0.50, blue: 0.95),
        bgGradient: [Color(red: 0.12, green: 0.05, blue: 0.22), Color(red: 0.05, green: 0.02, blue: 0.10)]
      )
    } else {
      // After Prayer / General Adhkar
      return AdhkarWidgetEntry(
        date: date,
        title: "أذكار بعد الصلاة",
        text: "اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.",
        note: "استغفار وتسبيح دبر كل صلاة مكتوبة.",
        iconName: "hands.sparkles.fill",
        target: "adhkar_prayer",
        accentColor: Color(red: 0.30, green: 0.85, blue: 0.50),
        bgGradient: [Color(red: 0.03, green: 0.18, blue: 0.10), Color(red: 0.01, green: 0.08, blue: 0.04)]
      )
    }
  }
}

struct AdhkarWidgetView: View {
  let entry: AdhkarWidgetEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    Group {
      switch family {
      case .systemSmall:
        smallView
      case .systemLarge:
        largeView
      default:
        mediumView
      }
    }
    .widgetURL(URL(string: "zawawy://\(entry.target)"))
    .widgetBackground(
      LinearGradient(
        colors: entry.bgGradient,
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
  }

  private var smallView: some View {
    VStack(alignment: .trailing, spacing: 5) {
      ModernWidgetHeader(
        title: entry.title,
        subtitle: nil,
        iconName: entry.iconName,
        accentColor: entry.accentColor,
        compact: true
      )

      Spacer(minLength: 1)

      Text(entry.text)
        .font(.system(size: 13, weight: .bold, design: .serif))
        .foregroundStyle(textPrimary)
        .multilineTextAlignment(.trailing)
        .lineLimit(3)
        .minimumScaleFactor(0.72)

      Spacer(minLength: 1)

      Text(entry.note)
        .font(.system(size: 9.5, weight: .medium))
        .foregroundStyle(textSecondary)
        .multilineTextAlignment(.trailing)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .padding(5)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
    .padding(10)
  }

  private var mediumView: some View {
    VStack(alignment: .trailing, spacing: 6) {
      ModernWidgetHeader(
        title: entry.title,
        subtitle: "الورد الحالي",
        iconName: entry.iconName,
        accentColor: entry.accentColor,
        compact: true
      )

      Text(entry.text)
        .font(.system(size: 15, weight: .bold, design: .serif))
        .foregroundStyle(textPrimary)
        .multilineTextAlignment(.trailing)
        .lineLimit(3)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .minimumScaleFactor(0.70)

      Spacer(minLength: 0)

      HStack(alignment: .top, spacing: 6) {
        Image(systemName: "sparkles")
          .font(.system(size: 10))
          .foregroundStyle(entry.accentColor)
          .padding(.top, 2)

        Text(entry.note)
          .font(.system(size: 10.5, weight: .medium))
          .foregroundStyle(textSecondary)
          .multilineTextAlignment(.trailing)
          .lineLimit(2)
          .minimumScaleFactor(0.72)
        Spacer()
      }
      .padding(.horizontal, 9)
      .padding(.vertical, 5)
      .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(entry.accentColor.opacity(0.20), lineWidth: 0.5)
      )
    }
    .padding(.horizontal, 13)
    .padding(.vertical, 9)
  }

  private var largeView: some View {
    VStack(alignment: .trailing, spacing: 8) {
      ModernWidgetHeader(
        title: entry.title,
        subtitle: "أذكار وحصن المسلم",
        iconName: entry.iconName,
        accentColor: entry.accentColor,
        compact: false
      )

      VStack(spacing: 6) {
        Image(systemName: entry.iconName)
          .font(.system(size: 20))
          .foregroundStyle(entry.accentColor)

        Text(entry.text)
          .font(.system(size: 18, weight: .bold, design: .serif))
          .foregroundStyle(textPrimary)
          .multilineTextAlignment(.center)
          .lineLimit(5)
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 6)
          .minimumScaleFactor(0.72)
      }
      .padding(.vertical, 10)
      .padding(.horizontal, 8)
      .frame(maxWidth: .infinity)
      .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 13))
      .overlay(
        RoundedRectangle(cornerRadius: 13)
          .stroke(entry.accentColor.opacity(0.22), lineWidth: 0.8)
      )

      VStack(alignment: .trailing, spacing: 4) {
        HStack {
          Image(systemName: "star.fill")
            .font(.system(size: 10.5))
            .foregroundStyle(entry.accentColor)
          Text("الفضل والبركة")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(entry.accentColor)
          Spacer()
        }

        Text(entry.note)
          .font(.system(size: 11.5, weight: .medium, design: .rounded))
          .lineLimit(3)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(textSecondary)
          .lineSpacing(2)
          .minimumScaleFactor(0.78)
      }
      .padding(9)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 11))
      .overlay(
        RoundedRectangle(cornerRadius: 11)
          .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
      )

      VStack(alignment: .trailing, spacing: 4) {
        HStack {
          Image(systemName: "heart.fill")
            .font(.system(size: 10.5))
            .foregroundStyle(entry.accentColor)
          Text("ثمرة المداومة على الذكر")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(entry.accentColor)
          Spacer()
        }

        Text("الذكر يحفظ العبد من كل مكروه، ويجلب الرزق، ويبعث الطمأنينة والانشراح في الصدر.")
          .font(.system(size: 11, weight: .regular, design: .rounded))
          .lineLimit(3)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(textSecondary.opacity(0.95))
          .minimumScaleFactor(0.78)
      }
      .padding(8)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .background(entry.accentColor.opacity(0.09), in: RoundedRectangle(cornerRadius: 11))
      .overlay(
        RoundedRectangle(cornerRadius: 11)
          .stroke(entry.accentColor.opacity(0.22), lineWidth: 0.6)
      )

      Spacer(minLength: 0)

      HStack {
        Image(systemName: "arrow.up.left.circle.fill")
          .font(.system(size: 10.5))
          .foregroundStyle(entry.accentColor)
        Text("افتح حصن المسلم والأذكار في تطبيق الزواوي")
          .font(.system(size: 9.5, weight: .medium))
          .foregroundStyle(textMuted)
        Spacer()
      }
      .padding(.horizontal, 4)
    }
    .padding(13)
  }
}

struct AdhkarWidget: Widget {
  let kind = "ZawawyAdhkarWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: AdhkarWidgetProvider()) {
      AdhkarWidgetView(entry: $0)
    }
    .configurationDisplayName("الأذكار اليومية الذكية")
    .description("أذكار الصباح والمساء والنوم والصلاة تتغير تلقائياً حسب الوقت.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

// MARK: - Widget Bundle
@main
struct ZawawyWidgetsBundle: WidgetBundle {
  var body: some Widget {
    DailyAyahWidget()
    PrayerWidget()
    ReminderWidget()
    SavedAyahsWidget()
    AdhkarWidget()
  }
}
