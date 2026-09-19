import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/il_mio_diario_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox('userBox');
  await Hive.openBox('habitsBox');
  await Hive.openBox('weightLogsBox');
  await Hive.openBox('measurementsBox');
  await Hive.openBox('diaryBox');
  await Hive.openBox('photosBox');
  await Hive.openBox('bloodTestsBox');
  await Hive.openBox('mealsBox');

  await dotenv.load(fileName: ".env");
  
  runApp(const RipartoDaMeApp());
}

class RipartoDaMeApp extends StatelessWidget {
  const RipartoDaMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riparto da Me',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.cozyTheme, // <--- APPLICA IL DESIGN SYSTEM UFFICIALE
      home: const HomeScreen(),
    );
  }
}
