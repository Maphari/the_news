import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:the_news/firebase_options.dart';

void initFirebase() async {
  //? Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  //? Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}