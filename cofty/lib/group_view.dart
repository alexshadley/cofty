import 'package:cofty/crud_service.dart' as crud;
import 'package:cofty/models.dart';
import 'package:flutter/material.dart';

class GroupView extends StatefulWidget {
  final Group group;

  GroupView({Key key, @required this.group}) : super(key: key);

  @override
  _GroupViewState createState() => _GroupViewState();
}

class _GroupViewState extends State<GroupView> {
  List<User> users = [];

  @override
  initState() {
    super.initState();

    crud
        .getGroupUsers(widget.group)
        .then((users) => setState(() => this.users = users));
  }

  Future<void> _addUserDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Other users can enter this code to join your group'),
            content: Text(widget.group.accessCode),
            actions: <Widget>[
              FlatButton(
                  child: Text('close'),
                  onPressed: () => Navigator.of(context).pop())
            ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      body: ListView(
        children:
            this.users.map((user) => ListTile(title: Text(user.name))).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUserDialog,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
