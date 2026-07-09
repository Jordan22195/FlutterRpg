import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/data/action_queue_data.dart';
import 'package:rpg/game_session.dart';

// lets pending microtasks run (the queue advances in a microtask)
Future<void> flushMicrotasks() => Future<void>(() {});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    return factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  test('queue runs tasks in order and advances when an action stops', () async {
    final session = buildSession();
    final save = session.saveGameData;
    final queue = session.actionQueueController;
    final timing = session.actionTimingController;

    // discover a tree in the current zone so the encounter can start
    session.worldService.addEntityToCurrentZone(
      EntityId.TREE,
      3,
      session.catalogBundle.entityCatalog,
      save.playerData,
      save.worldData,
    );

    queue.enqueueEncounter(EntityId.TREE);
    queue.enqueueExplore();
    expect(queue.tasks.length, 2);

    queue.startQueue();
    expect(queue.isQueueActive, isTrue);
    expect(timing.isRunning, isTrue);
    expect(queue.activeTask!.type, QueuedTaskType.ENCOUNTER);

    // the tree runs out: the encounter action stops the timing loop.
    // the queue treats a stop it didn't cause as the task finishing
    timing.stop();
    await flushMicrotasks();

    expect(queue.isQueueActive, isTrue);
    expect(timing.isRunning, isTrue);
    expect(queue.tasks.length, 1);
    expect(queue.activeTask!.type, QueuedTaskType.EXPLORE);

    session.dispose();
  });

  test('unstartable tasks are skipped', () async {
    final session = buildSession();
    final queue = session.actionQueueController;
    final timing = session.actionTimingController;

    // goblin was never discovered in this zone: the task can't start
    queue.enqueueEncounter(EntityId.GOBLIN);
    queue.enqueueExplore();

    queue.startQueue();
    expect(queue.tasks.length, 1);
    expect(queue.activeTask!.type, QueuedTaskType.EXPLORE);
    expect(timing.isRunning, isTrue);

    session.dispose();
  });

  test('stopping the queue keeps remaining tasks for a later resume', () {
    final session = buildSession();
    final queue = session.actionQueueController;
    final timing = session.actionTimingController;

    queue.enqueueExplore();
    queue.startQueue();
    expect(timing.isRunning, isTrue);

    queue.stopQueue();
    expect(queue.isQueueActive, isFalse);
    expect(timing.isRunning, isFalse);
    expect(queue.tasks.length, 1);

    session.dispose();
  });

  test('manually starting an action hands control back to the player', () async {
    final session = buildSession();
    final save = session.saveGameData;
    final queue = session.actionQueueController;
    final timing = session.actionTimingController;

    session.worldService.addEntityToCurrentZone(
      EntityId.TREE,
      3,
      session.catalogBundle.entityCatalog,
      save.playerData,
      save.worldData,
    );

    queue.enqueueEncounter(EntityId.TREE);
    queue.startQueue();
    expect(queue.activeTask, isNotNull);

    // player starts exploring by hand: stop + start in one call chain
    session.worldController.startExplore();
    await flushMicrotasks();

    expect(queue.isQueueActive, isFalse);
    expect(queue.activeTask, isNull);
    // the interrupted task stays queued
    expect(queue.tasks.length, 1);
    expect(timing.isRunning, isTrue);

    session.dispose();
  });

  test('finishing the last task deactivates the queue', () async {
    final session = buildSession();
    final queue = session.actionQueueController;
    final timing = session.actionTimingController;

    queue.enqueueExplore();
    queue.startQueue();
    expect(timing.isRunning, isTrue);

    timing.stop();
    await flushMicrotasks();

    expect(queue.isQueueActive, isFalse);
    expect(queue.tasks, isEmpty);
    expect(timing.isRunning, isFalse);

    session.dispose();
  });
}
