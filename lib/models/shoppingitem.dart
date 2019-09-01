import 'package:flutter/material.dart';

class ShoppingItem {
  final String documentId;
  String description;
  String infoQta;
  bool isBuy;

  ShoppingItem(
      {@required this.documentId,
      @required this.description,
      @required this.infoQta,
      @required this.isBuy});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'documentiId': documentId,
      'description': description,
      'infoQta': infoQta,
      'isBuy': isBuy,
    };
  }
}