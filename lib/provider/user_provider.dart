import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  User? user;

  void setUser(User? newUser) {
    user = newUser;
    notifyListeners();
  }

  User? getUser() {
    return user;
  }
}