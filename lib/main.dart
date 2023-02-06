import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber/providers/appdata.dart';
import 'package:uber/screens/loginPage.dart';
import 'package:uber/screens/mainPage.dart';
import 'package:uber/screens/registrationPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await FirebaseApp.configure(
    name: 'db2',
    options: Platform.isIOS
        ? const FirebaseOptions(
            googleAppID: '1:297855924061:ios:c6de2b69b03a5be8',
            gcmSenderID: '297855924061',
            databaseURL: 'https://flutterfire-cd2f7.firebaseio.com',
          )
        : const FirebaseOptions(
            googleAppID: '1:317618665445:android:fc244561b6bcf6b5afa10c',
            apiKey: 'AIzaSyCjDW8wKhVzZgGc8RuQrWj0okPUeihCKOY',
            databaseURL: 'https://uber-e176a-default-rtdb.firebaseio.com',
          ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: ((context) => AppData()),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          fontFamily: 'bolt-regular',
          primarySwatch: Colors.blue,
        ),
        initialRoute: LoginPage.id,
        routes: {
          RegistrationPage.id: (context) => RegistrationPage(),
          LoginPage.id: (context) => LoginPage(),
          MainPage.id: (context) => const MainPage(),
        },
      ),
    );
  }
}