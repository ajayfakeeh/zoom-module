import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String text;
  const LoadingWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.white),
        SizedBox(height: 16),
        Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}
