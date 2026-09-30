import Flutter
import Foundation
import WidgetKit
import UserNotifications

enum WidgetBridge {
  static let appGroup = "group.com.example.zawawyApp"
  static let prayersKey = "widget_prayers"
  static let savedAyahsKey = "widget_saved_ayahs"
  
  private static var pendingLaunchTarget: String?
  private static var widgetsChannel: FlutterMethodChannel?
  private static var notificationsChannel: FlutterMethodChannel?

  static func configure(binaryMessenger: FlutterBinaryMessenger) {
    let wChannel = FlutterMethodChannel(
      name: "zawawy_app/widgets",
      binaryMessenger: binaryMessenger
    )
    let nChannel = FlutterMethodChannel(
      name: "zawawy_app/prayer_notifications",
      binaryMessenger: binaryMessenger
    )
    
    widgetsChannel = wChannel
    notificationsChannel = nChannel

    // Request Notification Permissions on iOS early
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        print("Zawawy: Notification authorization error: \(error)")
      }
    }

    let handler: FlutterMethodCallHandler = { call, result in
      switch call.method {
      case "getLaunchTarget":
        let target = pendingLaunchTarget
        pendingLaunchTarget = nil
        result(target)

      case "schedulePrayerNotifications":
        guard let arguments = call.arguments as? [String: Any],
              let prayers = arguments["prayers"] as? [[String: Any]] else {
          result(FlutterMethodNotImplemented)
          return
        }
        do {
          let defaults = UserDefaults(suiteName: appGroup)
          defaults?.set(
            try JSONSerialization.data(withJSONObject: prayers),
            forKey: prayersKey
          )
          WidgetCenter.shared.reloadAllTimelines()

          // Schedule local notifications on iOS via UNUserNotificationCenter
          scheduleLocalNotifications(prayers: prayers)

          result(true)
        } catch {
          result(FlutterError(code: "widget_data", message: error.localizedDescription, details: nil))
        }

      case "updateWidgets":
        guard let arguments = call.arguments as? [String: Any],
              let prayers = arguments["prayers"] else {
          result(FlutterMethodNotImplemented)
          return
        }
        do {
          let defaults = UserDefaults(suiteName: appGroup)
          defaults?.set(
            try JSONSerialization.data(withJSONObject: prayers),
            forKey: prayersKey
          )
          WidgetCenter.shared.reloadAllTimelines()
          result(true)
        } catch {
          result(FlutterError(code: "widget_data", message: error.localizedDescription, details: nil))
        }

      case "updateSavedAyahs":
        guard let arguments = call.arguments as? [String: Any],
              let ayahs = arguments["ayahs"] else {
          result(FlutterMethodNotImplemented)
          return
        }
        do {
          let defaults = UserDefaults(suiteName: appGroup)
          defaults?.set(
            try JSONSerialization.data(withJSONObject: ayahs),
            forKey: savedAyahsKey
          )
          WidgetCenter.shared.reloadAllTimelines()
          result(true)
        } catch {
          result(FlutterError(code: "widget_data", message: error.localizedDescription, details: nil))
        }

      case "reloadWidgets":
        WidgetCenter.shared.reloadAllTimelines()
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    wChannel.setMethodCallHandler(handler)
    nChannel.setMethodCallHandler(handler)
  }

  private static func scheduleLocalNotifications(prayers: [[String: Any]]) {
    let center = UNUserNotificationCenter.current()

    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      guard granted else {
        print("Zawawy: Notifications permission not granted: \(String(describing: error))")
        return
      }

      center.removeAllPendingNotificationRequests()

      let now = Date()
      let calendar = Calendar.current
      var count = 0

      for (index, item) in prayers.enumerated() {
        // iOS has a limit of 64 scheduled notifications
        if count >= 60 { break }

        guard let name = item["name"] as? String else { continue }
        let timeMillis: Double
        if let tm = item["time"] as? Double {
          timeMillis = tm
        } else if let tmInt = item["time"] as? Int64 {
          timeMillis = Double(tmInt)
        } else if let tmInt = item["time"] as? Int {
          timeMillis = Double(tmInt)
        } else {
          continue
        }

        let fireDate = Date(timeIntervalSince1970: timeMillis / 1000.0)
        if fireDate <= now { continue }

        let content = UNMutableNotificationContent()
        let navTarget: String
        if name.contains("الصباح") {
          navTarget = "adhkar_morning"
          content.title = "حان وقت أذكار الصباح ☀️"
          content.body = "لا تنسَ قراءة أذكار الصباح لتحصين نفسك وابتداء يومك ببركة وذكر الله."
        } else if name.contains("المساء") {
          navTarget = "adhkar_evening"
          content.title = "حان وقت أذكار المساء 🌙"
          content.body = "لا تنسَ قراءة أذكار المساء لحفظك وطمأنينة قلبك وبركة ليلتك."
        } else if name.contains("أذكار") {
          navTarget = "adhkar"
          content.title = "حان وقت \(name)"
          content.body = "ألا بذكر الله تطمئن القلوب."
        } else {
          navTarget = "prayer"
          content.title = "حان وقت صلاة \(name) 🕌"
          content.body = "تقبّل الله منا ومنكم صالح الأعمال والطاعات."
        }

        content.sound = .default
        content.userInfo = ["target": navTarget]

        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
          identifier: "zawawy_prayer_\(index)_\(Int(fireDate.timeIntervalSince1970))",
          content: content,
          trigger: trigger
        )

        center.add(request) { error in
          if let error = error {
            print("Zawawy: Error scheduling notification for \(name): \(error)")
          }
        }
        count += 1
      }

      // Schedule Friday Kahf Reminder
      scheduleFridayKahfNotification(center: center)
    }
  }

  private static func scheduleFridayKahfNotification(center: UNUserNotificationCenter) {
    var dateComponents = DateComponents()
    dateComponents.weekday = 6 // Friday in Calendar (1=Sunday, 6=Friday)
    dateComponents.hour = 9
    dateComponents.minute = 0

    let content = UNMutableNotificationContent()
    content.title = "تذكير سورة الكهف 📖"
    content.body = "نورٌ ما بين الجمعتين.. لا تنسَ قراءة سورة الكهف والصلاة على النبي ﷺ اليوم."
    content.sound = .default
    content.userInfo = ["target": "quran_kahf"]

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: "zawawy_friday_kahf", content: content, trigger: trigger)
    center.add(request)
  }

  static func handleURL(_ url: URL) {
    guard url.scheme == "zawawy" else { return }
    let host = url.host ?? ""
    let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let target = host.isEmpty ? path : host

    guard !target.isEmpty else { return }
    handleNotificationTarget(target)
  }

  static func handleNotificationTarget(_ target: String) {
    guard !target.isEmpty else { return }
    if let channel = notificationsChannel ?? widgetsChannel {
      channel.invokeMethod("notificationNavigation", arguments: target)
    } else {
      pendingLaunchTarget = target
    }
  }
}
