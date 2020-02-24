import 'package:cofty/crud_service.dart' as crud;
import 'package:cofty/group_view.dart';
import 'package:cofty/models.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GroupsMenu extends StatefulWidget {
  final User user;

  GroupsMenu({Key key, this.user}) : super(key: key);

  @override
  _GroupsMenuState createState() => _GroupsMenuState();
}

class _GroupsMenuState extends State<GroupsMenu> {
  final codeController = TextEditingController();
  final groupNameController = TextEditingController();

  GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  List<Group> groups = [];

  @override
  void initState() {
    super.initState();

    crud.getUserGroups(this.widget.user).then((groups) {
      setState(() {
        this.groups = groups;
      });
    });
  }

  Future<void> createGroupDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Create group'),
            content: TextField(
              controller: groupNameController,
              decoration: InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Group name'),
            ),
            actions: <Widget>[
              FlatButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
              FlatButton(
                  child: Text('Create'),
                  onPressed: () {
                    crud
                        .createGroupWithName(groupNameController.text)
                        .then((group) {
                      crud.joinGroup(widget.user, group).then((status) {
                        Navigator.of(context).pop();
                      });
                    });
                  })
            ]);
      },
    ).then((_) {
      crud.getUserGroups(widget.user).then((groups) {
        setState(() {
          this.groups = groups;
        });
      });
    });
  }

  Future<void> _addGroupDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Enter your 6-digit group code'),
            content: TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Group code'),
            ),
            actions: <Widget>[
              FlatButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
              FlatButton(
                  child: Text('Join'),
                  onPressed: () {
                    crud
                        .joinGroupWithCode(widget.user, codeController.text)
                        .then((status) {
                      Navigator.of(context).pop();
                    });
                  })
            ]);
      },

      // refresh groups after adding
    ).then((_) {
      crud.getUserGroups(widget.user).then((groups) {
        setState(() {
          this.groups = groups;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the GroupsMenu object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text('Groups'),
        ),
        body: Column(children: <Widget>[
          ListView(
            shrinkWrap: true,
            children: this
                .groups
                .map((group) => ListTile(
                    title: Text(group.name),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => GroupView(group: group)));
                    }))
                .toList(),
          ),
          Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ButtonBar(
                      alignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RaisedButton(
                            child: Text('New group'),
                            onPressed: createGroupDialog),
                        RaisedButton(
                            child: Text('Join group'),
                            onPressed: _addGroupDialog)
                      ])))
        ]));
  }
}
