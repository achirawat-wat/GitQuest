import 'package:flutter/material.dart';

class QuestCard extends StatelessWidget {
  final String title;
  final int exp;
  final int coins;
  final bool isCompleted;
  final String statReward; // 💡 รับค่าสายพลังสเตตัส เช่น STR, INT, DEX, END

  const QuestCard({
    super.key,
    required this.title,
    required this.exp,
    required this.coins,
    required this.isCompleted,
    required this.statReward,
  });

  // 💡 แมปไอคอนสเตตัสที่จะแสดงบนฝั่งขวาของการ์ดเควสต์
  Widget _getStatIcon(String stat) {
    switch (stat.toUpperCase()) {
      case 'STR': return const Icon(Icons.sports_mma, size: 20, color: Color(0xFFB33A3A)); // กำปั้น
      case 'INT': return const Icon(Icons.psychology, size: 20, color: Color(0xFF3A63B3)); // สมอง
      case 'DEX': return const Icon(Icons.directions_run, size: 20, color: Color(0xFF2E5A44)); // รองเท้าวิ่ง
      case 'END': return const Icon(Icons.favorite, size: 20, color: Color(0xFFB37700)); // หัวใจ
      default: return const Icon(Icons.star, size: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFC1D4C6) : const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? const Color(0xFF9CBBA4) : const Color(0xFFE2D8BF), 
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
            color: isCompleted ? const Color(0xFF2E5A44) : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isCompleted ? const Color(0xFF2E5A44) : const Color(0xFF171717),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 💡 แสดงผลรางวัลสเตตัสที่จะได้รับอยู่ฝั่งขวาสุดของการ์ด
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('+$exp EXP', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  Text('+$coins $statReward', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                ],
              ),
              const SizedBox(width: 8),
              _getStatIcon(statReward),
            ],
          )
        ],
      ),
    );
  }
}