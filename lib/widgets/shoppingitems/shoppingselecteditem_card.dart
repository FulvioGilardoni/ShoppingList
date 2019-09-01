import 'package:flutter/material.dart';

import '../../models/shoppingitem.dart';
import '../../scoped-models/main.dart';
import '../../utility.dart';

class ShoppingSelectedItemCard extends StatefulWidget {
  final ShoppingItem _shoppingItem;
  final MainModel _mainModel;
  final Map<String, dynamic> _formData = {
    'description': null,
    'infoQta': null,
    'isBuy': null,
  };
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ShoppingSelectedItemCard(this._shoppingItem, this._mainModel);

  @override
  State<StatefulWidget> createState() {
    return _ShoppingSelectedItemCardState();
  }
}

class _ShoppingSelectedItemCardState extends State<ShoppingSelectedItemCard> {
  @override
  Widget build(BuildContext context) {
    print('building ShoppingSelectedItemCard');
    return Card(
      color: Colors.white70,
      child: _buildShoppingItem(context),
    );
  }

  Widget _buildShoppingItem(BuildContext context) {
    return Form(
      key: widget._formKey,
      child: Column(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.description, size: 35.0),
            title: TextFormField(
              decoration: InputDecoration(labelText: 'Articolo'),
              initialValue: widget._shoppingItem.description,
              validator: (val) {
                if (val.isEmpty) {
                  return 'Inserire articolo';
                }
              },
              onSaved: (val) => widget._formData['description'] = val,
            ),
          ),
          ListTile(
            leading: Icon(Icons.info, size: 35.0),
            title: TextFormField(
              decoration: InputDecoration(labelText: 'Info/qtà'),
              initialValue: widget._shoppingItem.infoQta,
              onSaved: (val) => widget._formData['infoQta'] = val ?? '',
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                widget._mainModel.isShoppingItemSaving()
                    ? CircularProgressIndicator()
                    : FlatButton(
                        color: Colors.blue,
                        child: Text('Salva', style: TextStyle(fontSize: 18.0)),
                        onPressed: () {
                          widget._formData['isBuy'] =
                              widget._shoppingItem.isBuy;
                          _saveForm(context);
                        },
                      ),
                Container(
                  width: 10.0,
                ),
                widget._mainModel.isShoppingItemSaving()
                    ? Container()
                    : FlatButton(
                        color: Colors.blue,
                        child:
                            Text('Annulla', style: TextStyle(fontSize: 18.0)),
                        onPressed: () => _cancelShoppingItem(context),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveForm(BuildContext context) async {
    print('_saveForm');
    if (widget._formKey.currentState.validate()) {
      widget._formKey.currentState.save();
      final ShoppingItem shoppingItem = ShoppingItem(
          documentId: widget._shoppingItem.documentId,
          description: widget._formData['description'],
          infoQta: widget._formData['infoQta'],
          isBuy: widget._formData['isBuy']);
      bool ret = await widget._mainModel.saveShoppingItem(shoppingItem);
      if (!ret) {
        showErrorMessage(context, 'Server Error');
      }
    }
  }

  void _cancelShoppingItem(BuildContext context) async {
    print('_cancelShoppingItem');
    bool ret = await widget._mainModel.nullifySelectedShoppingItem();
    if (!ret) {
      showErrorMessage(context, 'Server Error');
    }
  }
}
