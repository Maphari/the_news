import 'package:the_news/model/auth_userdata_model.dart';

//?
class AuthResultsModel {
  final bool success;
  final String? token;
  final AuthUserdataModel? user;
  final String? error;
  
  AuthResultsModel({
    required this.success,
    this.token,
    this.user,
    this.error,
  });
}
