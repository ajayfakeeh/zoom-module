import 'package:flutter/material.dart';

class ZoomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback leaveSession;

  const ZoomAppBar({super.key, required this.leaveSession});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        onPressed: leaveSession,
        icon: const Icon(Icons.close, color: Colors.white),
      ),
      centerTitle: true,
      actions: [
        ElevatedButton.icon(
          onPressed: leaveSession,
          icon: const Icon(Icons.call_end, color: Colors.white),
          label: const Text('Leave', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size(100, 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
