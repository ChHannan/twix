import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:moor_flutter/moor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:twix/Database/database.dart';
import 'package:twix/Api/api.dart';
import 'package:twix/Screens/task_screen.dart';
import 'package:twix/Widgets/adder_sheet.dart';
import 'package:twix/Widgets/board_list.dart';
import 'package:twix/Widgets/custom_app_bar.dart';
import 'package:twix/Widgets/custom_bottom_bar.dart';

import '../Widgets/build_board_card.dart';
import '../Widgets/build_group_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool isDivider = false;
  UserTableData loggedInUser;
  BoardTableData myTasksBoard;

  List<BoardTableData> boards;
  List<GroupTableData> groups;

  setAuthToken(TwixDB database) async {
    loggedInUser = await database.userDao.getLoggedInUser();
    Api.setAuthToken(loggedInUser.token,);

    myTasksBoard = await database.boardDao.getMyTasksBoard();
    await Api.createBoard(
        id: myTasksBoard.id,
        name: 'My Tasks',
        isPersonal: true,
        userId: loggedInUser.id,);
  }

  populateAssignedToMe(TwixDB database) async {
    var response = await Api.viewAssignedTask();
    var assignedTasks = jsonDecode(response.body,);
    for (var assignedTask in assignedTasks) {
      final String id = assignedTask['id'];
      final bool isDone = assignedTask['is_done'];

      final userId = assignedTask['user']['id'];
      final userEmail = assignedTask['user']['email'];
      final userName = assignedTask['user']['name'];

      final taskId = assignedTask['task']['id'];
      final taskName = assignedTask['task']['name'];
      final taskIsDone = assignedTask['is_done'];
      final taskDueDate = assignedTask['due_date'];
      final taskRemindMe = assignedTask['remind_me'];
      final taskBoardId = assignedTask['task']['board']['id'];
      final taskNotes = assignedTask['task']['notes'];
      final taskExists = (await database.taskDao.getTaskById(taskId)) != null;

      if (userId != loggedInUser.id)
        await database.userDao.insertUser(UserTableCompanion(
            id: Value(userId,), name: Value(userName,), email: Value(userEmail,),),);

      if (!taskExists) {
        await database.taskDao.insertTask(TaskTableCompanion(
            id: Value(taskId),
            name: Value(taskName),
            isDone: Value(taskIsDone),
            dueDate: Value(taskDueDate),
            remindMe: Value(taskRemindMe),
            boardId: Value(taskBoardId),
            notes: Value(taskNotes),
            createdAt: Value(DateTime.now(),),),);

        await database.assignedTaskDao.insertAssignedTask(
            AssignedTaskTableCompanion(
                id: Value(id),
                isDone: Value(isDone),
                taskId: Value(taskId),
                userId: Value(userId)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TwixDB database = Provider.of<TwixDB>(context);
    setAuthToken(database);
    populateAssignedToMe(database);
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          height: 60.0,
          color: ThemeData.light().scaffoldBackgroundColor,
        ),
        bottomNavigationBar: CustomBottomBar(
          listCallBack: () {
            _sheetDisplay(
                context, Icons.developer_board, 'Board', _insertBoard);
          },
          groupCallBack: () {
            _sheetDisplay(context, Icons.group_add, 'Group', _insertGroup);
          },
        ),
        body: ListView(
          children: <Widget>[
            BoardsList(
              iconData: Icons.wb_sunny,
              title: 'My Day',
              color: Colors.orange,
              callBack: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskScreen(
                      action: 'My Day',
                    ),
                  ),
                );
              },
            ),
            BoardsList(
              iconData: Icons.person_outline,
              title: 'Assigned To Me',
              color: Colors.green[700],
              callBack: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskScreen(
                      action: 'Assigned To Me',
                      loggedInUser: loggedInUser,
                    ),
                  ),
                );
              },
            ),
            BoardsList(
              iconData: Icons.playlist_add_check,
              title: 'My Tasks',
              color: Colors.red[800],
              callBack: () async {
                String myTasksBoardId = myTasksBoard.id;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskScreen(
                      boardId: myTasksBoardId,
                      action: 'normal MyTasks',
                    ),
                  ),
                );
              },
            ),
            Divider(
              indent: 20,
              endIndent: 20,
            ),
            _buildBoardList(
              context,
              database,
            ),
            StreamBuilder (
              stream: database.boardDao.watchAllBoards(),
              builder: (context, snapshot) {
                boards = snapshot.data ?? List();
                return Visibility(
                  visible: boards.length > 0,
                  child: Divider(
                    indent: 20,
                    endIndent: 20,
                  ),
                );
              }
            ),
            _buildGroupList(context, database)
          ],
        ),
      ),
    );
  }

  void _sheetDisplay(
      BuildContext context, IconData iconData, String text, Function callBack) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AdderSheet(
          iconData: iconData,
          text: text,
          callBack: callBack,
        );
      },
    );
  }

  _insertBoard(String boardName, TwixDB database) async {
    final id = Uuid().v4();
    await database.boardDao.insertBoard(
      BoardTableCompanion(
        id: Value(id),
        name: Value(boardName),
        createdAt: Value(
          DateTime.now(),
        ),
      ),
    );
    await Api.createBoard(
        id: id, name: boardName, userId: loggedInUser.id, isPersonal: false);
  }

  _insertGroup(String groupName, TwixDB database) async {
    final id = Uuid().v4();
    final adminId = (await database.userDao.getLoggedInUser()).id;
    await database.groupDao.insertGroup(
      GroupTableCompanion(
        id: Value(id),
        name: Value(groupName),
        adminId: Value(adminId),
      ),
    );
    await Api.createGroup(id, groupName, adminId);
  }

  StreamBuilder<List<BoardTableData>> _buildBoardList(
      BuildContext context, TwixDB database) {
    return StreamBuilder(
      stream: database.boardDao.watchAllBoards(),
      builder: (context, AsyncSnapshot<List<BoardTableData>> snapshot) {
        boards = snapshot.data ?? List();
        return ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: boards.length,
          itemBuilder: (_, index) {
            final boardItem = boards[index];
            return BuildBoardCard(boardItem: boardItem);
          },
        );
      },
    );
  }

  StreamBuilder<List<GroupTableData>> _buildGroupList(
      BuildContext context, TwixDB database) {
    return StreamBuilder(
      stream: database.groupDao.watchAllGroups(),
      builder: (context, AsyncSnapshot<List<GroupTableData>> snapshot) {
        groups = snapshot.data ?? List();
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: groups.length,
          itemBuilder: (_, index) {
            final groupItem = groups[index];
            return BuildGroupCard(groupItem: groupItem);
          },
        );
      },
    );
  }
}

class HoldData {
  static bool isDividerA = false;
}
