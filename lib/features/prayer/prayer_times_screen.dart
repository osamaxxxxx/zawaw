import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class UserLocation {
  static const latKey = 'loc_lat';
  static const lonKey = 'loc_lon';
  static const cityKey = 'loc_city';
  static const countryKey = 'loc_country';
  static const countryCodeKey = 'loc_country_code';
  static const sourceKey = 'loc_source';
  static const sourceGps = 'gps';
  static const sourceIp = 'ip';

  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String countryCode;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.countryCode,
  });

  static const UserLocation cairo = UserLocation(
    latitude: 30.0444,
    longitude: 31.2357,
    city: 'القاهرة',
    country: 'مصر',
    countryCode: 'EG',
  );

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      city: json['city'] as String? ?? 'القاهرة',
      country: json['country'] as String? ?? 'مصر',
      countryCode: json['countryCode'] as String? ?? 'EG',
    );
  }

  static UserLocation? fromPrefs(SharedPreferences prefs) {
    final cachedLat = prefs.getDouble(latKey);
    final cachedLon = prefs.getDouble(lonKey);
    if (cachedLat == null || cachedLon == null) return null;

    return UserLocation(
      latitude: cachedLat,
      longitude: cachedLon,
      city: prefs.getString(cityKey) ?? 'القاهرة',
      country: prefs.getString(countryKey) ?? 'مصر',
      countryCode: prefs.getString(countryCodeKey) ?? 'EG',
    );
  }

  Future<void> saveToPrefs(
    SharedPreferences prefs, {
    required String source,
  }) async {
    await prefs.setDouble(latKey, latitude);
    await prefs.setDouble(lonKey, longitude);
    await prefs.setString(cityKey, city);
    await prefs.setString(countryKey, country);
    await prefs.setString(countryCodeKey, countryCode);
    await prefs.setString(sourceKey, source);
  }
}

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  static const MethodChannel _widgetsChannel =
      MethodChannel('zawawy_app/widgets');

  static Future<void> scheduleOfflineNotifications({
    UserLocation? location,
  }) async {
    final loc = location ?? UserLocation.cairo;
    final scheduledPrayers = <PrayerTime>[];
    for (var dayOffset = 0; dayOffset < 10; dayOffset++) {
      final day = DateTime.now().add(Duration(days: dayOffset));
      final dayPrayers = PrayerTimeCalculator.calculate(
        date: day,
        latitude: loc.latitude,
        longitude: loc.longitude,
        timezoneOffsetMinutes: day.timeZoneOffset.inMinutes,
        countryCode: loc.countryCode,
      );
      
      scheduledPrayers.addAll(dayPrayers);
      
      // Calculate Morning Adhkar (Fajr + 30 minutes)
      try {
        final fajr = dayPrayers.firstWhere((p) => p.name == 'الفجر');
        scheduledPrayers.add(PrayerTime(
          'أذكار الصباح',
          fajr.time.add(const Duration(minutes: 30)),
        ));
      } catch (e) {
        debugPrint('Error getting Fajr for Adhkar scheduling: $e');
      }

      // Calculate Evening Adhkar (Asr + 30 minutes)
      try {
        final asr = dayPrayers.firstWhere((p) => p.name == 'العصر');
        scheduledPrayers.add(PrayerTime(
          'أذكار المساء',
          asr.time.add(const Duration(minutes: 30)),
        ));
      } catch (e) {
        debugPrint('Error getting Asr for Adhkar scheduling: $e');
      }
    }

    const notificationsChannel = MethodChannel('zawawy_app/prayer_notifications');
    try {
      await notificationsChannel.invokeMethod('schedulePrayerNotifications', {
        'prayers': scheduledPrayers
            .where((prayer) => prayer.time.isAfter(DateTime.now()))
            .map(
              (prayer) => {
                'name': prayer.name,
                'time': prayer.time.millisecondsSinceEpoch,
              },
            )
            .toList(),
      });
      debugPrint('Successfully scheduled 10 days of prayer & adhkar notifications completely offline!');
    } catch (e) {
      debugPrint('Error scheduling offline notifications: $e');
    }

    // iOS receives this through the app-group bridge; Android ignores it.
    try {
      await _widgetsChannel.invokeMethod('updateWidgets', {
        'prayers': scheduledPrayers
            .map(
              (prayer) => {
                'name': prayer.name,
                'time': prayer.time.millisecondsSinceEpoch,
              },
            )
            .toList(),
      });
    } catch (_) {
      // The bridge is only available on iOS builds with the widget extension.
    }
  }

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late Timer _timer;
  UserLocation _location = UserLocation.cairo;
  List<PrayerTime> _prayers = PrayerTimeCalculator.calculate(
    date: DateTime.now(),
    latitude: 30.0444,
    longitude: 31.2357,
    timezoneOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
    countryCode: 'EG',
  );
  DateTime _now = DateTime.now();
  bool _isLoading = true;
  String _sourceLabel = 'جاري تحديد موقعك وتحميل المواقيت الدقيقة';

  @override
  void initState() {
    super.initState();
    unawaited(_loadPrayerTimes());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      setState(() {
        _now = now;
      });
      if (!_isSameDay(_prayers.first.time, now)) {
        _loadPrayerTimes();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<UserLocation> _getUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLocation = UserLocation.fromPrefs(prefs);
    if (cachedLocation != null) return cachedLocation;

    try {
      final gpsLocation = await _getGpsLocation(requestPermission: true);
      await gpsLocation.saveToPrefs(prefs, source: UserLocation.sourceGps);
      return gpsLocation;
    } catch (_) {
      // Permission/network fallback: try coarse IP location, then Cairo.
    }

    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final newLocation = UserLocation.fromJson(data);
          await newLocation.saveToPrefs(prefs, source: UserLocation.sourceIp);
          return newLocation;
        }
      }
    } catch (_) {
      // Offline fallback: keep cached location or Cairo
    }

    return UserLocation.cairo;
  }

  Future<void> _loadLocationFromGps() async {
    setState(() {
      _isLoading = true;
      _sourceLabel = 'جاري تحديد موقعك باستخدام GPS...';
    });

    try {
      final newLocation = await _getGpsLocation(requestPermission: true);

      // Cache it
      final prefs = await SharedPreferences.getInstance();
      await newLocation.saveToPrefs(prefs, source: UserLocation.sourceGps);

      setState(() {
        _location = newLocation;
      });

      // Load timings
      await _loadPrayerTimesWithLocation(newLocation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديد موقعك بنجاح: ${newLocation.city}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تحديد الموقع', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            content: Text(e.toString(), style: const TextStyle(fontFamily: 'Cairo')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('موافق', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPrayerTimesWithLocation(UserLocation loc) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prayers = await PrayerTimesApi.fetchTimings(
        date: DateTime.now(),
        location: loc,
      );
      if (!mounted) return;
      setState(() {
        _prayers = prayers;
        _sourceLabel = 'المواعيد بحسب موقعك الحالي: ${loc.city}${loc.country.isNotEmpty ? "، ${loc.country}" : ""}';
        _isLoading = false;
      });
      await _scheduleNotifications();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _prayers = PrayerTimeCalculator.calculate(
          date: DateTime.now(),
          latitude: loc.latitude,
          longitude: loc.longitude,
          timezoneOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
          countryCode: loc.countryCode,
        );
        _sourceLabel =
            'تعذر تحديث المواقيت من الإنترنت، وتُعرض الآن مواقيت تقريبية لموقعك (${loc.city})';
        _isLoading = false;
      });
      await _scheduleNotifications();
    }
  }

  Future<void> _loadPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final loc = await _getUserLocation();
    if (!mounted) return;
    setState(() {
      _location = loc;
    });
    await _loadPrayerTimesWithLocation(loc);
    if (!mounted ||
        prefs.getString(UserLocation.sourceKey) == UserLocation.sourceGps) {
      return;
    }

    unawaited(_refreshFromGpsIfAlreadyAllowed());
  }

  Future<UserLocation> _getGpsLocation({required bool requestPermission}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'خدمات الموقع الجغرافي (GPS) معطلة. يرجى تفعيلها من إعدادات الجهاز.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw 'تم رفض صلاحية الوصول للموقع الجغرافي.';
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'تم رفض صلاحية الوصول للموقع بشكل دائم. يرجى تفعيلها من إعدادات التطبيق.';
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    String city = 'الموقع الحالي';
    String country = '';
    String countryCode = 'EG';

    try {
      final reverseUrl =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=10&accept-language=ar';
      final response = await http.get(
        Uri.parse(reverseUrl),
        headers: {'User-Agent': 'ZawawyApp'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          city = address['city'] as String? ??
              address['town'] as String? ??
              address['village'] as String? ??
              address['suburb'] as String? ??
              address['governorate'] as String? ??
              address['state'] as String? ??
              'موقعك الحالي';
          country = address['country'] as String? ?? '';
          countryCode =
              (address['country_code'] as String? ?? 'EG').toUpperCase();
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }

    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
      country: country,
      countryCode: countryCode,
    );
  }

  Future<void> _refreshFromGpsIfAlreadyAllowed() async {
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return;
    }

    try {
      final gpsLocation = await _getGpsLocation(requestPermission: false);
      final prefs = await SharedPreferences.getInstance();
      await gpsLocation.saveToPrefs(prefs, source: UserLocation.sourceGps);
      if (!mounted) return;
      setState(() {
        _location = gpsLocation;
      });
      await _loadPrayerTimesWithLocation(gpsLocation);
    } catch (e) {
      debugPrint('GPS refresh skipped: $e');
    }
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return Icons.wb_twilight_rounded;
      case 'الشروق':
        return Icons.wb_sunny_outlined;
      case 'الظهر':
        return Icons.wb_sunny_rounded;
      case 'العصر':
        return Icons.cloud_queue_rounded;
      case 'المغرب':
        return Icons.nights_stay_rounded;
      case 'العشاء':
        return Icons.bedtime_rounded;
      default:
        return Icons.access_time_filled_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayer = _nextPrayer();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);
    const darkGreen = Color(0xFF1B4332);

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
            'مواقيت الصلاة والأذان',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? goldColor : darkGreen,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'تحديث المواقيت',
              onPressed: _loadPrayerTimes,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            if (_isLoading)
              const LinearProgressIndicator(
                color: goldColor,
                backgroundColor: Colors.transparent,
              ),

            // Location Bar Card
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: goldColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: goldColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _location.city,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : darkGreen,
                          ),
                        ),
                        Text(
                          _sourceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _loadLocationFromGps,
                    icon: const Icon(Icons.my_location_rounded, size: 16, color: goldColor),
                    label: Text(
                      'GPS',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? goldColor : darkGreen,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: goldColor.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),

            // Next Prayer Banner Card
            _buildNextPrayerCard(nextPrayer),
            const SizedBox(height: 16),

            // Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, color: goldColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'أوقات الصلوات اليوم',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? goldColor : darkGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Prayer List
            ..._prayers.map((prayer) => _buildPrayerTile(prayer, nextPrayer)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNextPrayerCard(PrayerTime nextPrayer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);
    final occurrence = _nextOccurrence(nextPrayer);
    final remaining = occurrence.difference(_now);
    final formattedTime = _formatRemaining(remaining);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF142F24), const Color(0xFF0D1B14)]
              : [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: goldColor.withValues(alpha: isDark ? 0.15 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: goldColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: goldColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: goldColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الصلاة القادمة',
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'صلاة ${nextPrayer.name}',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: goldColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _formatTime(nextPrayer.time),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Text(
                    'الوقت المتبقي للأذان',
                    style: GoogleFonts.cairo(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedTime,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: goldColor,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTile(PrayerTime prayer, PrayerTime nextPrayer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNext = prayer.name == nextPrayer.name;
    const goldColor = Color(0xFFD4AF37);
    const darkGreen = Color(0xFF1B4332);
    final occurrence = _nextOccurrence(prayer);
    final remaining = occurrence.difference(_now);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isNext
            ? (isDark ? const Color(0xFF222C24) : const Color(0xFFF1F8F4))
            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNext ? goldColor : (isDark ? Colors.white.withValues(alpha: 0.05) : goldColor.withValues(alpha: 0.18)),
          width: isNext ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isNext
                ? goldColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isNext
                    ? goldColor.withValues(alpha: 0.2)
                    : (isDark ? const Color(0xFF282828) : goldColor.withValues(alpha: 0.1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getPrayerIcon(prayer.name),
                color: isNext ? goldColor : (isDark ? Colors.grey[400] : darkGreen),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        prayer.name,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isNext
                              ? (isDark ? goldColor : darkGreen)
                              : (isDark ? Colors.white : const Color(0xFF222222)),
                        ),
                      ),
                      if (isNext) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: goldColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'الصلاة القادمة',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'يتبقى ${_formatRemaining(remaining)}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isNext
                    ? goldColor.withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF282828) : const Color(0xFFF7F5EE)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isNext ? goldColor.withValues(alpha: 0.4) : Colors.transparent,
                ),
              ),
              child: Text(
                _formatTime(prayer.time),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isNext ? (isDark ? goldColor : darkGreen) : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PrayerTime _nextPrayer() {
    PrayerTime? next;
    DateTime? nextTime;
    for (final prayer in _prayers) {
      final occurrence = _nextOccurrence(prayer);
      if (nextTime == null || occurrence.isBefore(nextTime)) {
        next = prayer;
        nextTime = occurrence;
      }
    }
    return next ?? _prayers.first;
  }

  DateTime _nextOccurrence(PrayerTime prayer) {
    if (prayer.time.isAfter(_now)) return prayer.time;
    return prayer.time.add(const Duration(days: 1));
  }

  Future<void> _scheduleNotifications() async {
    try {
      await PrayerTimesScreen.scheduleOfflineNotifications(location: _location);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تفعيل تنبيهات الصلاة على هذا الجهاز'),
        ),
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  String _formatRemaining(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final hours = safeDuration.inHours.toString().padLeft(2, '0');
    final minutes = safeDuration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = safeDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class PrayerTime {
  final String name;
  final DateTime time;

  const PrayerTime(this.name, this.time);
}

class PrayerTimesApi {
  static const _apiUrl = 'https://api.aladhan.com/v1/timings';

  static Future<List<PrayerTime>> fetchTimings({
    required DateTime date,
    required UserLocation location,
  }) async {
    final dateText =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    
    // Determine method based on countryCode
    String method = '3'; // Default MWL
    if (location.countryCode == 'EG') {
      method = '5'; // Egyptian Survey
    } else if (location.countryCode == 'SA') {
      method = '4'; // Umm Al-Qura
    } else if (location.countryCode == 'US' || location.countryCode == 'CA') {
      method = '2'; // ISNA
    }

    final uri = Uri.parse('$_apiUrl/$dateText').replace(
      queryParameters: {
        'latitude': location.latitude.toString(),
        'longitude': location.longitude.toString(),
        'method': method,
      },
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Prayer timings request failed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final timings =
        (data['data'] as Map<String, dynamic>)['timings']
            as Map<String, dynamic>;

    return [
      PrayerTime('الفجر', _parseTime(date, timings['Fajr'] as String)),
      PrayerTime('الظهر', _parseTime(date, timings['Dhuhr'] as String)),
      PrayerTime('العصر', _parseTime(date, timings['Asr'] as String)),
      PrayerTime('المغرب', _parseTime(date, timings['Maghrib'] as String)),
      PrayerTime('العشاء', _parseTime(date, timings['Isha'] as String)),
    ];
  }

  static DateTime _parseTime(DateTime date, String value) {
    final clean = value.split(' ').first;
    final parts = clean.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}

class PrayerTimeCalculator {
  static List<PrayerTime> calculate({
    required DateTime date,
    required double latitude,
    required double longitude,
    required int timezoneOffsetMinutes,
    String countryCode = 'EG',
  }) {
    final day = DateTime(date.year, date.month, date.day);
    
    double fajrAngle = -19.5;
    double ishaAngle = -17.5;
    if (countryCode == 'SA') {
      fajrAngle = -18.5; // Umm Al-Qura Fajr
      ishaAngle = -19.0; 
    } else if (countryCode == 'US' || countryCode == 'CA') {
      fajrAngle = -15.0; // ISNA
      ishaAngle = -15.0;
    } else if (countryCode == 'EG') {
      fajrAngle = -19.5;
      ishaAngle = -17.5;
    } else {
      // Default: Muslim World League
      fajrAngle = -18.0;
      ishaAngle = -17.0;
    }

    return [
      PrayerTime('الفجر', _solarTime(day, fajrAngle, true, latitude, longitude, timezoneOffsetMinutes)),
      PrayerTime('الظهر', _dhuhr(day, latitude, longitude, timezoneOffsetMinutes)),
      PrayerTime('العصر', _asr(day, latitude, longitude, timezoneOffsetMinutes)),
      PrayerTime('المغرب', _solarTime(day, -0.833, false, latitude, longitude, timezoneOffsetMinutes)),
      PrayerTime('العشاء', _solarTime(day, ishaAngle, false, latitude, longitude, timezoneOffsetMinutes)),
    ];
  }

  static DateTime _dhuhr(DateTime date, double latitude, double longitude, int timezoneOffsetMinutes) {
    final minutes = 720 - 4 * longitude - _equationOfTime(_dayOfYear(date));
    return _dateWithMinutes(date, minutes + timezoneOffsetMinutes);
  }

  static DateTime _solarTime(DateTime date, double angle, bool beforeNoon, double latitude, double longitude, int timezoneOffsetMinutes) {
    final n = _dayOfYear(date);
    final decl = _solarDeclination(n);
    final noonMinutes = 720 - 4 * longitude - _equationOfTime(n);
    final hourAngle = _hourAngle(angle, decl, latitude);
    final delta = hourAngle * 4;
    final minutes = beforeNoon ? noonMinutes - delta : noonMinutes + delta;
    return _dateWithMinutes(date, minutes + timezoneOffsetMinutes);
  }

  static DateTime _asr(DateTime date, double latitude, double longitude, int timezoneOffsetMinutes) {
    final n = _dayOfYear(date);
    final decl = _solarDeclination(n);
    final angle = _toDegrees(
      atan(1 / (1 + tan((latitude - decl).abs() * pi / 180))),
    );
    return _solarTime(date, angle, false, latitude, longitude, timezoneOffsetMinutes);
  }

  static double _hourAngle(double angle, double declination, double latitude) {
    final latRad = latitude * pi / 180;
    final declRad = declination * pi / 180;
    final angleRad = angle * pi / 180;
    final value =
        (sin(angleRad) - sin(latRad) * sin(declRad)) /
        (cos(latRad) * cos(declRad));
    return _toDegrees(acos(value.clamp(-1.0, 1.0)));
  }

  static double _solarDeclination(int dayOfYear) {
    return 23.45 * sin((360 / 365) * (dayOfYear - 81) * pi / 180);
  }

  static double _equationOfTime(int dayOfYear) {
    final b = (360 / 365) * (dayOfYear - 81) * pi / 180;
    return 9.87 * sin(2 * b) - 7.53 * cos(b) - 1.5 * sin(b);
  }

  static int _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year)).inDays + 1;
  }

  static DateTime _dateWithMinutes(DateTime date, double minutes) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).add(Duration(minutes: minutes.round()));
  }

  static double _toDegrees(double radians) => radians * 180 / pi;
}
