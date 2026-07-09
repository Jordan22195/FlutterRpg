import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/action_queue_controller.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/primary_button.dart';

/*
queue screen contents:
-header with title and clear-all button
-reorderable list of queued tasks (icon, name, zone, remove button)
-the running task is highlighted
-run/stop buttons pinned to the bottom
*/

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<ActionQueueController>();
    final tasks = queue.tasks;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Action Queue",
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (tasks.isNotEmpty)
                    TextButton(
                      onPressed: () => queue.clearQueue(),
                      child: const Text("Clear"),
                    ),
                ],
              ),
            ),

            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.playlist_add,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Queue is empty",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Use the queue button on an entity,\n"
                            "crafting, or explore screen to add tasks.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: tasks.length,
                      onReorder: queue.reorderTask,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final isActive = queue.isActiveTask(task);
                        return Card(
                          key: ObjectKey(task),
                          shape: isActive
                              ? RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : null,
                          child: ListTile(
                            leading: IconRenderer(
                              size: 40,
                              id: queue.taskIconId(task),
                            ),
                            title: Text(queue.taskTitle(task)),
                            subtitle: Text(
                              isActive
                                  ? "Running · ${queue.taskSubtitle(task)}"
                                  : queue.taskSubtitle(task),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => queue.removeTaskAt(index),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.drag_handle),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: MomentumPrimaryButton(
                    enabled: tasks.isNotEmpty,
                    label: "Run Queue",
                    startActionFunction: () {
                      queue.startQueue();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const StopPrimaryButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
