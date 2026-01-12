import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static final EnvConfig _instance = EnvConfig._internal();

  factory EnvConfig() {
    return _instance;
  }

  EnvConfig._internal();

  //? Load environment variables once
  Future<void> load({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName);
  }

  //? Get a value from environment
  String? get(String key) => dotenv.env[key];

  //? Get a value with a default fallback
  String getOrDefault(String key, String defaultValue) {
    return dotenv.env[key] ?? defaultValue;
  }

  //? Check if a key exists
  bool isDefined(String key) => dotenv.env.containsKey(key);

  //? Check if multiple keys exist
  bool areAllDefined(List<String> keys) {
    return keys.every((key) => dotenv.env.containsKey(key));
  }
}