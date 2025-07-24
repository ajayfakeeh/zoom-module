import 'package:flutter/material.dart';

class LeaveSessionPopup extends StatelessWidget {
  const LeaveSessionPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      title: Row(
        children: [
          Icon(Icons.exit_to_app, color: Colors.red),
          SizedBox(width: 8),
          const Text(
            'Leave Session',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to leave the session?',
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Row(
                children: const [
                  Icon(Icons.cancel, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    'Cancel',
                    style: TextStyle(color: Colors.orange, fontSize: 16),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Row(
                children: const [
                  Icon(Icons.check, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Yes',
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
