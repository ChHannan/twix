import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:twix/Database/database.dart';
import 'package:twix/Database/DAOs/task_dao.dart';
import 'package:twix/Database/DAOs/assigned_task_dao.dart';

import 'package:twix/Widgets/build_task_card.dart';
import 'package:twix/Widgets/custom_scroll_behaviour.dart';
import 'package:twix/Widgets/task_adder_sheet.dart';

class TaskScreen extends StatefulWidget {
  final String boardId;
  final String action;
  final UserTableData loggedInUser;
  final Function showNotification;

  TaskScreen({this.boardId, this.action = 'normal', this.loggedInUser,
              this.showNotification});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String boardId;
  bool getBoardName = true;
  bool isMyDay = false;
  bool isAssignedToMe = false;
  bool isMyTasks = false;

  BoardTableData boardData;
  List doneTasks;
  List allTasks;
  List<TaskWithBoard> tasks;

  Function showNotification;


  @override
  void initState() {
    super.initState();
    showNotification = widget.showNotification;
    getBoardName = widget.action == 'normal';
    isMyDay = widget.action == 'My Day';
    isAssignedToMe = widget.action == 'Assigned To Me';

    if (widget.action == 'normal MyTasks') {
      getBoardName = true;
      isMyTasks = true;
    }
  }

  Future<BoardTableData> getBoard(TwixDB database) async {
    return getBoardName
        ? await database.boardDao.getBoardById(widget.boardId)
        : await database.boardDao.getMyTasksBoard();
  }

  Stream<List<TaskTableData>> watchAllTaskListNoJoin(TwixDB database) {
    return getBoardName
        ? database.taskDao.watchAllTasksByBoardIdNoJoin(widget.boardId)
        : isMyDay ? database.taskDao.watchAllMyDayTasks() : null;
  }

  Stream<List<TaskTableData>> watchDoneTaskList(TwixDB database) {
    return getBoardName
        ? database.taskDao.watchDoneTasksByBoardId(widget.boardId)
        : isMyDay ? database.taskDao.watchDoneMyDayTasks() : null;
  }

  Stream<List<TaskWithBoard>> watchAllTaskList(TwixDB database) {
    return getBoardName
        ? database.taskDao.watchAllTasksByBoardId(widget.boardId)
        : isMyDay
            ? database.taskDao.watchAllMyDayTasks()
            : database.taskDao.watchAllMyDayTasks();
  }

  @override
  Widget build(BuildContext context) {
    final TwixDB database = Provider.of<TwixDB>(context);
    final Future<BoardTableData> boardFuture = getBoard(database);

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text(
          'Tasks',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: ThemeData.light().scaffoldBackgroundColor,
        elevation: 0,
        actions: <Widget>[
          Visibility(
            visible: !isMyTasks && !isMyDay && !isAssignedToMe,
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
              ),
              onPressed: () {
                database.boardDao.deleteBoard(boardData);
                Navigator.pop(context);
              },
              color: Colors.red,
            ),
          )
        ],
      ),
      floatingActionButton: isAssignedToMe
          ? null
          : FloatingActionButton(
              onPressed: () async {
                boardId = (await getBoard(database)).id;
                showModalBottomSheet(
                  context: (context),
                  isScrollControlled: true,
                  builder: (context) => TaskAdderSheet(
                      boardId: boardId,
                      action: widget.action,
                      showNotification: showNotification),
                );
              },
              backgroundColor: Colors.indigo,
              child: Icon(Icons.add),
            ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height * 0.20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  FutureBuilder(
                    future: boardFuture,
                    builder: (context, snapshot) {
                      DateFormat format = DateFormat.yMMMd();
                      if (isAssignedToMe)
                        return _buildBoardColumn(
                            boardName: 'Assigned To Me',
                            createdAt: format.format(DateTime.now()));
                      else if (isMyDay)
                        return _buildBoardColumn(
                            boardName: 'My Day',
                            createdAt: format.format(DateTime.now()));
                      if (snapshot.connectionState == ConnectionState.active ||
                          snapshot.connectionState == ConnectionState.done) {
                        if (!snapshot.hasError) {
                          boardData = snapshot.data;
                          DateTime dateTime = boardData?.createdAt;
                          return _buildBoardColumn(
                              boardName:
                                  boardData == null ? '' : boardData.name,
                              createdAt: format.format(
                                  dateTime == null ? DateTime.now() : dateTime),
                              board: boardData,
                              database: database);
                        }
                      }
                      return _buildBoardColumn(
                          boardName: boardData != null ? boardData.name : '',
                          createdAt: boardData != null
                              ? format.format(boardData.createdAt)
                              : '',
                          board: boardData,
                          database: database);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        children: <Widget>[
                          isAssignedToMe
                              ? StreamBuilder(
                                  stream: database.assignedTaskDao
                                      .watchDoneAssignedTasksByUserId(
                                          widget.loggedInUser.id),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.done ||
                                        snapshot.connectionState ==
                                            ConnectionState.active) {
                                      return _buildCountDoneTasks(
                                          snapshot.data == null
                                              ? '0'
                                              : snapshot.data.length
                                                  .toString());
                                    }
                                    return _buildCountAllTasks('0');
                                  },
                                )
                              : StreamBuilder(
                                  stream: watchDoneTaskList(database),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState
                                            .active) if (!snapshot.hasError) {
                                      doneTasks = snapshot.data ?? List();
                                      return _buildCountDoneTasks(
                                          doneTasks?.length.toString());
                                    }
                                    return _buildCountDoneTasks(
                                        doneTasks != null
                                            ? doneTasks.length.toString()
                                            : '');
                                  }),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              '/',
                              style: TextStyle(
                                  fontSize: 30,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          isAssignedToMe
                              ? StreamBuilder(
                                  stream: database.assignedTaskDao
                                      .watchAllAssignedTasksByUserId(
                                          widget.loggedInUser.id),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.done ||
                                        snapshot.connectionState ==
                                            ConnectionState.active) {
                                      return _buildCountAllTasks(
                                          snapshot.data == null
                                              ? '0'
                                              : snapshot.data.length
                                                  .toString());
                                    }
                                    return _buildCountAllTasks('0');
                                  },
                                )
                              : StreamBuilder(
                                  stream: watchAllTaskList(database),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.active ||
                                        snapshot.connectionState ==
                                            ConnectionState.done) if (!snapshot
                                        .hasError) {
                                      allTasks = snapshot.data ?? List();
                                      return _buildCountAllTasks(
                                          allTasks.length.toString());
                                    }
                                    return _buildCountAllTasks(allTasks != null
                                        ? allTasks.length.toString()
                                        : '');
                                  }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
                height: MediaQuery.of(context).size.height * 0.65,
                child: isAssignedToMe
                    ? _buildAssignedTaskList(context, database)
                    : _buildTaskList(context, database)),
          ],
        ),
      ),
    );
  }

  StreamBuilder<List<AssignedTaskWithUser>> _buildAssignedTaskList(
      BuildContext context, TwixDB database) {
    return StreamBuilder(
      stream: database.assignedTaskDao
          .watchAllAssignedTasksByUserId(widget.loggedInUser.id),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? List();
        return ScrollConfiguration(
          behavior: CustomScrollBehaviour(),
          child: ListView.builder(
            itemCount: snapshot.data == null ? 0 : snapshot.data.length,
            itemBuilder: (_, index) {
              return BuildTaskCard(
                assignedTaskItem: tasks[index],
                database: database,
                showNotification: showNotification,
              );
            },
          ),
        );
      },
    );
  }

  StreamBuilder<List<TaskWithBoard>> _buildTaskList(
      BuildContext context, TwixDB database) {
    return StreamBuilder(
      stream: watchAllTaskList(database),
      builder: (context, AsyncSnapshot<List<TaskWithBoard>> snapshot) {
        tasks = snapshot.data ?? List();
        return ScrollConfiguration(
          behavior: CustomScrollBehaviour(),
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (_, index) {
              final taskItem = tasks[index];
              return BuildTaskCard(taskItem: taskItem, database: database,
              showNotification: showNotification,);
            },
          ),
        );
      },
    );
  }

  Widget _buildBoardColumn(
      {String boardName,
      String createdAt,
      BoardTableData board,
      TwixDB database}) {
    final TextEditingController boardNameController =
        TextEditingController.fromValue(TextEditingValue(
            text: boardName,
            selection: TextSelection.fromPosition(
                TextPosition(offset: boardName.length))));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 18),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            child: board == null || board?.isMyTasks == true
                ? Text(
                    boardName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  )
                : TextField(
                    controller: boardNameController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    enableInteractiveSelection: false,
                    maxLength: 25,
                    maxLines: 1,
                    autofocus: false,
                    onChanged: (value) {
                      database.boardDao
                          .updateBoard(board.copyWith(name: value));
                    },
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20),
          child: Text(createdAt),
        ),
      ],
    );
  }

  Widget _buildCountDoneTasks(String count) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        count,
        style: TextStyle(
            fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCountAllTasks(String count) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Text(
          count,
          style: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
