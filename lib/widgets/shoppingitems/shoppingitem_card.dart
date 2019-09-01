import 'package:flutter/material.dart';

import '../../models/shoppingitem.dart';
import '../../scoped-models/main.dart';
import '../../utility.dart';

class ShoppingItemCard extends StatelessWidget {
  final ShoppingItem _shoppingItem;
  final MainModel _mainModel;

  ShoppingItemCard(this._shoppingItem, this._mainModel);

  @override
  Widget build(BuildContext context) {
    print('building ShoppingItemCard ${_shoppingItem.description}');
    return Card(
      color: Colors.white70,
      child: _buildShoppingItem(context),
    );
  }

  Widget _buildShoppingItem(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(_shoppingItem.description.length > 0
            ? _shoppingItem.description[0].toUpperCase()
            : 'X'),
      ),
      title: Text(_shoppingItem.description),
      subtitle: Text(_shoppingItem.infoQta),
      trailing: Container(
        width: 100.0,
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            new IconButton(
              icon: Icon(Icons.shopping_cart, size: 35.0),
              color: _shoppingItem.isBuy ? Colors.green : Colors.black54,
              onPressed: () => _toogleShoppingItem(context),
            ),
            new IconButton(
              icon: Icon(Icons.delete, size: 35.0),
              color: Colors.black54,
              onPressed: () => _deleteShoppingItem(context),
            ),
          ],
        ),
      ),
      onLongPress: () => _selectShoppingItem(context),
    );
  }

  void _toogleShoppingItem(BuildContext context) async {
    print('_toogleShoppingItem');
    bool ret = await _mainModel.toogleIsBuy(_shoppingItem.documentId);
    if (!ret) {
      showErrorMessage(context, 'Server Error');
    }
  }

  void _deleteShoppingItem(BuildContext context) async {
    print('_deleteShoppingItem');
    bool ret = await _mainModel.deleteShoppingItem(_shoppingItem.documentId);
    if (!ret) {
      showErrorMessage(context, 'Server Error');
    }
  }

  void _selectShoppingItem(BuildContext context) {
    print('_selectShoppingItem');
    _mainModel.selectShoppingItem(_shoppingItem.documentId);
  }
}
