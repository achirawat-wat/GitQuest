import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../widgets/grid_painter.dart';

class StatWindow extends StatefulWidget {
  final Map<String, dynamic> userData;
  final List<String> languages;
  final int level;
  final String charClass;
  final String rank;
  final int str, intl, dex, end, cp, loc;
  final VoidCallback onClose;

  final int questStr, questInt, questDex, questEnd;
  final int globalRank;
  final int totalUsers;

  const StatWindow({
    super.key,
    required this.userData,
    required this.languages,
    required this.level,
    required this.charClass,
    required this.rank,
    required this.str,
    required this.intl,
    required this.dex,
    required this.end,
    required this.cp,
    required this.loc,
    required this.questStr,
    required this.questInt,
    required this.questDex,
    required this.questEnd,
    required this.onClose,
    this.globalRank = 142,
    this.totalUsers = 1532,
  });

  @override
  State<StatWindow> createState() => _StatWindowState();
}

class _StatWindowState extends State<StatWindow> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _exportGuildCard() async {
    setState(() => _isExporting = true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        RenderRepaintBoundary boundary =
            _cardKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        final base64Data = base64Encode(pngBytes);
        setState(() => _isExporting = false);

        if (mounted) _showPreviewDialog(pngBytes, base64Data);
      } catch (e) {
        debugPrint("Forge failed: $e");
        setState(() => _isExporting = false);
      }
    });
  }

  void _showPreviewDialog(Uint8List imageBytes, String base64Data) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            border: Border.all(color: const Color(0xFFD4AF37), width: 3),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '✨ CARD FORGED! ✨',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Guild Card is ready.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),

                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Image.memory(imageBytes, fit: BoxFit.contain),
                ),

                const SizedBox(height: 15),
                const Text(
                  '📌 Open it & share directly to your\nfavorite social platforms!',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final anchor =
                          html.AnchorElement(
                              href: 'data:image/png;base64,$base64Data',
                            )
                            ..setAttribute(
                              "download",
                              "GitQuest_Card_${widget.userData['login']}.png",
                            )
                            ..click();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E5A44),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'SAVE TO DEVICE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF1EAD7),
              border: Border.all(color: const Color(0xFF8B7355), width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black45, offset: Offset(4, 4)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '[ $title ]',
                    style: const TextStyle(
                      color: Color(0xFFB37700),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF171717),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E5A44),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Color(0xFFF1EAD7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoIcon(
    BuildContext context,
    String title,
    String desc, {
    bool isDark = false,
  }) {
    if (_isExporting) return const SizedBox.shrink();
    Color iconColor = isDark ? Colors.white70 : Colors.black54;
    return GestureDetector(
      onTap: () => _showInfoDialog(context, title, desc),
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: iconColor),
        ),
        alignment: Alignment.center,
        child: Text(
          'i',
          style: TextStyle(
            fontSize: 9,
            color: iconColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Icon _getStatIcon(String label) {
    switch (label) {
      case 'STR':
        return const Icon(Icons.sports_mma, size: 14, color: Color(0xFFB33A3A));
      case 'INT':
        return const Icon(Icons.psychology, size: 14, color: Color(0xFF3A63B3));
      case 'DEX':
        return const Icon(
          Icons.directions_run,
          size: 14,
          color: Color(0xFF2E5A44),
        );
      case 'END':
        return const Icon(Icons.favorite, size: 14, color: Color(0xFFB37700));
      default:
        return const Icon(Icons.star, size: 14);
    }
  }

  Widget _buildStatText(
    BuildContext context,
    String label,
    int value,
    Color color,
    String infoText,
  ) {
    return Row(
      children: [
        _getStatIcon(label),
        const SizedBox(width: 4),
        SizedBox(
          width: 50, // 💡 ลดความกว้าง Label ลงนิดหน่อย
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF171717),
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildInfoIcon(context, label, infoText),
            ],
          ),
        ),
        const Text(
          ' : ',
          style: TextStyle(color: Color(0xFF171717), fontSize: 13),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ), // 💡 ลดฟอนต์ Value
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int publicRepos = widget.userData['public_repos'] ?? 0;
    int followers = widget.userData['followers'] ?? 0;
    int following = widget.userData['following'] ?? 0;
    DateTime createdAt = DateTime.parse(widget.userData['created_at']);
    int accountAgeDays = DateTime.now().difference(createdAt).inDays;

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320, // 💡 ล็อกความกว้างไว้ที่ 320 พิกเซลให้กะทัดรัด
          decoration: const BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black54, offset: Offset(8, 8))],
          ),
          // 💡 ใช้สัดส่วน 9:16 (แนวตั้ง) ให้พอดีกับการ์ด
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: RepaintBoundary(
              key: _cardKey,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EAD7),
                  border: Border.all(color: const Color(0xFF2E5A44), width: 3),
                ),
                child: Stack(
                  children: [
                    CustomPaint(size: Size.infinite, painter: GridPainter()),

                    Column(
                      children: [
                        // --- Header Bar ---
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          color: const Color(0xFF2E5A44),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isExporting
                                    ? 'GITQUEST: HERO ID CARD'
                                    : 'HERO PROFILE',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF1EAD7),
                                ),
                              ),
                              Visibility(
                                visible: !_isExporting,
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Color(0xFFF1EAD7),
                                    size: 20,
                                  ),
                                  onPressed: widget.onClose,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- Body Content ---
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceEvenly, // 💡 ช่วยกระจายที่ว่างไม่ให้เบียดกัน
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFF8B7355),
                                          width: 2,
                                        ),
                                      ),
                                      child: Image.network(
                                        widget.userData['avatar_url'],
                                        width: 55,
                                        height: 55,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Transform.scale(
                                      scale: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        child: Image.asset(
                                          'assets/${widget.charClass.toLowerCase()}.png',
                                          height: 55,
                                          filterQuality: FilterQuality.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.userData['login']
                                                .toString()
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF171717),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Wrap(
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                'LV.${widget.level} | RANK ${widget.rank}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFFB37700),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              _buildInfoIcon(
                                                context,
                                                'LEVEL',
                                                'Gain 1 Level for every 1000 Lines of Code.',
                                              ),
                                            ],
                                          ),
                                          Wrap(
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                widget.charClass,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF2E5A44),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              _buildInfoIcon(
                                                context,
                                                'CLASS ADVANCEMENT',
                                                'Unlock new classes when stats reach 32+.',
                                              ),
                                            ],
                                          ),

                                          // 🌟 อัปเกรด GLOBAL RANK เป็นป้ายทองคำเรืองแสงสุดพรีเมียม
                                          // 🌟 อัปเกรด GLOBAL RANK เป็นป้ายทองคำเรืองแสงสุดพรีเมียม
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFD4AF37),
                                                  Color(0xFFB37700),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: const Color(0xFF8B7355),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.amber
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            // 💡 ใช้ FittedBox ห่อไว้เพื่อบีบสเกลตัวอักษรลงอัตโนมัติเมื่อพื้นที่ไม่พอ ป้องกันการทะลุกรอบ
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.emoji_events,
                                                    size: 12,
                                                    color: Colors.white,
                                                  ), // ลดขนาดถ้วยลงนิดนึงให้สมดุล
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'RANK: #${widget.globalRank}/${widget.totalUsers}', // ย่อคำให้กระชับ
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  _buildInfoIcon(
                                                    context,
                                                    'GLOBAL RANK',
                                                    'Your real-time ranking among all registered guild members based on Total Lines of Code (LOC).',
                                                    isDark: true,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(
                                  color: Color(0xFFBCB39C),
                                  thickness: 1.5,
                                ),

                                const Text(
                                  'BASE ATTRIBUTES',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatText(
                                        context,
                                        'STR',
                                        widget.str,
                                        const Color(0xFFB33A3A),
                                        'STRENGTH [Power]\nBase 5 + (Repo[$publicRepos] * 2) + (Level[${widget.level}] / 2)\n+ quest: +${widget.questStr}',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildStatText(
                                        context,
                                        'INT',
                                        widget.intl,
                                        const Color(0xFF3A63B3),
                                        'INTELLIGENCE [Logic]\nBase 5 + (Languages[${widget.languages.length}] * 5)\n+ quest: +${widget.questInt}',
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatText(
                                        context,
                                        'DEX',
                                        widget.dex,
                                        const Color(0xFF2E5A44),
                                        'DEXTERITY [Speed]\nBase 5 + (Recent Events / 2)\n+ quest: +${widget.questDex}',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildStatText(
                                        context,
                                        'END',
                                        widget.end,
                                        const Color(0xFFB37700),
                                        'ENDURANCE [Stamina]\nBase 5 + (Account Days[$accountAgeDays] / 30) + (Followers[$followers] * 2)\n+ quest: +${widget.questEnd}',
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(
                                  color: Color(0xFFBCB39C),
                                  thickness: 1,
                                ),

                                const Text(
                                  'LANGUAGES MASTERED',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.languages.isNotEmpty
                                      ? widget.languages.join('  •  ')
                                      : 'NO MAGIC DETECTED',
                                  style: const TextStyle(
                                    color: Color(0xFF3A63B3),
                                    fontSize: 12,
                                    height: 1.3,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const Divider(
                                  color: Color(0xFFBCB39C),
                                  thickness: 1,
                                ),

                                const Text(
                                  'GUILD RECORDS (BASE DATA)',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Public Repos: $publicRepos',
                                      style: const TextStyle(
                                        color: Color(0xFF171717),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Account Age: $accountAgeDays Days',
                                      style: const TextStyle(
                                        color: Color(0xFF171717),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Followers: $followers',
                                      style: const TextStyle(
                                        color: Color(0xFF171717),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Following: $following',
                                      style: const TextStyle(
                                        color: Color(0xFF171717),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),

                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2D8BF),
                                    border: Border.all(
                                      color: const Color(0xFF8B7355),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                'CP',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              _buildInfoIcon(
                                                context,
                                                'COMBAT POWER',
                                                'Overall Battle Power\n(LVL*100) + (STR*2) + (INT*2) + (DEX*2) + END',
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${widget.cp}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFB37700),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                'TOTAL LOC',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              _buildInfoIcon(
                                                context,
                                                'LINES OF CODE',
                                                'Total accumulated lines of code estimated from repository bytes.',
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${widget.loc}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF171717),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // --- Footer / Export Button ---
                        if (_isExporting)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2D8BF),
                              border: Border.all(
                                color: const Color(0xFF8B7355),
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              'VERIFIED BY GITQUEST GUILD',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF2E5A44),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _exportGuildCard,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E5A44),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF4A8060),
                                  width: 2,
                                ),
                              ),
                              child: const Text(
                                'FORGE GUILD CARD',
                                style: TextStyle(
                                  color: Color(0xFFF1EAD7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
