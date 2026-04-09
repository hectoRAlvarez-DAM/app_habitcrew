import 'package:flutter/foundation.dart';

class CoinService {
  static final CoinService instance = CoinService._internal();
  CoinService._internal();

  final ValueNotifier<int> coinsNotifier = ValueNotifier<int>(500);

  int get coins => coinsNotifier.value;

  void add(int amount) {
    coinsNotifier.value += amount;
  }

  bool spend(int amount) {
    if (coinsNotifier.value < amount) return false;
    coinsNotifier.value -= amount;
    return true;
  }
}
