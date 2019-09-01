import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../scoped-models/main.dart';
import '../widgets/accounts/currentaccount_card.dart';
import '../widgets/accounts/shareaccounts_card.dart';

class AccountManagerPage extends StatefulWidget {
  final MainModel _model;

  AccountManagerPage(this._model);

  @override
  State<StatefulWidget> createState() {
    return _AccountManagerPageState();
  }
}

class _AccountManagerPageState extends State<AccountManagerPage> {
  bool _isUserEditing = false;
  bool _isContactEditing = false;

  @override
  void initState() {
    widget._model.userInEditSubject.listen((bool isEditing) {
      setState(() {
        _isUserEditing = isEditing;
        _isContactEditing = _isContactEditing & (!_isUserEditing);
      });
    });
    widget._model.contactInEditSubject.listen((bool isEditing) {
      setState(() {
        _isContactEditing = isEditing;
        _isUserEditing = _isUserEditing & (!_isContactEditing);
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('building AccountManagerPage page');
    return WillPopScope(
      onWillPop: () {
        print('back button into AccountManagerPage pressed');
        Navigator.pop(context, false);
        return Future.value(false);
      },
      child: ScopedModelDescendant<MainModel>(
          builder: (BuildContext context, Widget child, MainModel model) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Utenze'),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.home),
                onPressed: () => Navigator.pop(context, false),
              )
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
              child: ListView(
                children: <Widget>[
                  CurrentAccountCard(widget._model, _isUserEditing),
                  SharedAccountsCard(widget._model, _isContactEditing),
                ],
              ),
            ),
          ),
          /*
          floatingActionButton:
              ((widget._model.currentUserItem.userName == '') ||
                      (widget._model.contactNumber > 0) ||
                      (_isEditing))
                  ? null
                  : FloatingActionButton(
                      child: Icon(Icons.add),
                      onPressed: widget._model.newLocalContactItem,
                    ), */
        );
      }),
    );
  }
}
