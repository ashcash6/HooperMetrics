// utils.dart

import 'package:flutter/material.dart';

const Color backgroundColor = Colors.black;
const Color accentColor = Colors.orangeAccent;

void showToast(BuildContext context, String message) {
  final snackBar = SnackBar(content: Text(message));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
