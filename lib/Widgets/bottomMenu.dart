import 'package:app_habitcrew/Screen/create.dart';
import 'package:app_habitcrew/Screen/home.dart';
import 'package:app_habitcrew/Screen/profile.dart';
import 'package:app_habitcrew/Screen/quests.dart';
import 'package:app_habitcrew/Screen/shop.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

class BottomMenu extends StatelessWidget {
  final int currentIndex;

  const BottomMenu({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 0, 0),
        border: const Border(
          top: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _menuButton(
            context,
            index: 0,
            icon: currentIndex == 0 ? Mdi.home : Mdi.home_outline,
            page: const Home(),
          ),
          _menuButton(
            context,
            index: 1,
            icon: currentIndex == 1 ? Mdi.trophy : Mdi.trophy_outline,
            page: const Quests(),
          ),
          _menuButton(
            context,
            index: 2,
            icon: currentIndex == 2 ? Mdi.add_circle : Mdi.add_circle_outline,
            page: const Create(),
            size: 50,
          ),
          _menuButton(
            context,
            index: 3,
            icon: currentIndex == 3 ? Mdi.shopping : Mdi.shopping_outline,
            page: const Shop(),
          ),
          _menuButton(
            context,
            index: 4,
            icon: currentIndex == 4 ? Mdi.account : Mdi.account_outline,
            page: const Profile(),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(
    BuildContext context, {
    required int index,
    required String icon,
    required Widget page,
    double size = 40,
  }) {
    final bool isActive = currentIndex == index;

    return IconButton(
      icon: Iconify(
        icon,
        size: size,
        color: isActive ? Colors.blue : Colors.green,
      ),
      onPressed: () {
        if (!isActive) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        }
      },
    );
  }
}
