import 'package:flutter/material.dart';
import 'package:git_quest/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'SUPABASE_URL หรือ SUPABASE_ANON_KEY ไม่ได้ถูกกำหนด\n'
      'กรุณาส่งค่าโดยใช้ --dart-define',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const GitQuestApp());
}

class GitQuestApp extends StatelessWidget {
  const GitQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF1EAD7),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A2B),
          brightness: Brightness.light,
          primary: const Color(0xFF2E5A44),
          secondary: const Color(0xFFD4AF37),
          surface: const Color(0xFFF7F3E8),
        ),

        textTheme: GoogleFonts.vt323TextTheme(
          ThemeData(brightness: Brightness.light).textTheme,
        ).apply(
          bodyColor: const Color(0xFF2C2519),
          displayColor: const Color(0xFF1A3828),
        ),

        useMaterial3: true,
      ),
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        final isDesktop = size.width > 600;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0E10),
          body: Center(
            child: Container(
              width: isDesktop ? (size.height * 9 / 16) : size.width,
              height: size.height,
              decoration: BoxDecoration(
                border: isDesktop
                    ? Border.all(
                        color: const Color(0xFFBC9642),
                        width: 4,
                      )
                    : null,
                boxShadow: isDesktop
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: ClipRect(
                child: child!,
              ),
            ),
          ),
        );
      },
      home: const LoginScreen(),
    );
  }
}