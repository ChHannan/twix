import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twix/Database/database.dart';

class AdderSheet extends StatefulWidget {
  final IconData iconData;
  final String text;
  final Function callBack;

  AdderSheet({this.iconData, this.text, this.callBack});

  @override
  _AdderSheetState createState() => _AdderSheetState();
}

class _AdderSheetState extends State<AdderSheet> {
  TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final TwixDB database = Provider.of<TwixDB>(context);
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: Duration(milliseconds: 100),
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 60,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Icon(
                      widget.iconData,
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 8.0,
                        top: 8,
                        bottom: 8,
                        right: 5,
                      ),
                      child: TextField(
                        controller: textEditingController,
                        decoration: InputDecoration(
                          hintText: '${widget.text} name',
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        autofocus: true,
                        maxLength: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FlatButton(
                child: Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (textEditingController.text.isNotEmpty)
                    widget.callBack(textEditingController.text, database);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }
}
