import 'package:flutter/material.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:provider/provider.dart';
import 'screens/main_shell.dart';
import 'controllers/encounter_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PlayerDataController>(
          create: (_) =>
              PlayerDataController()
                ..ensureLoaded().catchError((e, st) {
                  print("Error loading player data: $e\n$st");
                }),
        ),

        ChangeNotifierProvider<CraftingController>(
          create: (_) => CraftingController(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    PlayerDataController();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      //ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    PlayerDataController controller = context.watch<PlayerDataController>();
    if (PlayerDataController.instance.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return MainShell();
  }
}
