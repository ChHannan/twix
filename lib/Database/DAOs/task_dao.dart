import 'package:moor_flutter/moor_flutter.dart';

import 'package:twix/Database/database.dart';

import 'package:twix/Database/Tables/task_table.dart';
import 'package:twix/Database/Tables/board_table.dart';

part 'task_dao.g.dart';

@UseDao(tables: [TaskTable, BoardTable])
class TaskDao extends DatabaseAccessor<TwixDB> with _$TaskDaoMixin {
  TaskDao(TwixDB db) : super(db);

  Future<int> insertTask(Insertable<TaskTableData> task) =>
      into(taskTable).insert(task, orReplace: true);

  Future updateTask(Insertable<TaskTableData> task) =>
      update(taskTable).replace(task);

  Future deleteTask(Insertable<TaskTableData> task) =>
      delete(taskTable).delete(task);

  Future<TaskTableData> getTaskById(String id) =>
      (select(taskTable)..where((row) => row.id.equals(id))).getSingle();

  Future<List<TaskTableData>> getAllTasks(String like) =>
      (select(taskTable)..where((row) => row.name.like('$like%'))).get();

  Stream<List<TaskWithBoard>> watchAllTasksByBoardId(String boardId) =>
      (select(taskTable)
            ..where((row) => row.boardId.equals(boardId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.isDone, mode: OrderingMode.asc),
              (t) =>
                  OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
            ]))
          .join([
            innerJoin(boardTable, taskTable.boardId.equalsExp(boardTable.id)),
          ])
          .watch()
          .map((rows) => rows
              .map((row) => TaskWithBoard(
                  task: row.readTable(taskTable),
                  board: row.readTable(boardTable)))
              .toList());

  Stream<List<TaskTableData>> watchAllTasksByBoardIdNoJoin(String boardId) =>
      (select(taskTable)
            ..where((row) => row.boardId.equals(boardId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.isDone, mode: OrderingMode.asc)
            ]))
          .watch();

  Stream<List<TaskTableData>> watchDoneTasksByBoardId(String boardId) =>
      (select(taskTable)
            ..where((row) => row.boardId.equals(boardId))
            ..where((row) => row.isDone.equals(true)))
          .watch();

  Stream<List<TaskTableData>> watchNotDoneTasksByBoardId(String boardId) =>
      (select(taskTable)
        ..where((row) => row.boardId.equals(boardId))
        ..where((row) => row.isDone.equals(false)))
          .watch();

  Stream<List<TaskWithBoard>> watchAllMyDayTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (select(taskTable)
          ..where((row) => row.myDayDate.equals(today))
          ..orderBy([
            (t) => OrderingTerm(expression: t.isDone, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .join([
          innerJoin(boardTable, taskTable.boardId.equalsExp(boardTable.id)),
        ])
        .watch()
        .map((rows) => rows
            .map((row) => TaskWithBoard(
                task: row.readTable(taskTable),
                board: row.readTable(boardTable)))
            .toList());
  }

  Stream<List<TaskTableData>> getAllMyDayTasksNoJoin() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (select(taskTable)..where((row) => row.myDayDate.equals(today)))
        .watch();
  }

  Stream<List<TaskTableData>> watchDoneMyDayTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (select(taskTable)
          ..where((row) => row.myDayDate.equals(today))
          ..where((row) => row.isDone.equals(true)))
        .watch();
  }

  bool isMyDay(DateTime myDayDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime myDayDateRefined;
    if (myDayDate != null)
      myDayDateRefined =
          DateTime(myDayDate.year, myDayDate.month, myDayDate.day);
    return myDayDateRefined == today;
  }
}

class TaskWithBoard {
  final TaskTableData task;
  final BoardTableData board;

  TaskWithBoard({this.task, this.board});
}
