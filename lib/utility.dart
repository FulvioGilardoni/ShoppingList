import 'package:flutter/material.dart';

void showErrorMessage(BuildContext context, String msg) {
  Scaffold.of(context).showSnackBar(SnackBar(
    content: Text(
      msg,
      style: TextStyle(fontSize: 20.0),
    ),
    duration: Duration(seconds: 3),
  ));
}
