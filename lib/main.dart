import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/theme.dart';
import 'screens/reservation/calendar/reservation_calendar_screen.dart';
import 'screens/admin/admin_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP'); 
  Intl.defaultLocale = 'ja_JP'; 
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '予約カレンダー', // アプリのタイトル
      theme: AppTheme.light, // ここでテーマを設定
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
      locale: const Locale('ja', 'JP'), // ここで日本語に固定している
      home: const ReservationCalendarScreen(),// ここでホーム画面を予約カレンダー画面に設定
      routes: {
        '/admin': (_) => const AdminShell(),
      },
    );
  }
}