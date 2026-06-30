import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:math'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/db_service.dart';
import '../widgets/grid_painter.dart'; 
import '../widgets/quest_card.dart';   
import 'stat_window.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final List<String> languages;
  final int realLoc;          
  final int recentActivity;   

  const DashboardScreen({
    super.key,
    required this.userData,
    required this.languages,
    required this.realLoc,
    required this.recentActivity,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dbService = DbService();
  final dio = Dio();
  
  bool isSyncing = true; 
  
  late Map<String, dynamic> _userData;
  late List<String> _languages;
  late int _realLoc;
  late int _recentActivity;

  int level = 1; int str = 10; int intl = 10; int dex = 10; int end = 10; int cp = 0;
  String characterClass = "NOVICE"; String rank = "D";
  bool isStatWindowOpen = false;

  int questStr = 0; int questInt = 0; int questDex = 0; int questEnd = 0;
  List<Map<String, dynamic>> dailyQuests = [];

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
    _languages = widget.languages;
    _realLoc = widget.realLoc;
    _recentActivity = widget.recentActivity;

    _loadDataAndQuests();
  }

  // 💡 โหลดข้อมูลสเตตัสพร้อมดึงเควสต์จาก DB ควบคู่กัน
  Future<void> _loadDataAndQuests() async {
    await _fetchQuestsFromCloud();
    await _silentFetchFromGitHub();
  }

  // 💡 ฟังก์ชันดึงคลังเควสต์จาก Supabase แล้วสุ่มรายวัน
  Future<void> _fetchQuestsFromCloud() async {
    final cloudPool = await _dbService.fetchQuestPool();
    
    if (cloudPool.isNotEmpty) {
      final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
      final random = Random(dayOfYear); 
      
      List<Map<String, dynamic>> shuffledPool = List.from(cloudPool);
      shuffledPool.shuffle(random);
      
      setState(() {
        dailyQuests = shuffledPool.take(3).map((q) => {
          "id": q['id'],
          "title": q['title'],
          "target": q['target'],
          "req": q['req'],
          "exp": q['exp'],
          "reward": q['reward'],
          "stat": q['stat'],
          "isCompleted": false, 
        }).toList();
      });
    } else {
      debugPrint("Warning: Quest pool from cloud is empty or loading failed.");
    }
  }

  Future<void> _silentFetchFromGitHub() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('github_token');
      
      if (token == null) { 
        await _syncStatsWithCloud(); 
        return; 
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userResponse = await dio.get('https://api.github.com/user?t=$timestamp', options: Options(headers: {'Authorization': 'Bearer $token', 'Cache-Control': 'no-cache'}));
      final fetchedUserData = userResponse.data;
      
      String reposUrl = fetchedUserData['repos_url'];
      final reposResponse = await dio.get('$reposUrl?t=$timestamp', options: Options(headers: {'Authorization': 'Bearer $token', 'Cache-Control': 'no-cache'}));
      final List<dynamic> repos = reposResponse.data;
      final Set<String> languages = {};
      int totalBytes = 0;
      
      for (var repo in repos) {
        if (repo['languages_url'] != null) {
          try {
            final langRes = await dio.get('${repo['languages_url']}?t=$timestamp', options: Options(headers: {'Authorization': 'Bearer $token'}));
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
        final eventsRes = await dio.get('$eventsUrl?t=$timestamp', options: Options(headers: {'Authorization': 'Bearer $token'}));
        eventsCount = (eventsRes.data as List).length;
      } catch (e) {
        debugPrint("Error fetching events: $e");
      }
      
      fetchedUserData['public_repos'] = repos.length;
      
      if (mounted) {
        setState(() {
          _userData = fetchedUserData;
          _languages = languages.toList();
          _realLoc = totalBytes ~/ 30;
          _recentActivity = eventsCount;
        });
      }
      
      await _syncStatsWithCloud();
    } catch (e) {
      debugPrint("Silent fetch failed: $e");
      await _syncStatsWithCloud();
    } finally {
      if (mounted) {
        setState(() => isSyncing = false);
      }
    }
  }

  Future<void> _syncStatsWithCloud() async {
    String userId = _userData['login'].toString();
    String displayName = _userData['name'] ?? userId;
    String avatarUrl = _userData['avatar_url'];
    int calculatedLevel = (_realLoc / 1000).floor() + 1;
    
    final syncResult = await _dbService.syncAndCheckProgress(
      userId: userId, displayName: displayName, avatarUrl: avatarUrl, 
      newLevel: calculatedLevel, newLoc: _realLoc, 
      newRepos: _userData['public_repos'] ?? 0, 
      newEvents: _recentActivity, 
      newFollowers: _userData['followers'] ?? 0, techStack: _languages
    );

    if (syncResult != null) {
      int oldLevel = level;
      int oldStr = str;
      int oldIntl = intl;
      int oldDex = dex;
      int oldEnd = end;
      int oldCp = cp;

      setState(() {
        questStr = syncResult['quest_stats']['str']; 
        questInt = syncResult['quest_stats']['int']; 
        questDex = syncResult['quest_stats']['dex']; 
        questEnd = syncResult['quest_stats']['end'];
        _calculateStats(); 
      });

      if (syncResult['has_changes'] == true) {
        Map<String, dynamic> actualChanges = syncResult['changes'];
        List<Map<String, dynamic>> completedQuestsThisTurn = [];

        for (var quest in dailyQuests) {
          String targetKey = quest['target'];
          if (actualChanges.containsKey(targetKey) && !quest['isCompleted']) {
            int currentProgress = actualChanges[targetKey];
            if (currentProgress >= quest['req']) {
              quest['isCompleted'] = true;
              completedQuestsThisTurn.add(quest);

              String stat = quest['stat'].toString().toUpperCase();
              if (stat == 'STR') { questStr += quest['reward'] as int; }
              if (stat == 'INT') { questInt += quest['reward'] as int; }
              if (stat == 'DEX') { questDex += quest['reward'] as int; }
              if (stat == 'END') { questEnd += quest['reward'] as int; }
            }
          }
        }

        if (completedQuestsThisTurn.isNotEmpty) {
          await _dbService.saveQuestRewards(userId, {
            'str': questStr, 'int': questInt, 'dex': questDex, 'end': questEnd
          });
          setState(() => _calculateStats());
        }

        Map<String, dynamic> statsGrowth = {
          if (level > oldLevel) 'LEVEL': {'old': oldLevel, 'new': level, 'color': const Color(0xFFB37700)},
          if (str > oldStr) 'STR': {'old': oldStr, 'new': str, 'color': const Color(0xFFB33A3A)},
          if (intl > oldIntl) 'INT': {'old': oldIntl, 'new': intl, 'color': const Color(0xFF3A63B3)},
          if (dex > oldDex) 'DEX': {'old': oldDex, 'new': dex, 'color': const Color(0xFF2E5A44)},
          if (end > oldEnd) 'END': {'old': oldEnd, 'new': end, 'color': const Color(0xFFB37700)},
          if (cp > oldCp) 'CP': {'old': oldCp, 'new': cp, 'color': const Color(0xFFB37700)},
        };

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showQuestCompleteDialog(context, actualChanges, completedQuestsThisTurn, statsGrowth);
        });
      }
    }
  }

  void _showQuestCompleteDialog(
    BuildContext context, 
    Map<String, dynamic> actions, 
    List<Map<String, dynamic>> completedQuests,
    Map<String, dynamic> statsGrowth
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Container(
            width: 320,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1EAD7), 
              border: Border.all(color: const Color(0xFF2E5A44), width: 3), 
              boxShadow: const [BoxShadow(color: Colors.black38, offset: Offset(6, 6))], 
            ),
            child: Material(
              color: Colors.transparent,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡ REALM LOG REPORT ⚡', style: TextStyle(color: Color(0xFF2E5A44), fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 15),
                    const Text('The Guild master has tracked new activities from your outside world accounts:', style: TextStyle(color: Color(0xFF534C40), fontSize: 14), textAlign: TextAlign.center),
                    const SizedBox(height: 15),
                    
                    const Text('[ ACTIONS TRACKED ]', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...actions.entries.map((entry) {
                      String msg = "";
                      if (entry.key == 'loc_gained') msg = '📝 Code Written: +${entry.value} Lines';
                      if (entry.key == 'repos_added') msg = '📦 Public Repos forged: +${entry.value}';
                      if (entry.key == 'events_added') msg = '⚡ Recent Pushes to Guild: +${entry.value}';
                      if (entry.key == 'languages_added') msg = '🔮 New Languages learned: +${entry.value}';
                      if (entry.key == 'followers_added') msg = '🤝 Allied Followers: +${entry.value}';
                      
                      if(msg.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(msg, style: const TextStyle(color: Color(0xFF171717), fontSize: 14, fontWeight: FontWeight.bold)),
                      );
                    }),

                    if (completedQuests.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFFBCB39C), thickness: 1.5),
                      const SizedBox(height: 5),
                      const Text('🏆 QUEST COMPLETED! 🏆', style: TextStyle(color: Color(0xFFB37700), fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...completedQuests.map((quest) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('✅ ${quest['title']}\n  (Gain +${quest['reward']} ${quest['stat']} Bonus!)', style: const TextStyle(color: Color(0xFF2E5A44), fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      )),
                    ],

                    if (statsGrowth.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFFBCB39C), thickness: 1.5),
                      const SizedBox(height: 5),
                      const Text('[ ATTRIBUTES GROWTH ]', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...statsGrowth.entries.map((entry) {
                        String statName = entry.key;
                        int oldVal = entry.value['old'];
                        int newVal = entry.value['new'];
                        Color statColor = entry.value['color'];
                        int diff = newVal - oldVal;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 45, child: Text(statName, style: TextStyle(color: statColor, fontSize: 15, fontWeight: FontWeight.bold))),
                              Text('$oldVal ', style: const TextStyle(color: Colors.black38, fontSize: 14, fontWeight: FontWeight.bold)),
                              const Icon(Icons.arrow_right_alt, size: 16, color: Colors.black54),
                              Text(' $newVal ', style: TextStyle(color: statColor, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('(+$diff)', style: const TextStyle(color: Color(0xFF2E5A44), fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }),
                    ],
                    
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E5A44), 
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF4A8060), width: 2),
                        ),
                        child: const Text('CONFIRM LOGS', style: TextStyle(color: Color(0xFFF1EAD7), fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _calculateStats() {
    int publicRepos = _userData['public_repos'] ?? 0;
    int followers = _userData['followers'] ?? 0;
    DateTime createdAt = DateTime.parse(_userData['created_at']);
    int accountAgeDays = DateTime.now().difference(createdAt).inDays;

    level = (_realLoc / 1000).floor() + 1;
    str = 5 + (publicRepos * 2) + (level ~/ 2) + questStr; 
    intl = 5 + (_languages.length * 5) + questInt; 
    dex = 5 + (_recentActivity ~/ 2) + questDex; 
    end = 5 + (accountAgeDays ~/ 30) + (followers * 2) + questEnd; 

    Map<String, int> statMap = {'WARRIOR': str, 'MAGE': intl, 'ASSASSIN': dex, 'PALADIN': end};
    var highestStat = statMap.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    if (level >= 16 && statMap.values.any((v) => v >= 32)) {
      characterClass = highestStat.key;
    } else {
      characterClass = "NOVICE";
    }

    cp = (level * 100) + (str * 2) + (intl * 2) + (dex * 2) + end;
    
    if (cp >= 50000) {
      rank = "S";
    } else if (cp >= 10000) {
      rank = "A";
    } else if (cp >= 3000) {
      rank = "B";
    } else if (cp >= 1000) {
      rank = "C";
    } else {
      rank = "D";
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    int currentExp = _realLoc % 1000;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E10), 
      body: Center(
        child: Container(
          width: isDesktop ? (size.height * 9 / 16) : size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: const Color(0xFFF1EAD7), 
            border: isDesktop ? Border.all(color: const Color(0xFFBC9642), width: 4) : null,
          ),
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(double.infinity, double.infinity),
                painter: GridPainter(), 
              ),

              if (isSyncing)
                const Center(child: CircularProgressIndicator(color: Color(0xFF2E5A44))),

              if (!isSyncing)
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 25, 25, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "CODER'S\nCODE\nJOURNAL",
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1, color: Color(0xFF171717)),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: 44, height: 44,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const FaIcon(FontAwesomeIcons.shield, size: 42, color: Color(0xFF2E5A44)),
                                      Positioned(top: 9, child: const FaIcon(FontAwesomeIcons.github, size: 20, color: Color(0xFFF1EAD7))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            GestureDetector(
                              onTap: () => setState(() => isStatWindowOpen = true),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Transform.translate(
                                    offset: const Offset(15, 0),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(color: Color(0x59FFC107), blurRadius: 20, spreadRadius: 3)]
                                      ),
                                      child: Image.asset('assets/${characterClass.toLowerCase()}.png', height: 120, fit: BoxFit.contain, filterQuality: FilterQuality.none),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text('Lv. $level', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF171717))),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 130, height: 8,
                                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: (currentExp / 1000).clamp(0.0, 1.0),
                                      child: Container(decoration: BoxDecoration(color: const Color(0xFF2E5A44), borderRadius: BorderRadius.circular(4))),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('EXP: $currentExp/1000', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25),
                        child: Text("DAILY QUESTS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF171717))),
                      ),
                      const SizedBox(height: 10),
                      
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: dailyQuests.length,
                          itemBuilder: (context, index) {
                            var quest = dailyQuests[index];
                            return QuestCard(
                              title: quest['title'],
                              exp: quest['exp'],
                              coins: quest['reward'],
                              isCompleted: quest['isCompleted'],
                              statReward: quest['stat'], 
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20), 
                    ],
                  ),
                ),

              if (isStatWindowOpen)
                StatWindow(
                  userData: _userData, languages: _languages,
                  level: level, charClass: characterClass, rank: rank,
                  str: str, intl: intl, dex: dex, end: end, cp: cp, loc: _realLoc,
                  questStr: questStr, questInt: questInt, questDex: questDex, questEnd: questEnd,
                  onClose: () => setState(() => isStatWindowOpen = false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}