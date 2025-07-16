// lib/settings.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models.dart';

class SettingsScreen extends StatefulWidget {
  final List<Game> games;
  final List<PurchaseItem> items;
  final Future<void> Function(List<Game>, List<PurchaseItem>) onSave;

  const SettingsScreen({
    Key? key,
    required this.games,
    required this.items,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late List<TextEditingController> gameNameControllers;
  late List<TextEditingController> gamePriceControllers;
  late List<TextEditingController> itemNameControllers;
  late List<TextEditingController> itemPriceControllers;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    gameNameControllers =
        widget.games.map((g) => TextEditingController(text: g.name)).toList();
    gamePriceControllers = widget.games
        .map((g) =>
            TextEditingController(text: g.pricePerHour.toStringAsFixed(0)))
        .toList();
    itemNameControllers =
        widget.items.map((i) => TextEditingController(text: i.name)).toList();
    itemPriceControllers = widget.items
        .map((i) => TextEditingController(text: i.price.toStringAsFixed(0)))
        .toList();
  }

  void _addGame() {
    setState(() {
      gameNameControllers.add(TextEditingController());
      gamePriceControllers.add(TextEditingController());
    });
  }

  void _removeGame(int i) {
    setState(() {
      gameNameControllers.removeAt(i);
      gamePriceControllers.removeAt(i);
    });
  }

  void _addItem() {
    setState(() {
      itemNameControllers.add(TextEditingController());
      itemPriceControllers.add(TextEditingController());
    });
  }

  void _removeItem(int i) {
    setState(() {
      itemNameControllers.removeAt(i);
      itemPriceControllers.removeAt(i);
    });
  }

  Widget _cardWrapper({required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF287233),
        bottom: TabBar(
          controller: tabController,
          indicatorColor: Color(0xFF287233),
          tabs: [
            Tab(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_esports, color: Color(0xFF287233), size: 20),
                SizedBox(width: 7),
                Text("Games", style: TextStyle(color: Color(0xFF287233))),
              ],
            )),
            Tab(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart, color: Colors.blue, size: 20),
                SizedBox(width: 7),
                Text("Purchases", style: TextStyle(color: Colors.blue)),
              ],
            )),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          // Games Tab
          ListView(
            padding: EdgeInsets.all(22),
            children: [
              Text(
                "Game Types & Prices",
                style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF287233)),
              ),
              SizedBox(height: 12),
              ...List.generate(
                  gameNameControllers.length,
                  (i) => _cardWrapper(
                        child: ListTile(
                          leading: Icon(Icons.sports_esports,
                              color: Color(0xFF287233)),
                          title: TextField(
                            controller: gameNameControllers[i],
                            decoration: InputDecoration(
                              labelText: "Game Name",
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          trailing: SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: gamePriceControllers[i],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: "₹/hr",
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    style: GoogleFonts.lato(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16),
                                  ),
                                ),
                                if (gameNameControllers.length > 1)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        color: Colors.red[300]),
                                    onPressed: () => _removeGame(i),
                                    tooltip: 'Delete Game',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )),
              OutlinedButton.icon(
                onPressed: _addGame,
                icon: Icon(Icons.add, color: Color(0xFF287233)),
                label: Text("Add Game",
                    style: GoogleFonts.lato(color: Color(0xFF287233))),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF287233)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
              ),
              SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: () async {
                  final gs = <Game>[];
                  for (int i = 0; i < gameNameControllers.length; i++) {
                    final name = gameNameControllers[i].text.trim();
                    final price =
                        double.tryParse(gamePriceControllers[i].text) ?? 0;
                    if (name.isNotEmpty && price > 0)
                      gs.add(Game(name: name, pricePerHour: price));
                  }
                  await widget.onSave(gs, widget.items);
                  if (mounted) Navigator.pop(context);
                },
                icon: Icon(Icons.save),
                label: Text(
                  'Save Games',
                  style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF287233),
                  foregroundColor: Colors.white,
                  minimumSize: Size(140, 48),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),

          // Purchases Tab
          ListView(
            padding: EdgeInsets.all(22),
            children: [
              Text(
                "Available Purchases",
                style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue[900]),
              ),
              SizedBox(height: 12),
              ...List.generate(
                  itemNameControllers.length,
                  (i) => _cardWrapper(
                        child: ListTile(
                          leading:
                              Icon(Icons.fastfood, color: Colors.blue[700]),
                          title: TextField(
                            controller: itemNameControllers[i],
                            decoration: InputDecoration(
                              labelText: "Item Name",
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          trailing: SizedBox(
                            width: 90,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: itemPriceControllers[i],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: "₹",
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    style: GoogleFonts.lato(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16),
                                  ),
                                ),
                                if (itemNameControllers.length > 1)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        color: Colors.red[300]),
                                    onPressed: () => _removeItem(i),
                                    tooltip: 'Delete Item',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )),
              OutlinedButton.icon(
                onPressed: _addItem,
                icon: Icon(Icons.add, color: Colors.blue[700]),
                label: Text("Add Item",
                    style: GoogleFonts.lato(color: Colors.blue[700])),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue[700]!),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
              ),
              SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: () async {
                  final its = <PurchaseItem>[];
                  for (int i = 0; i < itemNameControllers.length; i++) {
                    final name = itemNameControllers[i].text.trim();
                    final price =
                        double.tryParse(itemPriceControllers[i].text) ?? 0;
                    if (name.isNotEmpty && price > 0)
                      its.add(PurchaseItem(name: name, price: price));
                  }
                  await widget.onSave(widget.games, its);
                  if (mounted) Navigator.pop(context);
                },
                icon: Icon(Icons.save),
                label: Text(
                  'Save Purchases',
                  style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  minimumSize: Size(140, 48),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
