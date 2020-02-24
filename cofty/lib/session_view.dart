import 'package:cofty/crud_service.dart' as crud;
import 'package:cofty/models.dart';
import 'package:flutter/material.dart';

class SessionView extends StatefulWidget {
  final User user;

  SessionView({Key key, @required this.user}) : super(key: key);

  @override
  _SessionViewState createState() => _SessionViewState();
}

class _SessionViewState extends State<SessionView> {
  List<Session> sessions = [];
  Map<int, List<User>> sessionUsers = new Map();

  @override
  initState() {
    super.initState();

    crud.getPendingSessions(widget.user).then((sessions) {
      setState(() {
        this.sessions = sessions;
      });
      for (var s in sessions) {
        crud.getSessionUsers(s).then((users) {
          setState(() => sessionUsers[s.id] = users);
        });
      }
    });
  }

  getSessionUserText(session) {
    if (this.sessionUsers.containsKey(session.id)) {
      var users = this.sessionUsers[session.id];
      if (users.length == 0) {
        return "Nobody?";
      } else if (users.length == 1) {
        return "Yourself?";
      } else {
        var otherUser = users.where((u) => u.gid != this.widget.user.gid).first;
        if (users.length == 2) {
          return otherUser.name;
        } else {
          return otherUser.name + ' and others';
        }
      }
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coffee Dates'),
      ),
      body: ListView(
        children: this.sessions.map((session) => sessionCard(session)).toList(),
      ),
    );
  }

  Widget sessionCard(Session session) {
    return Card(
        elevation: 2.0,
        child: Column(children: <Widget>[
          ListTile(
            title: Text(
                '${dayName[session.day.weekday - 1]} at ${session.hour} with ${getSessionUserText(session)}'),
            subtitle: Text('get coffee'),
          ),
          ButtonBar(
            children: <Widget>[
              FlatButton(
                child: const Text('I\'m going!'),
                onPressed: () {/* ... */},
              ),
              FlatButton(
                child: const Text('Not free then'),
                onPressed: () {/* ... */},
              ),
            ],
          ),
        ]));
  }
}
