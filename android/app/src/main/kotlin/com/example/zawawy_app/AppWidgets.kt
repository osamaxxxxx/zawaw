package com.example.zawawy_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class DailyReminderWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        AppWidgetHelper.updateAll(context)
    }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: android.os.Bundle) {
        AppWidgetHelper.updateAll(context)
    }
}

class PrayerTimesWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        AppWidgetHelper.updateAll(context)
    }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: android.os.Bundle) {
        AppWidgetHelper.updateAll(context)
    }
}

class AyahOfDayWidget : RotatingContentWidget("آية اليوم", 0xFF355C7D.toInt(), "daily_ayah", listOf(
    Pair("( إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ )", "الفاتحة: ٥ — التفسير: نخصك وحدك بالعبادة، ونستعين بك وحدك في جميع أمورنا."),
    Pair("( فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ )", "البقرة: ١٥٢ — التفسير: اذكروا الله بالطاعة والثناء يذكركم بالرحمة والثواب."),
    Pair("( وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ )", "البقرة: ١٨٦ — التفسير: الله قريب من عباده يسمع تضرعهم ويستجيب دعاءهم."),
    Pair("( اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ )", "البقرة: ٢٥٥ — التفسير: الله لا إله إلا هو، الحي القيوم القائم بتدبير خلقه."),
    Pair("( لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا )", "البقرة: ٢٨٦ — التفسير: لا يكلف الله نفساً إلا ما تطيقه رحمة وتيسيراً."),
    Pair("( وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ )", "آل عمران: ١٣٩ — التفسير: لا تضعفوا ولا تحزنوا فالعاقبة لأهل الإيمان الحق."),
    Pair("( حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ )", "آل عمران: ١٧٣ — التفسير: كفانا الله ونعم الحافظ والوكيل لمن توكل عليه."),
    Pair("( يُرِيدُ اللَّهُ أَن يُخَفِّفَ عَنكُمْ )", "النساء: ٢٨ — التفسير: من رحمة الله التيسير والتخفيف في أحكامه."),
    Pair("( وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ )", "الأعراف: ١٥٦ — التفسير: رحمة الله وسعت كل المخلوقات بالمغفرة والإحسان."),
    Pair("( حَسْبِيَ اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ )", "التوبة: ١٢٩ — التفسير: كفاني الله متوكلاً عليه في كل أموري."),
    Pair("( أَلَا إِنَّ أَوْلِيَاءَ اللَّهِ لَا خَوْفٌ عَلَيْهِمْ وَلَا هُمْ يَحْزَنُونَ )", "يونس: ٦٢ — التفسير: أهل الإيمان والتقوى في أمان الله ورعايته."),
    Pair("( وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ عَلَيْهِ تَوَكَّلْتُ )", "هود: ٨٨ — التفسير: التوفيق بيد الله وحده والتوكل عليه مفتاح الخير."),
    Pair("( إِنَّمَا أَشْكُو بَثِّي وَحُزْنِي إِلَى اللَّهِ )", "يوسف: ٨٦ — التفسير: بث الشكوى إلى الله يورث السكينة والفرج."),
    Pair("( أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ )", "الرعد: ٢٨ — التفسير: طمأنينة القلب وسكينته تكون بذكر الله تعالى."),
    Pair("( لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ )", "إبراهيم: ٧ — التفسير: شكر النعم سبب لدوامها واستجلاب المزيد."),
    Pair("( وَاعْبُدْ رَبَّكَ حَتَّىٰ يَأْتِيَكَ الْيَقِينُ )", "الحجر: ٩٩ — التفسير: استمر في عبادة الله حتى يأتيك الأجل على طاعة."),
    Pair("( إِنَّ اللَّهَ مَعَ الَّذِينَ اتَّقَوْا وَّالَّذِينَ هُم مُّحْسِنُونَ )", "النحل: ١٢٨ — التفسير: معية الله بالتأييد والنصر لأهل التقوى والإحسان."),
    Pair("( وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ )", "الإسراء: ٨٢ — التفسير: القرآن شفاء للصدور والأبدان ورحمة للمؤمنين."),
    Pair("( رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا )", "الكهف: ١٠ — التفسير: دعاء لطلب الرحمة والتوفيق للصواب في كل أمر."),
    Pair("( قَالَ لَا تَخَافَا إِنَّنِي مَعَكُمَا أَسْمَعُ وَأَرَىٰ )", "طه: ٤٦ — التفسير: معية الله ورعايته تدفع كل خوف وتبث اليقين."),
    Pair("( وَقُل رَّبِّ زِدْنِي عِلْمًا )", "طه: ١١٤ — التفسير: ادعُ الله أن يرزقك المزيد من العلم النافع."),
    Pair("( لَّا إِلَـٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ )", "الأنبياء: ٨٧ — التفسير: دعاء ذي النون ينجي الله به المؤمنين من كل كرب."),
    Pair("( وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ )", "الشعراء: ٨٠ — التفسير: الشفاء والعافية بيد الله وحده لا شريك له."),
    Pair("( وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا )", "العنكبوت: ٦٩ — التفسير: من جاهد نفسه في طاعة الله هداه الله للخير."),
    Pair("( فَاصْبِرْ إِنَّ وَعْدَ اللَّهِ حَقٌّ )", "الروم: ٦٠ — التفسير: الصبر واليقين بأن وعد الله بالفرج واقع لا محالة."),
    Pair("( لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ )", "الزمر: ٥٣ — التفسير: لا تيأسوا من مغفرة الله ورحمته الواسعة."),
    Pair("( وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ )", "غافر: ٦٠ — التفسير: التضرع بالدعاء موعود بالإجابة وتفريج الهم."),
    Pair("( ادْفَعْ بِالَّتِي هِيَ أَحْسَنُ )", "فصلت: ٣٤ — التفسير: قابل الإساءة بالإحسان والصفح الجميل."),
    Pair("( اللَّهُ لَطِيفٌ بِعِبَادِهِ يَرْزُقُ مَن يَشَاءُ )", "الشورى: ١٩ — التفسير: لطف الله يسوق الخيرات والرحمات لعباده."),
    Pair("( هُوَ الَّذِي أَنزَلَ السَّكِينَةَ فِي قُلُوبِ الْمُؤْمِنِينَ )", "الفتح: ٤ — التفسير: السكينة فضل من الله يثبت به قلوب أوليائه."),
    Pair("( إِنَّمَا الْمُؤْمِنُونَ إِخْوَةٌ )", "الحجرات: ١٠ — التفسير: أخوة الإيمان توجب الصلح والتراحم والمحبة."),
    Pair("( وَفِي السَّمَاءِ رِزْقُكُمْ وَمَا تُوعَدُونَ )", "الذاريات: ٢٢ — التفسير: الأرزاق مقدرة ومكتوبة عند الله في السماء."),
    Pair("( هَلْ جَزَاءُ الْإِحْسَانِ إِلَّا الْإِحْسَانُ )", "الرحمن: ٦٠ — التفسير: من أحسن العمل جازاه الله بأعظم الإحسان."),
    Pair("( وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ )", "الحديد: ٤ — التفسير: علم الله محيط بكم في كل زمان ومكان."),
    Pair("( وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا )", "الطلاق: ٢ — التفسير: التقوى سبب للفرج والرزق من حيث لا يحتسب."),
    Pair("( سَيَجْعَلُ اللَّهُ بَعْدَ عُسْرٍ يُسْرًا )", "الطلاق: ٧ — التفسير: بعد كل ضيق فرج ويسر من الله."),
    Pair("( وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ )", "الضحى: ٥ — التفسير: عطاء الله يملأ قلب المؤمن بالرضا والسرور."),
    Pair("( إِنَّ مَعَ الْعُسْرِ يُسْرًا )", "الشرح: ٦ — التفسير: مع كل شدة فرج وتيسير مضاعف من الله."),
    Pair("( وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ )", "العصر: ٣ — التفسير: النجاة في الإيمان والعمل الصالح والتواصي بالحق.")
))
class HadithOfDayWidget : RotatingContentWidget("حديث اليوم", 0xFF765D2A.toInt(), "daily_hadith", listOf(
    Pair("« إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ »", "متفق عليه — التفسير: صلاح الأعمال وقبولها مرتبط بإخلاص النية لله وحده."),
    Pair("« أَحَبُّ الأَعْمَالِ إِلَى اللهِ أَدْوَمُهَا وَإِنْ قَلَّ »", "متفق عليه — التفسير: المداومة على الطاعة القليلة أحب إلى الله من العمل المنقطع."),
    Pair("« خَيْرُكُمْ مَنْ تَعَلَّمَ القُرْآنَ وَعَلَّمَهُ »", "رواه البخاري — التفسير: من أفضل الناس من يعتني بالقرآن الكريم تلاوة وتعلماً."),
    Pair("« سُبْحَانَ اللهِ وَبِحَمْدِهِ، سُبْحَانَ اللهِ العَظِيمِ »", "متفق عليه — التفسير: كلمتان خفيفتان على اللسان ثقيلتان في الميزان حبيبتان للرحمن."),
    Pair("« لَا تَحْقِرَنَّ مِنَ المَعْرُوفِ شَيْئًا »", "رواه مسلم — التفسير: لا تستصغر أي عمل خير ولو كان طلاقة الوجه والابتسامة."),
    Pair("« الكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ »", "متفق عليه — التفسير: الكلام الحسن وإدخال السرور على الناس من الصدقات."),
    Pair("« تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ »", "رواه الترمذي — التفسير: الابتسامة وبشاشة الوجه عمل يسير يؤجر عليه المسلم."),
    Pair("« مَنْ لَا يَرْحَمِ النَّاسَ لَا يَرْحَمْهُ اللهُ »", "متفق عليه — التفسير: ارحم خلق الله يرحمك الله برحمته الواسعة."),
    Pair("« المُسْلِمُ مَنْ سَلِمَ المُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ »", "متفق عليه — التفسير: كمال الإسلام في كف الأذى عن الناس ونشر السلام."),
    Pair("« فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ »", "متفق عليه — التفسير: الحث على حفظ اللسان والحديث بالخير أو لزوم الصمت."),
    Pair("« مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللهُ لَهُ طَرِيقًا إِلَى الجَنَّةِ »", "رواه مسلم — التفسير: فضل طلب العلم الشرعي والنافع وأنه طريق للجنة."),
    Pair("« إِنَّ اللهَ رَفِيقٌ يُحِبُّ الرِّفْقَ »", "رواه مسلم — التفسير: الرفق في الأمور كلها يورث البركة والتيسير."),
    Pair("« اتَّقِ اللهَ حَيْثُمَا كُنْتَ »", "رواه الترمذي — التفسير: وصية جامعة بمراقبة الله وحسن الخلق مع الناس."),
    Pair("« المُؤْمِنُ القَوِيُّ خَيْرٌ وَأَحَبُّ إِلَى اللهِ »", "رواه مسلم — التفسير: قوة الإيمان والعزيمة والعمل الصالح أحب إلى الله."),
    Pair("« احْفَظِ اللهَ يَحْفَظْكَ »", "رواه الترمذي — التفسير: من راعى حدود الله حفظه الله في دينه ودنياه."),
    Pair("« عَجَبًا لِأَمْرِ المُؤْمِنِ إِنَّ أَمْرَهُ كُلَّهُ خَيْرٌ »", "رواه مسلم — التفسير: شأن المؤمن كله خير بين الشكر في الرخاء والصبر في الضراء."),
    Pair("« الدُّعَاءُ هُوَ العِبَادَةُ »", "رواه الترمذي — التفسير: الدعاء مظهر الافتقار والتوكل التام على الله."),
    Pair("« مَنْ صَلَّى عَلَيَّ صَلَاةً صَلَّى اللهُ عَلَيْهِ بِهَا عَشْرًا »", "رواه مسلم — التفسير: فضل الصلاة على النبي ﷺ وبركتها في مغفرة الذنوب."),
    Pair("« اليَدُ العُلْيَا خَيْرٌ مِنَ اليَدِ السُّفْلَى »", "متفق عليه — التفسير: فضل العطاء والإنفاق والكرم والتعفف."),
    Pair("« لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ »", "متفق عليه — التفسير: كمال الإيمان في سلامة الصدر ومحبة الخير للجميع."),
    Pair("« مَنْ نَفَّسَ عَنْ مُؤْمِنٍ كُرْبَةً نَفَّسَ اللهُ عَنْهُ كُرْبَةً يَوْمَ القِيَامَةِ »", "رواه مسلم — التفسير: الجزاء من جنس العمل في تفريج هموم الناس."),
    Pair("« وَاللهُ فِي عَوْنِ العَبْدِ مَا كَانَ العَبْدُ فِي عَوْنِ أَخِيهِ »", "رواه مسلم — التفسير: من أعان الناس كان الله في عونه وتوفيقه."),
    Pair("« اقْرَؤُوا القُرْآنَ فَإِنَّهُ يَأْتِي يَوْمَ القِيَامَةِ شَفِيعًا لِأَصْحَابِهِ »", "رواه مسلم — التفسير: القرآن يشفع لأهله التالين له يوم القيامة."),
    Pair("« الصَّلَاةُ نُورٌ، وَالصَّدَقَةُ بُرْهَانٌ، وَالصَّبْرُ ضِيَاءٌ »", "رواه مسلم — التفسير: أنوار العبادات تنير درب المؤمن في الدنيا والآخرة."),
    Pair("« مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ »", "رواه مسلم — التفسير: الصدقة تبارك في الرزق والعفو يورث العزة."),
    Pair("« إِنَّ الصِّدْقَ يَهْدِي إِلَى البِرِّ »", "متفق عليه — التفسير: الصدق في القول والعمل سبيل للجنة."),
    Pair("« الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الغَضَبِ »", "متفق عليه — التفسير: القوة الحقيقية في ضبط النفس والتحلي بالحلم."),
    Pair("« أَفْشُوا السَّلَامَ وَأَطْعِمُوا الطَّعَامَ »", "رواه الترمذي — التفسير: نشر السلام وإطعام المحتاجين من أسباب دخول الجنة."),
    Pair("« رِضَا الرَّبِّ فِي رِضَا الوَالِدِ »", "رواه الترمذي — التفسير: بر الوالدين من أعظم القربات لمرضاة الله."),
    Pair("« أَنَا وَكَافِلُ اليَتِيمِ فِي الجَنَّةِ هَكَذَا »", "رواه البخاري — التفسير: عظيم منزلة كافل اليتيم ومرافقته للنبي ﷺ."),
    Pair("« مَنْ أَحَبَّ أَنْ يُبْسَطَ لَهُ فِي رِزْقِهِ فَلْيَصِلْ رَحِمَهُ »", "متفق عليه — التفسير: صلة الرحم سبب لسعة الرزق والبركة في العمر."),
    Pair("« اسْتَوْصُوا بِالنِّسَاءِ خَيْرًا »", "متفق عليه — التفسير: الوصية النبوية بالإحسان إلى الأهل والنساء."),
    Pair("« أَقْرَبِكُمْ مِنِّي مَجْلِسًا يَوْمَ القِيَامَةِ أَحَاسِنَكُمْ أَخْلَاقًا »", "رواه الترمذي — التفسير: حسن الخلق سبب للقرب من رسول الله ﷺ."),
    Pair("« مَنْ غَشَّنَا فَلَيْسَ مِنَّا »", "رواه مسلم — التفسير: تحريم الغش والخديعة في المعاملات والأخلاق."),
    Pair("« مَنْ تَوَاضَعَ لِلَّهِ رَفَعَهُ »", "رواه الطبراني — التفسير: التواضع يورث الرفعة والقبول عند الله والناس."),
    Pair("« إِنَّ اللهَ طَيِّبٌ لَا يَقْبَلُ إِلَّا طَيِّبًا »", "رواه مسلم — التفسير: الحث على الحلال والعمل الصالح الخالص."),
    Pair("« دَعْ مَا يَرِيبُكَ إِلَى مَا لَا يَرِيبُكَ »", "رواه الترمذي — التفسير: الورع وترك الشبهات يورث طمأنينة القلب."),
    Pair("« مِنْ حُسْنِ إِسْلَامِ المَرْءِ تَرْكُهُ مَا لَا يَعْنِيهِ »", "رواه الترمذي — التفسير: حفظ الوقت بالانشغال بما ينفع في الدين والدنيا."),
    Pair("« خَيْرُكُمْ خَيْرُكُمْ لِأَهْلِهِ »", "رواه الترمذي — التفسير: حسن المعاملة يبدأ من البيت والأسرة."),
    Pair("« إِنَّ اللهَ يُحِبُّ إِذَا عَمِلَ أَحَدُكُمْ عَمَلًا أَنْ يُتْقِنَهُ »", "رواه البيهقي — التفسير: الحث على الإتقان والإخلاص في كل عمل.")
))
class SavedAyahsWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) { ids.forEach { SavedAyahsWidget.update(context, manager, it) } }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: android.os.Bundle) { SavedAyahsWidget.update(context, manager, id) }
    companion object {
    fun update(context: Context, manager: AppWidgetManager, id: Int) {
        val saved = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE).getStringSet(AppWidgetHelper.SAVED_AYAHS_KEY, emptySet()) ?: emptySet()
        val ayahs = saved.mapNotNull { raw ->
            try {
                org.json.JSONObject(raw).let { item ->
                    item.optString("text").takeIf { it.isNotBlank() }?.let { text ->
                        val surah = item.optInt("surah", 0)
                        val ayah = item.optInt("ayah", 0)
                        val reference = if (surah > 0 && ayah > 0) "سورة $surah، آية $ayah" else "من محفوظاتك"
                        val tafsir = item.optString("tafsir").trim()
                        Triple(
                            text,
                            reference,
                            if (tafsir.isNotBlank()) "التفسير: $tafsir" else "التفسير غير محمّل لهذه الآية بعد. افتحها من التطبيق لتحديثه.\n$reference"
                        )
                    }
                }
            } catch (e: Exception) { null }
        }.sortedBy { it.second }
        val selected = ayahs.getOrNull(((System.currentTimeMillis() / (4 * 60 * 60 * 1000)) % ayahs.size.coerceAtLeast(1)).toInt())
        val views = RemoteViews(context.packageName, R.layout.daily_reminder_widget)
        val wide = manager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110) >= 220
        AppWidgetHelper.applyCardTheme(views, 0xFF6E466D.toInt(), wide)
        views.setTextViewText(R.id.widget_label, "مراجعة المحفوظات")
        views.setTextViewText(R.id.widget_content, if (selected != null) "( ${selected.first} )" else "لا توجد آيات محفوظة بعد")
        views.setTextViewText(R.id.widget_meaning, selected?.third ?: "احفظ أي آية من المصحف لتظهر هنا.")
        // The saved-ayah widget always keeps the tafsir line visible.
        views.setViewVisibility(R.id.widget_meaning, android.view.View.VISIBLE)
        views.setOnClickPendingIntent(R.id.widget_root, AppWidgetHelper.launchIntent(context, "saved_ayahs"))
        manager.updateAppWidget(id, views)
    }
    }
}
class AdhkarWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) { ids.forEach { update(context, manager, it) } }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: android.os.Bundle) { update(context, manager, id) }

    private fun update(context: Context, manager: AppWidgetManager, id: Int) {
        val calendar = java.util.Calendar.getInstance()
        val hour = calendar.get(java.util.Calendar.HOUR_OF_DAY)

        val (title, navTarget, color, items) = when {
            hour in 5..11 -> Quadruple(
                "أذكار الصباح",
                "adhkar_morning",
                0xFF1FB6FF.toInt(),
                listOf(
                    Pair("أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ.", "دعاء الصباح واستفتاح اليوم بذكر الله وتوحيده."),
                    Pair("اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ.", "سيد الاستغفار — من قاله موقناً به دخل الجنة."),
                    Pair("( اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ )", "آية الكرسي — حصن وأمان من كل سوء حتى تمسي."),
                    Pair("رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا.", "كان حقاً على الله أن يرضيه يوم القيامة."),
                    Pair("بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ.", "حفظ ووقاية تامة من كل ضرر."),
                    Pair("يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ.", "دعاء لتيسير الأمور وتفويض الأمر لله وحده.")
                )
            )
            hour in 15..20 -> Quadruple(
                "أذكار المساء",
                "adhkar_evening",
                0xFF6A1B9A.toInt(),
                listOf(
                    Pair("أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ.", "استقبال المساء بالحمد والتوحيد والثناء على الله."),
                    Pair("اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ.", "سيد الاستغفار في المساء يوجب الجنة لمن مات في ليلته."),
                    Pair("أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.", "حصن منيع في المساء لا يضرك معه شيء."),
                    Pair("( اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ )", "آية الكرسي في المساء حرز من الشيطان حتى تصبح."),
                    Pair("اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَإِلَيْكَ الْمَصِيرُ.", "تسليم الأمر لله واستشعار نعمه في ختام اليوم.")
                )
            )
            hour >= 21 || hour < 5 -> Quadruple(
                "أذكار النوم",
                "adhkar_sleep",
                0xFF560BAD.toInt(),
                listOf(
                    Pair("بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا.", "سنة النبي ﷺ قبل النوم."),
                    Pair("بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ.", "توكل تام على الله عند أخذ المضجع."),
                    Pair("اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ.", "دعاء مأثور يُقال ثلاث مرات قبل النوم."),
                    Pair("( اللَّهُ لَا إِلَـٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ )", "آية الكرسي قبل النوم لا يقربك شيطان حتى تصبح.")
                )
            )
            else -> Quadruple(
                "أذكار بعد الصلاة والتسبيح",
                "adhkar_prayer",
                0xFF20BF55.toInt(),
                listOf(
                    Pair("أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ.", "الاستغفار عقب الصلوات المفروضة."),
                    Pair("اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.", "ذكر مأثور بعد الصلاة مباشرة."),
                    Pair("سُبْحَانَ اللَّهِ (٣٣)، وَالْحَمْدُ لِلَّهِ (٣٣)، وَاللَّهُ أَكْبَرُ (٣٣).", "تسبيح وتحميد وتكبير دبر كل صلاة مكتوبة."),
                    Pair("اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ.", "وصية نبوية عظيمة دبر الصلوات.")
                )
            )
        }

        val slot = System.currentTimeMillis() / (2 * 60 * 60 * 1000)
        val index = (slot % items.size).toInt()
        val item = items[index]

        val views = RemoteViews(context.packageName, R.layout.daily_reminder_widget)
        val wide = manager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110) >= 220
        AppWidgetHelper.applyCardTheme(views, color, wide)
        views.setTextViewText(R.id.widget_label, title)
        views.setTextViewText(R.id.widget_content, item.first)
        views.setTextViewText(R.id.widget_meaning, item.second)
        views.setViewVisibility(R.id.widget_meaning, android.view.View.VISIBLE)
        views.setTextViewTextSize(R.id.widget_content, android.util.TypedValue.COMPLEX_UNIT_SP, if (wide) 20f else 16f)
        views.setOnClickPendingIntent(R.id.widget_root, AppWidgetHelper.launchIntent(context, navTarget))
        manager.updateAppWidget(id, views)
    }

    private data class Quadruple<A, B, C, D>(val first: A, val second: B, val third: C, val fourth: D)
}

open class SimpleContentWidget(private val title: String, private val content: String, private val meaning: String, private val color: Int, private val navigationTarget: String = "home") : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) { ids.forEach { update(context, manager, it) } }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: android.os.Bundle) { update(context, manager, id) }
    private fun update(context: Context, manager: AppWidgetManager, id: Int) {
        val views = RemoteViews(context.packageName, R.layout.daily_reminder_widget)
        val wide = manager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110) >= 220
        AppWidgetHelper.applyCardTheme(views, color, wide)
        views.setTextViewText(R.id.widget_label, title)
        views.setTextViewText(R.id.widget_content, content)
        views.setTextViewText(R.id.widget_meaning, meaning)
        views.setViewVisibility(R.id.widget_meaning, if (wide) android.view.View.VISIBLE else android.view.View.GONE)
        views.setTextViewTextSize(R.id.widget_content, android.util.TypedValue.COMPLEX_UNIT_SP, if (wide) 20f else 16f)
        views.setOnClickPendingIntent(R.id.widget_root, AppWidgetHelper.launchIntent(context, navigationTarget))
        manager.updateAppWidget(id, views)
    }
}

open class RotatingContentWidget(private val title: String, private val color: Int, private val navigationTarget: String, private val items: List<Pair<String, String>>) : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) { ids.forEach { update(context, manager, it) } }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: android.os.Bundle) { update(context, manager, id) }
    private fun update(context: Context, manager: AppWidgetManager, id: Int) {
        val slot = System.currentTimeMillis() / (4 * 60 * 60 * 1000)
        val index = ((slot * 1103515245L + 12345L) and Long.MAX_VALUE) % items.size
        val item = items[index.toInt()]
        val views = RemoteViews(context.packageName, R.layout.daily_reminder_widget)
        val wide = manager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110) >= 220
        AppWidgetHelper.applyCardTheme(views, color, wide)
        views.setTextViewText(R.id.widget_label, title)
        views.setTextViewText(R.id.widget_content, item.first)
        // Keep the explanation visible for both the compact and expanded verse/hadith widgets.
        views.setTextViewText(R.id.widget_meaning, item.second.replaceFirst("المعنى:", "التفسير:"))
        views.setViewVisibility(R.id.widget_meaning, android.view.View.VISIBLE)
        views.setTextViewTextSize(R.id.widget_content, android.util.TypedValue.COMPLEX_UNIT_SP, if (wide) 20f else 16f)
        views.setOnClickPendingIntent(R.id.widget_root, AppWidgetHelper.launchIntent(context, navigationTarget))
        manager.updateAppWidget(id, views)
    }
}

class WidgetRefreshReceiver : android.content.BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AppWidgetHelper.updateAll(context)
    }
}

object AppWidgetHelper {
    const val SAVED_AYAHS_KEY = "widget_saved_ayahs"

    /** Applies the card itself, rather than the transparent widget root, so each
     * content type keeps its intended theme on every launcher. */
    fun applyCardTheme(views: RemoteViews, color: Int, wide: Boolean = true) {
        val (background, icon) = when (color) {
            0xFF9B4A37.toInt() -> Pair(R.drawable.widget_card_earth, "✽")
            0xFF765D2A.toInt() -> Pair(R.drawable.widget_card_earth, "✦")
            0xFF6E466D.toInt() -> Pair(R.drawable.widget_card_violet, "⌑")
            else -> Pair(R.drawable.widget_card_background, "☾")
        }
        views.setInt(R.id.widget_card, "setBackgroundResource", background)
        views.setTextViewText(R.id.widget_icon, icon)
        views.setViewVisibility(R.id.widget_scene, if (wide) android.view.View.VISIBLE else android.view.View.GONE)
    }
    private val reminders = listOf(
        Triple("آية اليوم", "( وَقُل رَّبِّ زِدْنِي عِلْمًا )", "نسأل الله الزيادة في العلم النافع والتوفيق."),
        Triple("حديث اليوم", "« أَحَبُّ الأَعْمَالِ إِلَى اللهِ أَدْوَمُهَا وَإِنْ قَلَّ »", "المداومة على العمل الصالح القليل خير من العمل الكثير المنقطع."),
        Triple("آية اليوم", "( إِنَّ مَعَ الْعُسْرِ يُسْرًا )", "مع كل شدة وضيق فرج وتيسير مضاعف من الله."),
        Triple("حديث اليوم", "« خَيْرُكُمْ مَنْ تَعَلَّمَ القُرْآنَ وَعَلَّمَهُ »", "أفضل الناس من يعتني بكتاب الله تلاوة وتعلماً وتعليماً."),
        Triple("آية اليوم", "( أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ )", "راحة القلب وطمأنينة النفس في دوام ذكر الله."),
        Triple("حديث اليوم", "« الكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ »", "الكلام الحسن وإدخال السرور على قلوب الناس من أعظم الصدقات."),
        Triple("آية اليوم", "( لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ )", "لا تيأسوا من رحمة الله ومغفرته مهما عظمت الذنوب."),
        Triple("حديث اليوم", "« اتَّقِ اللهَ حَيْثُمَا كُنْتَ »", "وصية نبوية جامعة بمراقبة الله وحسن الخلق مع الناس.")
    )

    private fun remainingUntil(time: Long, now: Long): String {
        val totalSeconds = ((time - now).coerceAtLeast(0L) / 1000L).toInt()
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60
        return if (hours > 0) {
            String.format(Locale.US, "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format(Locale.US, "%02d:%02d", minutes, seconds)
        }
    }

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        updateReminder(context, manager)
        updatePrayerTimes(context, manager)
        updateContentWidget(context, manager, AyahOfDayWidget())
        updateContentWidget(context, manager, HadithOfDayWidget())
        updateContentWidget(context, manager, AdhkarWidget())
        manager.getAppWidgetIds(ComponentName(context, SavedAyahsWidget::class.java)).forEach {
            SavedAyahsWidget.update(context, manager, it)
        }
    }

    private fun updateContentWidget(context: Context, manager: AppWidgetManager, widget: AppWidgetProvider) {
        val ids = manager.getAppWidgetIds(ComponentName(context, widget.javaClass))
        if (ids.isNotEmpty()) widget.onUpdate(context, manager, ids)
    }

    private fun updateReminder(context: Context, manager: AppWidgetManager) {
        val ids = manager.getAppWidgetIds(ComponentName(context, DailyReminderWidget::class.java))
        val day = java.util.Calendar.getInstance().get(java.util.Calendar.DAY_OF_YEAR)
        val content = reminders[day % reminders.size]
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.daily_reminder_widget)
            val options = manager.getAppWidgetOptions(id)
            val wide = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110) >= 220
            applyCardTheme(views, if (day % 2 == 0) 0xFF355C7D.toInt() else 0xFF9B4A37.toInt(), wide)
            views.setTextViewTextSize(R.id.widget_content, android.util.TypedValue.COMPLEX_UNIT_SP, if (wide) 20f else 16f)
            views.setViewVisibility(R.id.widget_meaning, android.view.View.VISIBLE)
            views.setTextViewText(R.id.widget_label, content.first)
            views.setTextViewText(R.id.widget_content, content.second)
            views.setTextViewText(R.id.widget_meaning, "التفسير: ${content.third}")
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context, if (content.first == "آية اليوم") "daily_ayah" else "daily_hadith"))
            manager.updateAppWidget(id, views)
        }
    }

    private fun updatePrayerTimes(context: Context, manager: AppWidgetManager) {
        val ids = manager.getAppWidgetIds(ComponentName(context, PrayerTimesWidget::class.java))
        val raw = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE).getString(MainActivity.KEY_PRAYERS, "[]") ?: "[]"
        var nextName = "افتح التطبيق لتحديث المواقيت"
        var nextTime = ""
        var countdown = ""
        var countdownBase: Long? = null
        var showElapsed = false
        try {
            val array = JSONArray(raw)
            val now = System.currentTimeMillis()
            val elapsedThreshold = 30 * 60 * 1000L // 30 minutes after adhan to show elapsed
            // Find next upcoming prayer
            var upcomingIndex = -1
            for (i in 0 until array.length()) {
                val prayer = array.getJSONObject(i)
                if (prayer.getLong("time") > now) {
                    upcomingIndex = i
                    break
                }
            }
            if (upcomingIndex != -1) {
                // There is a upcoming prayer today
                val prayer = array.getJSONObject(upcomingIndex)
                val prayerTime = prayer.getLong("time")
                val prayerName = prayer.getString("name")
                nextName = "الصلاة القادمة: $prayerName"
                val formattedTime = SimpleDateFormat("h:mm a", Locale("ar")).format(Date(prayerTime))
                nextTime = "موعد الأذان: $formattedTime"
                val remaining = prayerTime - now
                countdown = "الوقت المتبقي: ${remainingUntil(prayerTime, now)}"
                countdownBase = SystemClock.elapsedRealtime() + remaining
            } else if (array.length() > 0) {
                // No upcoming prayer today (all prayers passed). Show elapsed since last prayer up to threshold,
                // then show time to first prayer of next day (approx by adding 24h to first prayer time).
                val lastPrayer = array.getJSONObject(array.length() - 1)
                val lastTime = lastPrayer.getLong("time")
                val elapsed = now - lastTime
                if (elapsed <= elapsedThreshold) {
                    showElapsed = true
                    val elapsedSec = (elapsed / 1000).toInt()
                    val hours = elapsedSec / 3600
                    val minutes = (elapsedSec % 3600) / 60
                    val seconds = elapsedSec % 60
                    val formattedElapsed = if (hours > 0) {
                        String.format(Locale.US, "%d:%02d:%02d", hours, minutes, seconds)
                    } else {
                        String.format(Locale.US, "%02d:%02d", minutes, seconds)
                    }
                    countdown = "مضى على الأذان: $formattedElapsed"
                } else {
                    // Show time to first prayer of next day (approximate by adding 24h to first prayer time)
                    val firstPrayer = array.getJSONObject(0)
                    val firstTime = firstPrayer.getLong("time")
                    val nextFirstTime = firstTime + 24 * 60 * 60 * 1000L // add 24 hours
                    val remaining = nextFirstTime - now
                    val firstName = firstPrayer.getString("name")
                    nextName = "الصلاة القادمة: $firstName (غداً)"
                    val formattedTime = SimpleDateFormat("h:mm a", Locale("ar")).format(Date(nextFirstTime))
                    nextTime = "موعد الأذان: $formattedTime"
                    countdown = "الوقت المتبقي: ${remainingUntil(nextFirstTime, now)}"
                    countdownBase = SystemClock.elapsedRealtime() + remaining
                }
            }
        } catch (e: Exception) { }
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)
            val options = manager.getAppWidgetOptions(id)
            val wide = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110) >= 220
            views.setViewVisibility(R.id.widget_scene, if (wide) android.view.View.VISIBLE else android.view.View.GONE)
            views.setTextViewTextSize(R.id.prayer_next, android.util.TypedValue.COMPLEX_UNIT_SP, if (wide) 18f else 15f)
            views.setTextViewText(R.id.prayer_next, nextName)
            views.setTextViewText(R.id.prayer_time, nextTime)
            if (showElapsed) {
                // Show elapsed as plain text (will be updated on next onUpdate)
                views.setTextViewText(R.id.prayer_countdown, countdown)
                views.setBoolean(R.id.prayer_countdown, "setCountDown", false)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && countdownBase != null) {
                views.setChronometer(R.id.prayer_countdown, countdownBase!!, "الوقت المتبقي: %s", true)
                views.setBoolean(R.id.prayer_countdown, "setCountDown", true)
            } else {
                views.setTextViewText(R.id.prayer_countdown, countdown)
            }
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context, "prayer"))
            manager.updateAppWidget(id, views)
        }
    }

    fun launchIntent(context: Context, target: String): PendingIntent = PendingIntent.getActivity(
        context,
        target.hashCode(),
        Intent(context, MainActivity::class.java).apply {
            action = "com.example.zawawy_app.OPEN_$target"
            data = android.net.Uri.parse("zawawy://widget/$target")
            putExtra(MainActivity.EXTRA_NAV_TARGET, target)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

}
