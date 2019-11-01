import 'package:flutter/material.dart';

class OnSwipeContainer extends StatelessWidget {
  final Color color;
  final IconData iconData;
  final Alignment alignment;

  OnSwipeContainer({
    this.color,
    this.iconData,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      color: color,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(
            iconData,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
