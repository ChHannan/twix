import 'package:flutter/material.dart';

class BoardsList extends StatelessWidget {
  final IconData iconData;
  final String title;
  final Color color;
  final Function callBack;
  final String remainingTasks;

  BoardsList({
    this.iconData,
    this.title,
    this.color,
    this.callBack,
    this.remainingTasks = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListTile(
        leading: Icon(
          iconData,
          color: color,
        ),
        trailing: Text(remainingTasks),
        title: Text(title),
        onTap: callBack,
      ),
    );
  }
}
