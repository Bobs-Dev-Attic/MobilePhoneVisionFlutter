import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastWidget {
  static void show(
    String message, {
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: backgroundColor,
      textColor: textColor,
      gravity: gravity,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  static void showError(String message) {
    show(message, backgroundColor: Colors.redAccent);
  }

  static void showSuccess(String message) {
    show(message, backgroundColor: Colors.green);
  }

  static void showWarning(String message) {
    show(message, backgroundColor: Colors.orange, gravity: ToastGravity.TOP);
  }
}
