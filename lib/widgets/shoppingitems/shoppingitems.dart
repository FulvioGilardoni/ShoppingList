import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../../scoped-models/main.dart';
import '../../models/shoppingitem.dart';
import 'shoppingitem_card.dart';
import 'shoppingselecteditem_card.dart';

class ShoppingItems extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    print('building ShoppingItems widget');    
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        Widget shoppingItemCards;        
        final List<ShoppingItem> shoppingitems = model.allShoppingItemsOrdered;
        if (shoppingitems.length > 0) {
          shoppingItemCards = ListView.builder(
              itemCount: shoppingitems.length,
              itemBuilder: (BuildContext context, int index) {
                final ShoppingItem shoppingItem = shoppingitems[index];
                return (model.selShoppingItemIndexOrder == index
                    ? ShoppingSelectedItemCard(shoppingItem, model)
                    : ShoppingItemCard(shoppingItem, model));
              });
        } else {
          shoppingItemCards = Container();
        }
        return shoppingItemCards;
      },
    );
  }
}
