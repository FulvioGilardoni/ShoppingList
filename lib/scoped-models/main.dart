import 'package:scoped_model/scoped_model.dart';
import 'dart:async';

import './connected_models.dart';

class MainModel extends Model
    with ConnectedModels, ShoppingItemModel, UserModel {}
