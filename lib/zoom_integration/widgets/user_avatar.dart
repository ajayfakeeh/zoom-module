import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String userName;
  final bool isMainView;
  final bool? isTabView;

  const UserAvatar({
    Key? key,
    required this.userName,
    this.isMainView = false,
    this.isTabView,
  }) : super(key: key);

  static final List<Color> _colors = [
    Colors.redAccent.shade200,
    Colors.blueAccent.shade200,
    Colors.green.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.teal.shade300,
    Colors.indigo.shade300,
    Colors.cyan.shade300,
    Colors.deepOrange.shade300,
  ];

  Color _getRandomColor(String seed) {
    final index = seed.codeUnitAt(0) % _colors.length;
    return _colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final double avatarSize = isMainView
        ? 80
        : (isTabView == true ? 30 : 40);

    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    final bgColor = _getRandomColor(userName);

    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white70,
                  width: 2.0,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: bgColor,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: avatarSize / 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userName,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMainView ? 18 : 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
