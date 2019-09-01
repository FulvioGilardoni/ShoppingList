import 'package:flutter/material.dart';
import 'dart:async';

import '../widgets/shoppingitems/shoppingitems.dart';
import '../scoped-models/main.dart';
import '../utility.dart';
import 'AccountManager.dart';

class ShoppingListPage extends StatefulWidget {
  final MainModel _model;

  ShoppingListPage(this._model);

  @override
  State<StatefulWidget> createState() {
    return _ShoppingListPageState();
  }
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  bool _isSelected = false;
  StreamSubscription _shoppingListWatcher;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    widget._model.fetchShoppingItems();
    widget._model.selectShoppingItemSubject.listen((bool isSelected) {
      setState(() {
        _isSelected = isSelected;
      });
    });
    _shoppingListWatcher = widget._model
        .activateShoppingListListenUpdate((shoppingItem, changeType) {
      if (mounted) {
        setState(() {
          widget._model.updateShoppingItemFromRemote(shoppingItem, changeType);
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    if (_shoppingListWatcher != null) {
      _shoppingListWatcher.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('building ShoppingList page');
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista della spesa'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.share),
              tooltip: 'Condividi',
              onPressed: () {
                _gotoAccountManager(context);
              }),
          IconButton(
            icon: Icon(Icons.clear_all),
            tooltip: 'Cancella tutto',
            onPressed: () =>
                !_isSelected ? _deleteAllItems(context, widget._model) : null,
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('images/sfondo.jpg'),
          ),
        ),
        child: Center(
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            child: ShoppingItems(),
            onRefresh: refreshPage,
          ),
        ),
      ),
      floatingActionButton: _isSelected
          ? null
          : FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: widget._model.newLocalShoppingItem,
            ),
    );
  }

  void _gotoAccountManager(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return AccountManagerPage(widget._model);
        },
      ),
    );

    _refreshIndicatorKey.currentState.show();
  }

  Future<void> refreshPage() async {
    await widget._model.signInAnonymously();
    await widget._model.fetchShoppingItems();
  }

  void _deleteAllItems(BuildContext context, MainModel model) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Eliminare tutte le voci?'),
            content: Text(
                'L\'operazione eliminerà definitivamente tutte le voci di spesa.'),
            actions: <Widget>[
              FlatButton(
                child: Text('Annulla'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text('Continua'),
                onPressed: () {
                  Navigator.pop(context);
                  _executeDeleteAllItems(context, model);
                },
              )
            ],
          );
        });
  }

  void _executeDeleteAllItems(BuildContext context, MainModel model) async {
    bool ret = await model.deleteAllShoppingItem();
    if (!ret) {
      showErrorMessage(context, 'Server Error');
    }
  }
}
