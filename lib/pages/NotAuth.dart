import 'package:flutter/material.dart';

class NotAuthPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('building NotAuth page');
    return Scaffold(
      appBar: AppBar(
        title: Text('Autenticazione...'),
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('images/sfondo.jpg'),
          ),
        ),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
