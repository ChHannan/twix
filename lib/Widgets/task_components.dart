import 'package:flutter/material.dart';

class TaskComponents extends StatelessWidget {
  final IconData iconData;
  final String text;
  final Function callBack;
  TaskComponents({this.iconData, this.text, this.callBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, top: 8, bottom: 8, right: 5),
      child: InkWell(
        onTap: callBack,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                    top: 8.0, left: 10, bottom: 8, right: 5),
                child: Icon(
                  iconData,
                  size: 17,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    top: 8.0, left: 5, bottom: 8, right: 10),
                child: Text(
                  text,
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
