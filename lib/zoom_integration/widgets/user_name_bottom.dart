import 'package:flutter/material.dart';

class UserNameBottom extends StatelessWidget {
  final String userName;
  final double position;
  const UserNameBottom({super.key, required this.userName, required this.position});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: position,
      left: position,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
