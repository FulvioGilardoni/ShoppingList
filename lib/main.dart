import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import 'scoped-models/main.dart';

import 'pages/NotAuth.dart';
import 'pages/ShoppingList.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  bool _isAuthenticated = false;
  final MainModel _model = MainModel();

  @override
  void initState() {
    _model.signInAnonymously();
    _model.userAuthenticatedSubject.listen((bool isAuthenticated) {
      setState(() {
        _isAuthenticated = isAuthenticated;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('building main page');
    return ScopedModel<MainModel>(
      model: _model,
      child: MaterialApp(
        title: 'Lista della spesa',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: _isAuthenticated ? ShoppingListPage(_model) : NotAuthPage(),
      ),
    );
  }
}
