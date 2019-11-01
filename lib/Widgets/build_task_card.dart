import 'package:flutter/material.dart';
import 'package:twix/Database/DAOs/assigned_task_dao.dart';
import 'package:twix/Database/DAOs/task_dao.dart';
import 'package:twix/Database/database.dart';
import 'package:twix/Widgets/task_card.dart';
import 'onswipe_container.dart';

class BuildTaskCard extends StatefulWidget {
  final TaskWithBoard taskItem;
  final AssignedTaskWithUser assignedTaskItem;
  final TwixDB database;
  final Function showNotification;

  BuildTaskCard(
      {this.taskItem,
      this.assignedTaskItem,
      this.database,
      this.showNotification});

  @override
  _BuildTaskCardState createState() => _BuildTaskCardState();
}

class _BuildTaskCardState extends State<BuildTaskCard>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.ease);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TaskCard taskCard = TaskCard(
      task: widget.taskItem != null ? widget.taskItem : null,
      assignedTask:
          widget.assignedTaskItem != null ? widget.assignedTaskItem : null,
      showNotification: widget.showNotification,
    );
    bool isDone = widget.taskItem == null
        ? widget.assignedTaskItem.task.isDone
        : widget.taskItem.task.isDone;
    DismissDirection dismissDirection =
        isDone ? DismissDirection.endToStart : DismissDirection.horizontal;
    return FadeTransition(
      opacity: _animation,
      child: Builder(
        builder: (context) => Dismissible(
          key: ValueKey(taskCard.hashCode),
          direction: dismissDirection,
          background: OnSwipeContainer(
            color: Colors.blue,
            iconData: Icons.check,
            alignment: Alignment.centerLeft,
          ),
          child: taskCard,
          onDismissed: (DismissDirection direction) {
            if (direction == DismissDirection.startToEnd) {
              // Logic to update the task to isDone
              widget.assignedTaskItem == null
                  ? widget.database.taskDao
                      .updateTask(widget.taskItem.task.copyWith(isDone: true))
                  : widget.database.taskDao.updateTask(
                      widget.assignedTaskItem.task.copyWith(isDone: true));

              // Display snack bar
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  content: Text("Done"),
                  duration: Duration(milliseconds: 600),
                ),
              );
            } else if (direction == DismissDirection.endToStart) {
              // Logic to delete the task
              widget.assignedTaskItem == null
                  ? widget.database.taskDao.deleteTask(widget.taskItem.task)
                  : widget.database.assignedTaskDao
                      .deleteAssignedTask(widget.assignedTaskItem.assignedTask);

              // Display snack bar
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  content: Text("Deleted"),
                  duration: Duration(milliseconds: 600),
                ),
              );
            }
          },
          secondaryBackground: OnSwipeContainer(
            color: Colors.red,
            iconData: Icons.delete,
            alignment: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
}
