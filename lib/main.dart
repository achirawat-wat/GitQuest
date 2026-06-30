import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:git_quest/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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
        // 🎨 1. สีพื้นหลังหลักอิงจากโทนสีครีมวินเทจ (Warm Ivory) ในรูปตัวอย่าง
        scaffoldBackgroundColor: const Color(0xFFF1EAD7), 
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A2B), // สีเขียวสัญญาลักษณ์กิลด์
          brightness: Brightness.light,       // ปรับเป็น Light เพื่อให้เข้ากับพื้นหลังสว่าง
          primary: const Color(0xFF2E5A44),   // สีเขียวปุ่มและโลโก้หลัก
          secondary: const Color(0xFFD4AF37), // สีทองเหลืองโบราณ (ขอบและปุ่มกด)
          surface: const Color(0xFFF7F3E8),   // สีการ์ด/หน้าต่าง Pop-up ภายในเกม
        ),

        // 🔤 2. การจัดการ Text ให้แสดงผลสไตล์ Pixel (VT323) ได้คมชัดสมบูรณ์แบบ
        textTheme: GoogleFonts.vt323TextTheme(
          ThemeData(brightness: Brightness.light).textTheme,
        ).apply(
          bodyColor: const Color(0xFF2C2519),      // สีน้ำตาลเข้มเกือบดำสำหรับข้อความทั่วไป อ่านง่ายขึ้นเยอะ
          displayColor: const Color(0xFF1A3828),   // สีเขียวเข้มสำหรับหัวข้อ (Heading)
        ),
        
        useMaterial3: true,
      ),
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        final isDesktop = size.width > 600;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0E10), // สีกรอบนอกสุดตัดดำสนิท เพื่อขับตัวจำลองหน้าจอมือถือให้เด่น
          body: Center(
            child: Container(
              width: isDesktop ? (size.height * 9 / 16) : size.width,
              height: size.height,
              decoration: BoxDecoration(
                // 💡 ปรับเส้นขอบกรอบจำลองให้เป็นสีทองวินเทจสไตล์ไอเทมระดับตำนาน (Legendary Border)
                border: isDesktop ? Border.all(color: const Color(0xFFBC9642), width: 4) : null,
                boxShadow: isDesktop ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ] : null,
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