import 'dart:async';

import 'package:scoped_model/scoped_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/subjects.dart';

import '../models/shoppingitem.dart';
import '../models/useritem.dart';

mixin ConnectedModels on Model {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _firestore = Firestore.instance;

  UserItem _currentUserItem;

  String _lastError = "";

  String lastError() {
    return _lastError;
  }
}

mixin UserModel on ConnectedModels {
  PublishSubject<bool> _userAuthenticatedSubject = PublishSubject();
  PublishSubject<bool> get userAuthenticatedSubject {
    return _userAuthenticatedSubject;
  }

  PublishSubject<bool> _userInEditSubject = PublishSubject();
  PublishSubject<bool> get userInEditSubject {
    return _userInEditSubject;
  }

  PublishSubject<bool> _contactInEditSubject = PublishSubject();
  PublishSubject<bool> get contactInEditSubject {
    return _contactInEditSubject;
  }

  UserItem get currentUserItem {
    return _currentUserItem;
  }

  Future<Null> signInAnonymously() async {
    print('signInAnonymously');
    try {
      final FirebaseUser user = await _auth.signInAnonymously();
      final FirebaseUser currentUser = await _auth.currentUser();
      assert(user.uid == currentUser.uid);

      var u = await _firestore.collection('users').document(user.uid).get();
      if (u != null) {
        UserItem _tempUserItem = UserItem.fromFBMap(u.data, u.documentID);
        if (_tempUserItem.actualShoppingItemsList ==
            '') // non ho lista della spesa -> la creo
        {
          var l = await _firestore.collection('lists').document().get();
          if (l != null) {
            _tempUserItem.actualShoppingItemsList = l.documentID;
            _tempUserItem.personalShoppingItemsList = l.documentID;
          }
        }

        bool validUser;
        if (_tempUserItem.actualShoppingItemsList != "") {
          final UserItem _userItem = UserItem(
              userId: _tempUserItem.userId,
              userName: _tempUserItem.userName,
              actualShoppingItemsList: _tempUserItem.actualShoppingItemsList,
              personalShoppingItemsList: _tempUserItem.personalShoppingItemsList,
              contactId: _tempUserItem.contactId,
              contactEnabled: _tempUserItem.contactEnabled);

          validUser = await updateCurrentUser(_userItem);
        } else {
          validUser = true;
        }

        if (validUser) {
          _userAuthenticatedSubject.add(true);
        }
      }
    } catch (error) {
      _lastError = error.toString();
    }

    notifyListeners();
  }

  Future<bool> updateCurrentUser(UserItem _useritem) async {
    print('_updateCurrentUser');

    bool result = false;

    try {
      final TransactionHandler updateUser = (Transaction tx) async {
        final DocumentSnapshot ds = await tx
            .get(_firestore.collection('users').document(_useritem.userId));

        await tx.set(ds.reference, {
          'actualShoppingItemsList': _useritem.actualShoppingItemsList,
          'personalShoppingItemsList': _useritem.personalShoppingItemsList,
          'userName': _useritem.userName,
          'contactId': _useritem.contactId,
          'contactEnabled': _useritem.contactEnabled
        });

        return {'userUpdate': true};
      };

      var d = (await _firestore
              .collection('users')
              .where('userName', isEqualTo: _useritem.userName)
              .getDocuments())
          .documents;

      if ((d == null) ||
          (d.length == 0) ||
          (d[0].documentID == _useritem.userId) ||
          (_useritem.userName.isEmpty)) {
        await _firestore.runTransaction(updateUser);
        _currentUserItem = _useritem;
        result = true;
      }
    } catch (error) {
      _lastError = error;
    }

    notifyListeners();
    return result;
  }

  Future<bool> updateRemoteUser(UserItem _useritem) async {
    print('_updateRemoteUser');

    bool result = false;

    try {
      final TransactionHandler updateUser = (Transaction tx) async {
        final DocumentSnapshot ds = await tx
            .get(_firestore.collection('users').document(_useritem.userId));

        await tx.set(ds.reference, {
          'actualShoppingItemsList': _useritem.actualShoppingItemsList,
          'personalShoppingItemsList': _useritem.personalShoppingItemsList,
          'userName': _useritem.userName,
          'contactId': _useritem.contactId,
          'contactEnabled': _useritem.contactEnabled
        });

        return {'userUpdate': true};
      };

      var d = (await _firestore
              .collection('users')
              .where('userName', isEqualTo: _useritem.userName)
              .getDocuments())
          .documents;

      if ((d == null) ||
          (d.length == 0) ||
          (d[0].documentID == _useritem.userId)) {
        await _firestore.runTransaction(updateUser);
        result = true;
      }
    } catch (error) {
      _lastError = error;
    }

    notifyListeners();
    return result;
  }

  Future<String> getUserId(String userName) async {
    String result = '';

    try {
      final TransactionHandler getUserTx = (Transaction tx) async {
        String _documentId = '';
        var d = (await _firestore
                .collection('users')
                .where('userName', isEqualTo: userName)
                .getDocuments())
            .documents;
        if ((d != null) && (d.length > 0)) {
          _documentId = d[0].documentID;
        }

        var dataMap = new Map<String, dynamic>();
        dataMap['documentId'] = _documentId;

        return dataMap;
      };
      Map<String, dynamic> a = await _firestore.runTransaction(getUserTx);

      result = a['documentId'];
    } catch (error) {
      _lastError = error;
    }

    return result;
  }

  Future<UserItem> getUserItem(String userId) async {
    UserItem result;

    try {
      final TransactionHandler getUserTx = (Transaction tx) async {
        var dataMap = new Map<String, dynamic>();
        if (userId != "") {
          var d = await _firestore.collection('users').document(userId).get();
          if ((d != null) && (d.data != null)) {
            UserItem _tempUserItem = UserItem.fromFBMap(d.data, d.documentID);
            dataMap = _tempUserItem.toMap();
          }
        }
        return dataMap;
      };
      Map<String, dynamic> a = await _firestore.runTransaction(getUserTx);
      result = UserItem.fromFBMap(a, userId);
    } catch (error) {
      _lastError = error;
    }

    return result;
  }
}

mixin ShoppingItemModel on ConnectedModels {
  PublishSubject<bool> _selectShoppingItemSubject = PublishSubject();
  PublishSubject<bool> get selectShoppingItemSubject {
    return _selectShoppingItemSubject;
  }

  List<ShoppingItem> _shoppingItems = [];
  int __selShoppingItemIndex = -1;
  int _selShoppingItemIndexOrder = -1;

  bool _isShoppingItemSaving = false;
  bool _localupdateFireStoreData = false;

  int get selShoppingItemIndexOrder => _selShoppingItemIndexOrder;
  set _selShoppingItemIndex(int value) {
    __selShoppingItemIndex = value;
    if (value == -1) {
      _selShoppingItemIndexOrder = -1;
    } else {
      String documentId = _shoppingItems[value].documentId;
      _selShoppingItemIndexOrder =
          (allShoppingItemsOrdered.indexWhere((ShoppingItem shoppingItem) {
        return shoppingItem.documentId == documentId;
      }));
    }
    _selectShoppingItemSubject.add(value >= 0);
  }

  bool isShoppingItemSaving() {
    return _isShoppingItemSaving;
  }

  List<ShoppingItem> get allShoppingItemsOrdered {
    List<ShoppingItem> shoppingitemsList = List.from(_shoppingItems);
    shoppingitemsList.sort(((a, b) => ((a.isBuy && b.isBuy
        ? b.documentId.compareTo(a.documentId)
        : (a.isBuy && !b.isBuy
            ? 1
            : (!a.isBuy && b.isBuy
                ? -1
                : b.documentId.compareTo(a.documentId)))))));
    return shoppingitemsList;
  }

  Future<Null> fetchShoppingItems() async {
    print('fetchShoppingItems');
    try {
      final List<ShoppingItem> fetchedShoppingItemList = [];
      if (_currentUserItem != null) {
        var d = (await _firestore
                .collection('lists')
                .document(_currentUserItem.actualShoppingItemsList)
                .collection('items')
                .getDocuments())
            .documents;
        if (d != null) {
          d.forEach((value) {
            final ShoppingItem shoppingItem = ShoppingItem(
                documentId: value.documentID,
                description: value['description'] ?? '',
                infoQta: value['infoQta'] ?? '',
                isBuy: value['isBuy'] ?? false);
            fetchedShoppingItemList.add(shoppingItem);
          });
        }
      }
      _shoppingItems = fetchedShoppingItemList;
    } catch (error) {}

    _selShoppingItemIndex = -1;
    notifyListeners();

    return;
  }

  Future<bool> toogleIsBuy(String documentId) async {
    print('toogleIsBuy');
    bool result = false;
    _localupdateFireStoreData = true;

    final int index = (_shoppingItems.indexWhere((ShoppingItem shoppingItem) {
      return shoppingItem.documentId == documentId;
    }));

    if (index >= 0) {
      final oldIsBuy = _shoppingItems[index].isBuy;
      _shoppingItems[index].isBuy = !_shoppingItems[index].isBuy;
      notifyListeners();

      try {
        final TransactionHandler isBuyTransaction = (Transaction tx) async {
          final DocumentSnapshot ds = await tx.get(_firestore
              .collection('lists')
              .document(_currentUserItem.actualShoppingItemsList)
              .collection('items')
              .document(documentId));

          await tx.update(ds.reference, {'isBuy': _shoppingItems[index].isBuy});
          return {'ToggleIsBuy': true};
        };

        await _firestore.runTransaction(isBuyTransaction);
        result = true;
      } catch (error) {
        _shoppingItems[index].isBuy = oldIsBuy;
        notifyListeners();
      }
    }

    _localupdateFireStoreData = false;
    return result;
  }

  Future<bool> deleteShoppingItem(String documentId) async {
    print('deleteShoppingItem');
    bool result = false;
    _localupdateFireStoreData = true;

    final int index = (_shoppingItems.indexWhere((ShoppingItem shoppingItem) {
      return shoppingItem.documentId == documentId;
    }));

    if (index >= 0) {
      try {
        final TransactionHandler deleteTransaction = (Transaction tx) async {
          final DocumentSnapshot ds = await tx.get(_firestore
              .collection('lists')
              .document(_currentUserItem.actualShoppingItemsList)
              .collection('items')
              .document(documentId));

          await tx.delete(ds.reference);
          return {'deleted': true};
        };

        await _firestore.runTransaction(deleteTransaction);

        _shoppingItems.removeAt(index);
        result = true;
      } catch (error) {}
    }

    notifyListeners();

    _localupdateFireStoreData = false;
    return result;
  }

  Future<bool> deleteAllShoppingItem() async {
    print('deleteAllShoppingItem');
    bool result = false;
    _localupdateFireStoreData = true;

    try {
      final TransactionHandler deleteTransaction = (Transaction tx) async {
        final ds = (await _firestore
                .collection('lists')
                .document(_currentUserItem.actualShoppingItemsList)
                .collection('items')
                .getDocuments())
            .documents;

        if (ds != null) {
          for (var d in ds) {
            await tx.delete(d.reference);
          }
        }
        return {'deleted': true};
      };

      await _firestore.runTransaction(deleteTransaction);

      _shoppingItems.clear();
      result = true;
    } catch (error) {}

    notifyListeners();

    _localupdateFireStoreData = false;
    return result;
  }

  Future<bool> nullifySelectedShoppingItem() async {
    print('nullifySelectedShoppingItem');
    if (__selShoppingItemIndex >= 0) {
      if (_shoppingItems[__selShoppingItemIndex].documentId == 'new') {
        _shoppingItems.removeAt(__selShoppingItemIndex);
      }
    }
    _selShoppingItemIndex = -1;
    notifyListeners();

    return true;
  }

  Future<bool> saveShoppingItem(ShoppingItem _shoppingItem) async {
    print('saveShoppingItem');
    bool result = false;
    _localupdateFireStoreData = true;

    _isShoppingItemSaving = true;
    notifyListeners();

    final int index = (_shoppingItems.indexWhere((ShoppingItem shoppingItem) {
      return shoppingItem.documentId == _shoppingItem.documentId;
    }));

    if (index >= 0) {
      try {
        final bool isUpdate = (_shoppingItem.documentId != 'new');

        final TransactionHandler createTransaction = (Transaction tx) async {
          final DocumentSnapshot ds = await tx.get(_firestore
              .collection('lists')
              .document(_currentUserItem.actualShoppingItemsList)
              .collection('items')
              .document(isUpdate
                  ? _shoppingItems[__selShoppingItemIndex].documentId
                  : null));

          await tx.set(ds.reference, {
            'description': _shoppingItem.description,
            'infoQta': _shoppingItem.infoQta,
            'isBuy': _shoppingItem.isBuy
          });

          var dataMap = new Map<String, dynamic>();
          dataMap['documentId'] = ds.documentID;
          dataMap['description'] = _shoppingItem.description;
          dataMap['infoQta'] = _shoppingItem.infoQta;
          dataMap['isBuy'] = _shoppingItem.isBuy;

          return dataMap;
        };

        Map<String, dynamic> a =
            await _firestore.runTransaction(createTransaction);

        final ShoppingItem shoppingItem = ShoppingItem(
            documentId: a['documentId'],
            description: a['description'],
            infoQta: a['infoQta'],
            isBuy: a['isBuy']);

        _shoppingItems[index] = shoppingItem;
        _selShoppingItemIndex = -1;
        result = true;
      } catch (error) {}
    }

    _selShoppingItemIndex = -1;
    _isShoppingItemSaving = false;
    notifyListeners();

    _localupdateFireStoreData = false;
    return result;
  }

  void newLocalShoppingItem() {
    print('newLocalShoppingItem');

    final ShoppingItem shoppingItem = ShoppingItem(
        documentId: 'new', description: '', infoQta: '', isBuy: false);
    _shoppingItems.insert(0, shoppingItem); // aggiungo in testa alla lista!
    _selShoppingItemIndex = 0;

    notifyListeners();
  }

  void selectShoppingItem(String documentId) {
    print('selectShoppingItem');

    if (__selShoppingItemIndex == -1) {
      final int index = (_shoppingItems.indexWhere((ShoppingItem shoppingItem) {
        return shoppingItem.documentId == documentId;
      }));

      if (index >= 0) {
        _selShoppingItemIndex = index;
      }
    }
  }

  StreamSubscription activateShoppingListListenUpdate(
      void onChange(
          ShoppingItem shoppingItem, DocumentChangeType documentChangeType)) {
    if (_currentUserItem != null) {
      return _firestore
          .collection('lists')
          .document(_currentUserItem.actualShoppingItemsList)
          .collection('items')
          .snapshots()
          .listen((snapshot) {
        snapshot.documentChanges.forEach((value) {
          String documentId = value.document.documentID;
          Map<String, dynamic> data = value.document.data;
          final ShoppingItem shoppingItem = ShoppingItem(
              documentId: documentId,
              description: data['description'] ?? '',
              infoQta: data['infoQta'] ?? '',
              isBuy: data['isBuy'] ?? false);
          onChange(shoppingItem, value.type);
        });
      });
    }
    return null;
  }

  void updateShoppingItemFromRemote(
      ShoppingItem lshoppingItem, DocumentChangeType changeType) {
    final int index = (_shoppingItems.indexWhere((ShoppingItem shoppingItem) {
      return shoppingItem.documentId == lshoppingItem.documentId;
    }));
    if (!_localupdateFireStoreData) {
      if ((changeType == DocumentChangeType.removed) && (index >= 0)) {
        _shoppingItems.removeAt(index);
      } else {
        final ShoppingItem shoppingItem = ShoppingItem(
            documentId: lshoppingItem.documentId,
            description: lshoppingItem.description,
            infoQta: lshoppingItem.infoQta,
            isBuy: lshoppingItem.isBuy);

        if ((changeType == DocumentChangeType.modified) && (index >= 0)) {
          // update element
          _shoppingItems[index] = shoppingItem;
        } else if (changeType == DocumentChangeType.added) {
          _shoppingItems.add(shoppingItem);
        }
      }
    }
    _selShoppingItemIndex = -1;
  }
}
