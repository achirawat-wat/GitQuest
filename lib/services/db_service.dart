import 'package:flutter/foundation.dart'; // 💡 เพิ่ม import นี้สำหรับใช้งาน debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  final _supabase = Supabase.instance.client;

  // 💡 ฟังก์ชันใหม่สำหรับดึงคลังเควสต์จาก Supabase Cloud
  Future<List<Map<String, dynamic>>> fetchQuestPool() async {
    try {
      final response = await _supabase.from('quests').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Failed to fetch quest pool from cloud: $e");
      return []; // คืนค่าว่างกลับไปหากเชื่อมต่อฐานข้อมูลไม่สำเร็จ
    }
  }

  Future<Map<String, dynamic>?> syncAndCheckProgress({
    required String userId,
    required String displayName,
    required String avatarUrl,
    required int newLevel,
    required int newLoc,
    required int newRepos,
    required int newEvents,
    required int newFollowers,
    required List<String> techStack,
  }) async {
    final oldData = await _supabase
        .from('user_profile_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    int qStr = 0; int qInt = 0; int qDex = 0; int qEnd = 0;

    if (oldData != null) {
      qStr = oldData['quest_str_bonus'] ?? 0;
      qInt = oldData['quest_int_bonus'] ?? 0;
      qDex = oldData['quest_dex_bonus'] ?? 0;
      qEnd = oldData['quest_end_bonus'] ?? 0;

      // 💡 ตรวจเช็กความเปลี่ยนแปลง พร้อมป้องกัน Null Error (Safeguard)
      Map<String, int> changes = {};
      
      if (newLevel > (oldData['current_level'] ?? 1)) {
        changes['level_up'] = newLevel - (oldData['current_level'] as int? ?? 1);
      }
      if (newLoc > (oldData['total_loc'] ?? 0)) {
        changes['loc_gained'] = newLoc - (oldData['total_loc'] as int? ?? 0);
      }
      if (newRepos > (oldData['public_repos'] ?? 0)) {
        changes['repos_added'] = newRepos - (oldData['public_repos'] as int? ?? 0);
      }
      if (newEvents > (oldData['recent_events'] ?? 0)) {
        changes['events_added'] = newEvents - (oldData['recent_events'] as int? ?? 0);
      }
      if (newFollowers > (oldData['followers'] ?? 0)) {
        changes['followers_added'] = newFollowers - (oldData['followers'] as int? ?? 0);
      }
      
      List<dynamic> oldTech = oldData['tech_stack'] ?? [];
      if (techStack.length > oldTech.length) {
        changes['languages_added'] = techStack.length - oldTech.length;
      }

      await _supabase.from('user_profile_stats').upsert({
        'user_id': userId,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'current_level': newLevel,
        'total_loc': newLoc,
        'public_repos': newRepos,
        'recent_events': newEvents,
        'followers': newFollowers,
        'tech_stack': techStack,
      });

      if (changes.isNotEmpty) {
        return {
          'has_changes': true,
          'changes': changes,
          'old_data': oldData, 
          'quest_stats': {'str': qStr, 'int': qInt, 'dex': qDex, 'end': qEnd}
        };
      }
    } else {
      await _supabase.from('user_profile_stats').insert({
        'user_id': userId,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'current_level': newLevel,
        'total_loc': newLoc,
        'public_repos': newRepos,
        'recent_events': newEvents,
        'followers': newFollowers,
        'tech_stack': techStack,
      });
    }

    return {
      'has_changes': false,
      'quest_stats': {'str': qStr, 'int': qInt, 'dex': qDex, 'end': qEnd}
    };
  }

  Future<void> saveQuestRewards(String userId, Map<String, int> questStats) async {
    await _supabase.from('user_profile_stats').update({
      'quest_str_bonus': questStats['str'],
      'quest_int_bonus': questStats['int'],
      'quest_dex_bonus': questStats['dex'],
      'quest_end_bonus': questStats['end'],
    }).eq('user_id', userId);
  }
  Future<Map<String, int>> getGlobalRank(int userLoc) async {
    try {
      // 1. ดึงจำนวนผู้เล่นทั้งหมดในระบบ
      final allUsersResponse = await _supabase.from('user_profile_stats').select('user_id');
      int total = allUsersResponse.length;

      // 2. ดึงจำนวนผู้เล่นที่มีบรรทัดโค้ด (LOC) มากกว่าเรา
      final higherRankResponse = await _supabase.from('user_profile_stats')
          .select('user_id')
          .gt('total_loc', userLoc);
          
      // 3. อันดับของเรา = (จำนวนคนที่เก่งกว่า) + 1
      int rank = higherRankResponse.length + 1;

      // ป้องกันกรณีฐานข้อมูลว่าง
      if (total == 0) total = 1;
      
      return {'rank': rank, 'total': total};
    } catch (e) {
      debugPrint("Error fetching global rank: $e");
      return {'rank': 1, 'total': 1}; // Fallback ค่าเริ่มต้นถ้าเน็ตมีปัญหา
    }
  }
}