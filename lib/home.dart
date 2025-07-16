// lib/home.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'settings.dart';

class SnookerTimeHome extends StatefulWidget {
  @override
  State<SnookerTimeHome> createState() => _SnookerTimeHomeState();
}

class _SnookerTimeHomeState extends State<SnookerTimeHome> {
  List<Game> games = [
    Game(name: "Snooker", pricePerHour: 240),
    Game(name: "Race", pricePerHour: 380),
  ];
  List<PurchaseItem> items = [
    PurchaseItem(name: "Drink", price: 40),
    PurchaseItem(name: "Chips", price: 50),
  ];

  GameSession? currentSession;
  List<GameSession> sessionHistory = [];
  List<Purchase> purchases = [];
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = prefs.getStringList('games');
    final itemsJson = prefs.getStringList('items');
    setState(() {
      if (gamesJson != null && gamesJson.isNotEmpty) {
        try {
          games = gamesJson.map((s) => Game.fromJson(jsonDecode(s))).toList();
        } catch (e) {
          games = [
            Game(name: "Snooker", pricePerHour: 240),
            Game(name: "Race", pricePerHour: 380),
          ];
        }
      }
      if (itemsJson != null && itemsJson.isNotEmpty) {
        try {
          items = itemsJson
              .map((s) => PurchaseItem.fromJson(jsonDecode(s)))
              .toList();
        } catch (e) {
          items = [
            PurchaseItem(name: "Drink", price: 40),
            PurchaseItem(name: "Chips", price: 50),
          ];
        }
      }
    });
  }

  Future<void> saveSettings(
      List<Game> newGames, List<PurchaseItem> newItems) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'games',
      newGames.map((g) => jsonEncode(g.toJson())).toList(),
    );
    await prefs.setStringList(
      'items',
      newItems.map((i) => jsonEncode(i.toJson())).toList(),
    );
    setState(() {
      games = List.from(newGames);
      items = List.from(newItems);
    });
  }

  void _startSession(Game game) {
    if (currentSession != null) return;
    setState(() {
      currentSession = GameSession(
        gameName: game.name,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        isWon: false,
        pricePerHour: game.pricePerHour,
        amount: 0,
      );
      _elapsedSeconds = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds =
            DateTime.now().difference(currentSession!.startTime).inSeconds;
      });
    });
  }

  void _endSession() async {
    if (currentSession == null) return;
    _timer?.cancel();
    _elapsedSeconds = 0;
    final now = DateTime.now();
    final start = currentSession!.startTime;
    final minutesPlayed = now.difference(start).inSeconds / 60;
    final rate = currentSession!.pricePerHour;
    final name = currentSession!.gameName;

    bool? isWon = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Won or Lost?'),
        content: Text('Did you win this $name round?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Won', style: TextStyle(color: Colors.green))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Lost', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (isWon == null) return;

    double amount = 0;
    if (!isWon) {
      amount = (minutesPlayed * rate) / 60;
      amount = double.parse(amount.toStringAsFixed(2));
    }

    setState(() {
      sessionHistory.add(GameSession(
        gameName: name,
        startTime: start,
        endTime: now,
        isWon: isWon,
        pricePerHour: rate,
        amount: amount,
      ));
      currentSession = null;
    });
  }

  void _addPurchase(PurchaseItem item) {
    final now = DateTime.now();
    setState(() {
      purchases.add(Purchase(
        name: item.name,
        price: item.price,
        time: now,
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${item.name} added: ₹${item.price}")));
  }

  String _formatElapsed(int secs) {
    final mins = secs ~/ 60;
    final s = secs % 60;
    return "${mins.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Widget buildDashboard() {
    int wins = sessionHistory.where((s) => s.isWon).length;
    int lost = sessionHistory.where((s) => !s.isWon).length;
    int gamesCount = sessionHistory.length;
    double spent = sessionHistory.fold(0.0, (a, b) => a + b.amount) +
        purchases.fold(0.0, (a, b) => a + b.price);
    int itemsCount = purchases.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.11),
              blurRadius: 7,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _dashCard(Icons.sports_esports, gamesCount, "Games",
                bg: Color(0xFFe3ffe1), iconColor: Color(0xFF287233)),
            _dashCard(Icons.emoji_events, wins, "Wins",
                bg: Color(0xFFe0f7fa), iconColor: Colors.green[700]),
            _dashCard(Icons.close, lost, "Lost",
                bg: Color(0xFFFFE3E3), iconColor: Colors.red[700]),
            _dashCard(Icons.shopping_cart, itemsCount, "Items",
                bg: Color(0xFFe3edff), iconColor: Colors.blue[700]),
            _dashCard(Icons.currency_rupee, spent.toStringAsFixed(0), "Total",
                bg: Color(0xFFFFF3E0), iconColor: Colors.deepOrange[700]),
          ],
        ),
      ),
    );
  }

  Widget _dashCard(IconData icon, dynamic value, String label,
      {Color? iconColor, Color? bg}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 9, horizontal: 3),
      width: 62,
      padding: EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: bg ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.black87),
          SizedBox(height: 5),
          Text('$value',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          SizedBox(height: 1),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }

  void _showTotal() {
    double total = sessionHistory.fold(0.0, (a, b) => a + b.amount) +
        purchases.fold(0.0, (a, b) => a + b.price);

    Map<String, List<Purchase>> groupedPurchases = {};
    for (var p in purchases) {
      groupedPurchases.putIfAbsent(p.name, () => []).add(p);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Current Bill'),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sessionHistory.isEmpty && purchases.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text('No sessions or purchases yet.',
                        style: TextStyle(fontSize: 16)),
                  ),
                if (sessionHistory.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8, top: 2),
                    child: Text(
                      "Games",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF287233),
                      ),
                    ),
                  ),
                ...sessionHistory.map((s) {
                  final mins = s.endTime.difference(s.startTime).inMinutes;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports_esports,
                              size: 18, color: Color(0xFF287233)),
                          SizedBox(width: 7),
                          Text(
                            "${s.gameName} (${s.isWon ? "Won" : "Lost"}${!s.isWon ? ", ₹${s.amount.toStringAsFixed(0)}" : ""})",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 26.0, top: 2, bottom: 2),
                        child: Text(
                          "Start: ${DateFormat('hh:mm a').format(s.startTime)}   End: ${DateFormat('hh:mm a').format(s.endTime)}   ($mins min)",
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ),
                      Divider(height: 22),
                    ],
                  );
                }),
                if (groupedPurchases.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8, top: 8),
                    child: Text(
                      "Purchases",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ...groupedPurchases.entries.map((entry) {
                  final name = entry.key;
                  final list = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fastfood,
                              size: 18, color: Colors.blue[800]),
                          SizedBox(width: 7),
                          Text(
                            "${list.length} $name${list.length > 1 ? 's' : ''}: ₹${(list.first.price * list.length).toStringAsFixed(0)}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 26.0, top: 3, bottom: 2),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          children: list
                              .map(
                                (p) => Text(
                                    "${DateFormat('hh:mm a').format(p.time)}",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                              )
                              .toList(),
                        ),
                      ),
                      Divider(height: 22),
                    ],
                  );
                }),
                if (sessionHistory.isNotEmpty || purchases.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 8),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFF287233).withOpacity(0.11),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Center(
                        child: Text(
                          "Total: ₹${total.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 21,
                            color: Color(0xFF287233),
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _resetAll() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset All?'),
        content: Text(
            'This will clear your current bill and sessions. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Reset', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (res == true) {
      setState(() {
        sessionHistory.clear();
        purchases.clear();
        currentSession = null;
        _elapsedSeconds = 0;
      });
      _timer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ready for your next visit!")),
      );
    }
  }

  Widget _buildGameCard({
    required IconData icon,
    required String title,
    required Color color,
    required double price,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        color: onTap == null ? Colors.grey[300] : Colors.white,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          width: double.infinity,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.10),
                radius: 28,
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Start $title',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Text(
                '₹${price.toStringAsFixed(0)}/hr',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F7F4),
      appBar: AppBar(
        title: Text(
          'SnookerTime',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF287233),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Color(0xFF287233)),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) => SettingsScreen(
                            games: List<Game>.from(games),
                            items: List<PurchaseItem>.from(items),
                            onSave: (gs, its) async {
                              await saveSettings(gs, its);
                              await _loadSettings();
                            },
                          )));
              await _loadSettings();
              setState(() {});
            },
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildDashboard(),
                if (currentSession != null)
                  Card(
                    color: Colors.amber[100],
                    margin: EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.sports_esports,
                              color: Colors.orange[900], size: 30),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Now Playing: ${currentSession!.gameName}',
                                  style: GoogleFonts.lato(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Started at: ${DateFormat('hh:mm a').format(currentSession!.startTime)}",
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Elapsed: ${_formatElapsed(_elapsedSeconds)}",
                                  style: GoogleFonts.lato(
                                      fontSize: 15,
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _endSession,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: Size(0, 38),
                              elevation: 0,
                            ),
                            child: Text("End",
                                style: GoogleFonts.lato(
                                    fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                  ),
                ...games.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildGameCard(
                        icon: Icons.sports_esports,
                        title: g.name,
                        color: Color(0xFF287233),
                        price: g.pricePerHour,
                        onTap: currentSession == null
                            ? () => _startSession(g)
                            : null,
                      ),
                    )),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(items.length, (i) {
                      final item = items[i];
                      final color = Colors
                          .primaries[i % Colors.primaries.length].shade200;
                      final textColor = Colors
                          .primaries[i % Colors.primaries.length].shade800;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        child: Material(
                          color: color,
                          borderRadius: BorderRadius.circular(22),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _addPurchase(item),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fastfood,
                                      color: textColor, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    item.name,
                                    style: GoogleFonts.lato(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(width: 7),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    child: Text(
                                      "₹${item.price.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey[300],
                        thickness: 1.4,
                        endIndent: 10,
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 18, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.07),
                            blurRadius: 2,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_downward,
                          color: Colors.grey[400], size: 20),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey[300],
                        thickness: 1.4,
                        indent: 10,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 22),
                if (currentSession == null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _resetAll,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red[600],
                          minimumSize: Size(110, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: Colors.red[100]!, width: 2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh,
                                color: Colors.red[600], size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Reset',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: Colors.red[700],
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 18),
                      ElevatedButton(
                        onPressed: _showTotal,
                        style: ElevatedButton.styleFrom(
                          elevation: 2,
                          backgroundColor: Color(0xFF287233),
                          foregroundColor: Colors.white,
                          minimumSize: Size(120, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          shadowColor: Color(0xFF287233).withOpacity(0.18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.currency_rupee_rounded,
                                color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Total',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 20),
                Text(
                  'Created by Nadeem Khan · v1.0',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.blueGrey[400],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
