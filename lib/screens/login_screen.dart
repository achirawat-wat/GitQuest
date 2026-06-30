import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final dio = Dio();
  bool isLoading = false;
  Map<String, dynamic>? userData;
  List<String> usedLanguages = [];
  
  int totalLinesOfCode = 0;
  int recentActivityCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('github_token');

    if (savedToken != null) {
      debugPrint("🔒 [SESSION] Found saved token! Resuming game...");
      await _fetchUserData(savedToken);
    } else {
      debugPrint("🔓 [SESSION] No saved token. Waiting for login...");
      _checkForGitHubCallback();
    }
  }

  void _checkForGitHubCallback() {
    final uri = Uri.base;
    final code = uri.queryParameters['code'];
    
    if (code != null) {
      _exchangeCodeForToken(code);
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loginWithGitHub() async {
    final clientId = dotenv.env['GITHUB_CLIENT_ID'];
    final url = Uri.parse(
        'https://github.com/login/oauth/authorize?client_id=$clientId&redirect_uri=http://localhost:8080');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, webOnlyWindowName: '_self');
    }
  }

  Future<void> _exchangeCodeForToken(String code) async {
    setState(() => isLoading = true);
    try {
      final response = await dio.post(
        'https://github.com/login/oauth/access_token',
        data: {
          'client_id': dotenv.env['GITHUB_CLIENT_ID'],
          'client_secret': dotenv.env['GITHUB_CLIENT_SECRET'],
          'code': code,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final token = response.data['access_token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('github_token', token);
        await _fetchUserData(token);
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUserData(String token) async {
    try {
      final userResponse = await dio.get(
        'https://api.github.com/user',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final fetchedUserData = userResponse.data;

      final reposUrl = fetchedUserData['repos_url'];
      final reposResponse = await dio.get(
        reposUrl,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final List<dynamic> repos = reposResponse.data;
      final Set<String> languages = {};
      int totalBytes = 0;
      
      for (var repo in repos) {
        if (repo['languages_url'] != null) {
          try {
            final langRes = await dio.get(
              repo['languages_url'],
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
            final Map<String, dynamic> langData = langRes.data;
            
            langData.forEach((key, value) {
              languages.add(key);
              totalBytes += (value as int); 
            });
          } catch (e) {
            debugPrint("Error fetching languages: $e");
          }
        }
      }

      int eventsCount = 0;
      try {
        String eventsUrl = fetchedUserData['events_url'].toString().replaceAll('{/privacy}', '/public');
        final eventsRes = await dio.get(
          eventsUrl,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        eventsCount = (eventsRes.data as List).length;
      } catch (e) {
        debugPrint("Error fetching events: $e");
      }

      setState(() {
        userData = fetchedUserData;
        usedLanguages = languages.toList();
        totalLinesOfCode = totalBytes ~/ 30; 
        recentActivityCount = eventsCount;
        isLoading = false;
      });
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('github_token');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData != null) {
      return DashboardScreen(
        userData: userData!, 
        languages: usedLanguages,
        realLoc: totalLinesOfCode,
        recentActivity: recentActivityCount,
      );
    }

    final size = MediaQuery.of(context).size;

return Scaffold(
      backgroundColor: const Color(0xFFF1EAD7),
      body: Stack(
        children: [
          // 🛡️ 1. โซนด้านบน: โลโก้โล่กิลด์ GitHub และชื่อเกม
          Positioned(
            top: size.height * 0.10, // ขยับขึ้นนิดนึงให้บาลานซ์กับปุ่มด้านล่าง
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2D8BF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2E5A44), width: 4),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.shield, // เปลี่ยนเป็นโล่แบบทึบ เพื่อให้โลโก้ซ้อนแล้วเด่น
                        size: 75,
                        color: Color(0xFF1A3828),
                      ),
                      Positioned(
                        top: 38, // เลื่อนตำแหน่ง GitHub โลโก้ให้อยู่กลางโล่พอดี
                        child: const FaIcon(
                          FontAwesomeIcons.github,
                          size: 38,
                          color: Color(0xFFE2D8BF), // สีเดียวกับพื้นหลังวงกลม
                        ),
                      ),
                    ],
                  ),
                ),
                // 💡 ใช้ Transform.translate เพื่อดึงข้อความให้ชิดโลโก้แบบแนบสนิท
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: const Text(
                    'GitQuest',
                    style: TextStyle(
                      fontSize: 80, // ปรับลงมาเล็กน้อยให้พอดีขอบจอ
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Color(0xFF171717),
                      height: 1.0, // บีบระยะห่างบรรทัด
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🎨 2. โซนตรงกลาง: โหลดกราฟิกหลัก Pixel Art เข้ามาแสดงโดยตรง
          Positioned(
            top: size.height * 0.38,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/character.png', // รูปภาพที่รวมองค์ประกอบฉากและตัวละครไว้แล้ว
                height: 300, 
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none, // ล็อคความคมชัดสไตล์พิกเซลอาร์ตไม่ให้เบลอ
              ),
            ),
          ),

          // ⚔️ 3. โซนด้านล่าง: แผ่นเหล็กปุ่มกดเข้ากิลด์พร้อมแสงเรืองรอง (Glow Aura)
          Positioned(
            bottom: size.height * 0.12,
            left: 0,
            right: 0,
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF2E5A44))
                  : Container(
                      width: 300, // 💡 ล็อคความกว้างให้สั้นลง
                      height: 75,  // 💡 ล็อคความสูงให้เพิ่มขึ้น
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEAA655).withValues(alpha: 0.5),
                            blurRadius: 25,
                            spreadRadius: 8,
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _loginWithGitHub,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E5A44), 
                          padding: EdgeInsets.zero, // ใช้ขนาดของ Container แทน
                          elevation: 8,
                          shadowColor: Colors.black,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          side: const BorderSide(color: Color(0xFF4A8060), width: 3), 
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(FontAwesomeIcons.github, color: Color(0xFFF1EAD7), size: 22),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with GitHub',
                              style: TextStyle(
                                color: const Color(0xFFF1EAD7), 
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    offset: const Offset(2, 2),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}