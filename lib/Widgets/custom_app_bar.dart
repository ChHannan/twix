import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:twix/Database/database.dart';

class CustomAppBar extends PreferredSize {
  final double height;
  final Color color;

  CustomAppBar({this.height, this.color});

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<TwixDB>(context);
    return Container(
      //padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      height: height,
      color: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
              child: Padding(
            child: Hero(
              tag: 'icon',
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('images/splash_image.png'),
                radius: 1,
              ),
            ),
            padding: const EdgeInsets.all(5.0),
          )),
          Expanded(
            flex: 5,
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildUserProfile(database)),
          ),
          Expanded(
            child: Material(
              child: InkWell(
                onTap: () {
                  showSearch(context: context, delegate: Search());
                },
                child: Icon(
                  Icons.search,
                  color: Colors.indigoAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);

  StreamBuilder<UserTableData> _buildUserProfile(TwixDB database) {
    return StreamBuilder(
      stream: database.userDao.watchLoggedInUser(),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.active ||
            snapshot.connectionState == ConnectionState.done) if (!snapshot
                .hasError &&
            snapshot.data != null) {
          User.name = snapshot.data.name;
          User.email = snapshot.data.email;
          return _buildUserNameAndEmail(User.name, User.email);
        }
        return _buildUserNameAndEmail(User.name, User.email);
      },
    );
  }

  Widget _buildUserNameAndEmail(String name, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Text(
          name,
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        Text(
          email,
          style: TextStyle(color: Colors.black, fontSize: 12),
        ),
      ],
    );
  }
}

class Search extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.close),
        onPressed: () {
          query = "";
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () {
          close(context, null);
        },
        icon: Icon(Icons.arrow_back));
  }

  @override
  Widget buildResults(BuildContext context) {
    return null;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final database = Provider.of<TwixDB>(context);
    return FutureBuilder(
        future: database.taskDao.getAllTasks(query),
        builder: (BuildContext context,
            AsyncSnapshot<List<TaskTableData>> snapshot) {
          var data = snapshot.data ?? List();
          return ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return TaskSearchCard(
                task: data[index],
              );
            },
            itemCount: data.length,
          );
        },);
  }
}

class TaskSearchCard extends StatelessWidget {
  final TaskTableData task;

  TaskSearchCard({this.task});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: task.isDone
          ? Icon(Icons.check_circle_outline,color: Colors.green,)
          : Icon(Icons.radio_button_unchecked),
      title: Text(task.name),
    );
  }
}

class User {
  static String name = '';
  static String email = '';
}
