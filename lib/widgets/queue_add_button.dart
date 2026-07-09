import 'package:flutter/material.dart';

// small button that adds the screen's action to the action queue.
// sits next to the primary action button on action screens.
class QueueAddButton extends StatelessWidget {
  const QueueAddButton({super.key, required this.enabled, required this.onQueue});

  final bool enabled;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        icon: const Icon(Icons.playlist_add),
        tooltip: "Add to queue",
        onPressed: enabled
            ? () {
                onQueue();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Added to queue"),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            : null,
      ),
    );
  }
}
