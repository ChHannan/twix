import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:twix/Database/database.dart';

class NoteEditor extends StatelessWidget {
  final TaskTableData task;
  final TextEditingController notesController = TextEditingController();

  NoteEditor({Key key, this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<TwixDB>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notes',
          style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: ThemeData.light().scaffoldBackgroundColor,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              if (notesController.text.isNotEmpty) {
                await database.taskDao.updateTask(
                    task.copyWith(notes: notesController.text));
              }
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Container(
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            autofocus: true,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            decoration: InputDecoration(
              border: InputBorder.none,
            ),
            controller: notesController..text = task.notes,
          ),
        ),
      ),
    );
  }
}
