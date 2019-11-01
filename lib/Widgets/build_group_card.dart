import 'package:flutter/material.dart';
import 'package:twix/Database/database.dart';
import 'package:twix/Widgets/board_list.dart';
import 'package:twix/Screens/group_screen.dart';

class BuildGroupCard extends StatefulWidget {
  final GroupTableData groupItem;

  BuildGroupCard({this.groupItem});

  @override
  _BuildGroupCardState createState() => _BuildGroupCardState();
}

class _BuildGroupCardState extends State<BuildGroupCard>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 800,
      ),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.ease,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: BoardsList(
        iconData: Icons.group,
        title: widget.groupItem.name,
        color: Colors.teal,
        callBack: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupScreen(
                group: widget.groupItem,
              ),
            ),
          );
        },
      ),
    );
  }
}
