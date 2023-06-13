import 'package:flutter/material.dart';

Widget title(String title) {
  return Container(
    child: Row(
      children: <Widget>[
        Container(
          height: 1.0,
          width: 8.0,
          color: Colors.grey,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Flexible(
          child: Container(
            height: 1.0,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  );
}
