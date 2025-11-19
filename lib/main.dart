import 'package:flutter/material.dart';
import 'package:squire/di/locator.dart';
import 'package:provider/provider.dart';
import 'package:squire/view_models/home_view_model.dart';
import 'package:squire/view/home_screen.dart';
import 'package:squire/data/repositories/unit_repository.dart';

void main() {
  setupLocator();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(repository: locator<UnitRepository>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
