// This is a basic Flutter widget test for ZawawyApp.

import 'package:flutter_test/flutter_test.dart';
import 'package:zawawy_app/main.dart';

void main() {
  testWidgets('App loads and displays home screen categories', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ZawawyApp(showOnboardingInitially: false));
    await tester.pumpAndSettle();

    // Verify that our app bar shows the correct title.
    expect(find.text('تلاوات الشيخ عبدالرحمن الزواوي'), findsOneWidget);

    // Verify that our main categories are displayed.
    expect(find.text('المصحف الشريف'), findsOneWidget);
    expect(find.text('الأذكار والأدعية'), findsOneWidget);
    expect(find.text('مواقيت الصلاة'), findsOneWidget);
    expect(find.text('المحفوظات'), findsOneWidget);
    expect(find.text('دعاء ختم المصحف'), findsOneWidget);
    expect(find.text('التنزيلات'), findsOneWidget);
  });
}
