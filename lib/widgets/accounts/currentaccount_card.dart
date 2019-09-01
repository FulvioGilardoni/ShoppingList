import 'package:flutter/material.dart';
import '../../scoped-models/main.dart';
import '../../utility.dart';
import '../../models/useritem.dart';

class CurrentAccountCard extends StatefulWidget {
  final MainModel _model;
  final bool _isUserNameInEdit;

  CurrentAccountCard(this._model, this._isUserNameInEdit);

  @override
  State<StatefulWidget> createState() {
    return _CurrentAccountCardState();
  }
}

class _CurrentAccountCardState extends State<CurrentAccountCard> {  
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    _usernameController.text = widget._model.currentUserItem.userName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('building CurrentAccountCard');

    return Card(
      color: Colors.white70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.account_circle, size: 50.0),
            title: TextField(
              decoration: InputDecoration(labelText: 'Utente'),
              style: TextStyle(
                fontSize: 25.0,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              controller: _usernameController,
              onTap: () {
                widget._model.userInEditSubject.add(true);
              },
            ),
          ),
          ButtonTheme.bar(
            child: ButtonBar(
              children: <Widget>[
                FlatButton(
                  child: Text('Salva'),
                  onPressed: widget._isUserNameInEdit ? _saveUserName : null,
                ),
                FlatButton(
                  child: Text('Annulla'),
                  onPressed: widget._isUserNameInEdit ? _cancelUserName : null,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _saveUserName() async {
    bool result = true;
    removeFocusOnUserName();
    if (_usernameController.text.trim().isNotEmpty) {
      UserItem _userItem = widget._model.currentUserItem;
      _userItem.userName = _usernameController.text;
      result = await widget._model.updateCurrentUser(_userItem);
    }
    else{
      _usernameController.text = widget._model.currentUserItem.userName;
    }
    if (!result) {
      showErrorMessage(context, 'Aggiornamento utente fallito');
    }    
  }

  void _cancelUserName() {
    _usernameController.text = widget._model.currentUserItem.userName;
    removeFocusOnUserName();
  }

  void removeFocusOnUserName() {
    FocusScope.of(context).requestFocus(new FocusNode());
    widget._model.userInEditSubject.add(false);
  }
}
