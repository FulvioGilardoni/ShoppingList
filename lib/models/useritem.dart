import 'package:flutter/material.dart';

class UserItem {
  String userId;
  String userName;
  String actualShoppingItemsList;
  String personalShoppingItemsList;
  String contactId;
  bool contactEnabled;

  UserItem(
      {@required this.userId,
      @required this.userName,
      @required this.actualShoppingItemsList,
      @required this.personalShoppingItemsList,
      @required this.contactId,
      @required this.contactEnabled});

  UserItem.fromFBMap(Map<String, dynamic> mapData, String userid) {
    userId = userid;
    userName = mapData != null ? (mapData['userName'] ?? '') : '';
    actualShoppingItemsList =
        mapData != null ? (mapData['actualShoppingItemsList'] ?? '') : '';
    personalShoppingItemsList = mapData != null
        ? (mapData['personalShoppingItemsList'] ?? actualShoppingItemsList)
        : '';
    contactId = mapData != null ? (mapData['contactId'] ?? '') : '';
    contactEnabled =
        mapData != null ? (mapData['contactEnabled'] ?? false) : false;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'actualShoppingItemsList': actualShoppingItemsList,
      'personalShoppingItemsList': personalShoppingItemsList,
      'contactId': contactId,
      'contactEnabled': contactEnabled
    };
  }
}
