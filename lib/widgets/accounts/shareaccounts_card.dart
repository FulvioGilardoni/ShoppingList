import 'package:flutter/material.dart';
import '../../scoped-models/main.dart';
import '../../utility.dart';
import '../../models/useritem.dart';

class SharedAccountsCard extends StatefulWidget {
  final MainModel _model;
  final bool _isContactNameInEdit;

  SharedAccountsCard(this._model, this._isContactNameInEdit);

  @override
  State<StatefulWidget> createState() {
    return _SharedAccountsCardState();
  }
}

class _SharedAccountsCardState extends State<SharedAccountsCard> {
  final TextEditingController _sharedNameController = TextEditingController();

  @override
  void initState() {
    _setDefaultContactName();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('building SharedAccountsCard');

    return Card(
      color: Colors.white70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: (widget._model.currentUserItem.contactId.isNotEmpty)
                ? IconButton(
                    iconSize: 40.0,
                    icon: Icon(
                      widget._model.currentUserItem.contactEnabled
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                    onPressed: _toogleContact,
                  )
                : null,
            title: TextField(
              decoration: InputDecoration(labelText: 'Contatto'),
              style: TextStyle(
                fontSize: 25.0,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              controller: _sharedNameController,
              onTap: () {
                widget._model.contactInEditSubject.add(true);
              },
            ),
          ),
          ButtonTheme.bar(
            child: ButtonBar(
              children: <Widget>[
                FlatButton(
                  child: Text('Salva'),
                  onPressed: widget._isContactNameInEdit ? _saveContact : null,
                ),
                FlatButton(
                  child: Text('Annulla'),
                  onPressed:
                      widget._isContactNameInEdit ? _cancelContact : null,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _saveContact() async {
    bool result = false;
    String oldContactId;
    _removeFocusOnContact();
    if (_sharedNameController.text.trim().isNotEmpty) {
      String _contactId =
          await widget._model.getUserId(_sharedNameController.text.trim());
      if (_contactId != '') {
        UserItem _userItem = widget._model.currentUserItem;
        // actualShoppingItemsList, personalShoppingItemsList le lascio inalterate
        oldContactId = _userItem.contactId;
        _userItem.contactId = _contactId;
        _userItem.contactEnabled = true;  // abilito sempre il contatto!
        result = await widget._model.updateCurrentUser(_userItem);

        if (result) {
          _userItem = await widget._model.getUserItem(_contactId);
          _userItem.contactId = widget._model.currentUserItem.userId;
          if (oldContactId != _contactId) {
            // nuovo legame
            _userItem.contactEnabled = false;
          } // else vecchio legame -> lascio così come è
          result = await widget._model.updateRemoteUser(_userItem);
        }
      }
    }
    if (!result) {
      _setDefaultContactName();
      showErrorMessage(context, 'Aggiornamento utente fallito');
    }
  }

  void _toogleContact() async {
    bool result = false;
    if (widget._model.currentUserItem.contactId.isNotEmpty) {
      UserItem _userItem = widget._model.currentUserItem;
      UserItem _contactUserItem = await widget._model.getUserItem(_userItem.contactId);      
      _userItem.contactEnabled = !_userItem.contactEnabled;
      if ((!_userItem.contactEnabled) || (!_contactUserItem.contactEnabled)) {
        _userItem.actualShoppingItemsList = _userItem.personalShoppingItemsList;
        _contactUserItem.actualShoppingItemsList = _contactUserItem.personalShoppingItemsList;
      }
      else  // entrambi i contatti sono abilitati -> ultimo abilitato è il locale 
      {
        _userItem.actualShoppingItemsList = _contactUserItem.personalShoppingItemsList;
        _contactUserItem.actualShoppingItemsList = _contactUserItem.personalShoppingItemsList;
      }
      result = await widget._model.updateCurrentUser(_userItem);
      result = result & await widget._model.updateRemoteUser(_contactUserItem);
    }
    if (!result) {
      _setDefaultContactName();
      showErrorMessage(context, 'Aggiornamento utente fallito');
    }
  }

  void _cancelContact() {
    _setDefaultContactName();
    _removeFocusOnContact();
  }

  void _removeFocusOnContact() {
    FocusScope.of(context).requestFocus(new FocusNode());
    widget._model.contactInEditSubject.add(false);
  }

  void _setDefaultContactName() async {
    UserItem u = await widget._model
        .getUserItem(widget._model.currentUserItem.contactId);
    _sharedNameController.text = u.userName;
  }
}
