// lib/models.dart

class Game {
  final String name;
  final double pricePerHour;
  Game({required this.name, required this.pricePerHour});
  Map<String, dynamic> toJson() => {'name': name, 'pricePerHour': pricePerHour};
  static Game fromJson(Map<String, dynamic> json) => Game(
        name: json['name'],
        pricePerHour: (json['pricePerHour'] as num).toDouble(),
      );
}

class PurchaseItem {
  final String name;
  final double price;
  PurchaseItem({required this.name, required this.price});
  Map<String, dynamic> toJson() => {'name': name, 'price': price};
  static PurchaseItem fromJson(Map<String, dynamic> json) => PurchaseItem(
        name: json['name'],
        price: (json['price'] as num).toDouble(),
      );
}

class GameSession {
  final String gameName;
  final DateTime startTime;
  final DateTime endTime;
  final bool isWon;
  final double pricePerHour;
  final double amount;

  GameSession({
    required this.gameName,
    required this.startTime,
    required this.endTime,
    required this.isWon,
    required this.pricePerHour,
    required this.amount,
  });
}

class Purchase {
  final String name;
  final double price;
  final DateTime time;

  Purchase({
    required this.name,
    required this.price,
    required this.time,
  });
}
