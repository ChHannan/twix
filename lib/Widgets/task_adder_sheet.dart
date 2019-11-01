import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moor_flutter/moor_flutter.dart' hide Column;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twix/Database/database.dart';

import 'package:twix/Widgets/task_details.dart';

class TaskAdderSheet extends StatefulWidget {
  final String boardId;
  final String action;
  final Function showNotification;

  const TaskAdderSheet(
      {Key key,
      @required this.boardId,
      this.action = 'normal',
      this.showNotification})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TaskAdderSheetState();
}

class _TaskAdderSheetState extends State<TaskAdderSheet> {
  final TextEditingController textEditingController = TextEditingController();

  DateTime now = DateTime.now();
  DateTime today;
  DateTime dueDate;

  DateTime initialDate = DateTime.now();
  TimeOfDay initialTime = TimeOfDay.now();

  DateTime reminderDate;
  TimeOfDay reminderTime;

  DateTime remindMeDateTime;
  Color addButtonBackgroundColor = Colors.grey[400];

  @override
  void initState() {
    super.initState();
    today = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<TwixDB>(context);
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: Duration(milliseconds: 100),
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 70,
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, top: 8, bottom: 8, right: 5),
                      child: TextField(
                        decoration: InputDecoration(
                            hintText: 'Task name',
                            border: InputBorder.none,
                            counterText: ''),
                        autofocus: true,
                        maxLines: 1,
                        maxLength: 40,
                        controller: textEditingController,
                        onSubmitted: (value) {
                          _insertTask(database);
                        },
                        onChanged: (value){
                          if (value==null || value==''){
                            setState(() {
                              addButtonBackgroundColor = Colors.grey[400];
                            });
                          }else{
                            setState(() {
                              addButtonBackgroundColor = Colors.indigoAccent;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async{
                        _insertTask(database);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 3,vertical: 5),
                        margin: EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(
                          color: addButtonBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 51,
              child: Row(
                children: <Widget>[
                  TaskDetails(
                    iconData: Icons.calendar_today,
                    text: dueDate == null
                        ? 'Set due date'
                        : DateFormat.yMMMEd().format(dueDate).toString(),
                    callBack: selectDueDate,
                  ),
                  TaskDetails(
                    iconData: FontAwesomeIcons.bell,
                    text: remindMeDateTime == null
                        ? 'Remind Me'
                        : '${DateFormat.MMMEd().format(remindMeDateTime).toString()}, '
                            '${DateFormat.jm().format(remindMeDateTime).toString()}',
                    callBack: selectRemindDate,
                  ),
                ],
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

  Future selectDueDate() async {
    var selected = await showDatePicker(
        context: (context),
        initialDate: initialDate,
        firstDate: DateTime(2000, 1),
        lastDate: DateTime(2050, 1));
    if (selected != null && selected != dueDate)
      setState(() {
        dueDate = selected;
        dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
      });
  }

  Future selectRemindDate() async {
    var selected = await showDatePicker(
        context: (context),
        initialDate: initialDate,
        firstDate: DateTime(2000, 1),
        lastDate: DateTime(2050, 1));
    if (selected != null && selected != reminderDate) {
      reminderDate = selected;
      selectRemindTime();
    }
  }

  Future selectRemindTime() async {
    var selected =
        await showTimePicker(context: context, initialTime: initialTime);
    if (selected != null && selected != reminderTime) {
      setState(() {
        reminderTime = selected;
      });
      remindMeDateTime = DateTime(reminderDate.year, reminderDate.month,
          reminderDate.day, reminderTime.hour, reminderTime.minute);
    }
  }

  void _insertTask(TwixDB database) async {
    today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);
    String uuid = Uuid().v4();
    if (textEditingController.text.isNotEmpty) {
      widget.action == 'normal'
          ? database.taskDao.insertTask(TaskTableCompanion(
              id: Value(uuid),
              name: Value(textEditingController.text),
              dueDate: Value(dueDate),
              myDayDate: Value(dueDate),
              boardId: Value(widget.boardId),
              remindMe: Value(remindMeDateTime),
              createdAt: Value(DateTime.now())))
          : widget.action == 'normal MyTasks'
              ? database.taskDao.insertTask(
                  TaskTableCompanion(
                    id: Value(uuid),
                    name: Value(textEditingController.text),
                    boardId: Value(widget.boardId),
                    dueDate: Value(dueDate),
                    myDayDate: Value(dueDate),
                    remindMe: Value(remindMeDateTime),
                    createdAt: Value(DateTime.now()),
                  ),
                )
              : database.taskDao.insertTask(
                  TaskTableCompanion(
                    id: Value(uuid),
                    name: Value(textEditingController.text),
                    boardId: Value(widget.boardId),
                    dueDate: Value(dueDate),
                    myDayDate: Value(
                      DateTime(today.year, today.month, today.day),
                    ),
                    remindMe: Value(remindMeDateTime),
                    createdAt: Value(DateTime.now()),
                  ),
                );
      Navigator.pop(context);
      if (remindMeDateTime != null) {
        widget.showNotification(
            title: 'Twix reminder!',
            task: 'You have to complete ${textEditingController.text}!',
            time: remindMeDateTime,
            payload: uuid);
      }
    }
  }
}
