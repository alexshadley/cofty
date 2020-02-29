import 'package:cofty/crud_service.dart' as crud;
import 'package:cofty/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    updateSessions();
  }

  void updateSessions() {
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

  void attendAndUpdate(Session session, bool attending) {
    if (attending) {
      this.widget.user.sessionsAccepted.add(session.id);
      this.widget.user.sessionsRejected.remove(session.id);
    } else {
      this.widget.user.sessionsRejected.add(session.id);
      this.widget.user.sessionsAccepted.remove(session.id);
    }

    crud.attendSession(widget.user, session, attending).then((_) {
      updateSessions();
    });
  }

  bool sessionFilter(Session session) {
    if (session.day.difference(DateTime.now()).inDays >= -1 &&
        !widget.user.sessionsRejected.contains(session.id)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coffee Dates'),
      ),
      body: ListView(
        children: this.sessions.where(sessionFilter).map(sessionCard).toList(),
      ),
    );
  }

  Widget sessionCard(Session session) {
    return Card(
      elevation: 2.0,
      child: Column(
        children: <Widget>[
          Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Expanded(
                flex: 5,
                child: ListTile(
                  title: Text(
                      '${dayName[session.day.weekday - 1]} at ${session.hour} with ${getSessionUserText(session)}'),
                  subtitle: Text(
                      'On ${DateFormat.MMMMd().format(session.day)} -- ${sessionStatusText(session)}'),
                )),
            Expanded(flex: 1, child: Icon(sessionIcon(session)))
          ]),
          ButtonBar(children: sessionButtons(session)),
        ],
      ),
    );
  }

  String sessionStatusText(Session session) {
    if (session.status == "pending") {
      if (widget.user.sessionsAccepted.contains(session.id)) {
        return "Waiting on others";
      } else {
        return "Waiting on you";
      }
    } else if (session.status == "accepted") {
      return "Confirmed!";
    } else {
      return "Rejected";
    }
  }

  IconData sessionIcon(Session session) {
    switch (session.status) {
      case "pending":
        {
          return Icons.hourglass_empty;
        }
      case "accepted":
        {
          return Icons.done;
        }
    }
  }

  List<Widget> sessionButtons(session) {
    if (widget.user.sessionsAccepted.contains(session.id)) {
      return [
        FlatButton(
          child: const Text('Cancel'),
          onPressed: () => attendAndUpdate(session, false),
        ),
      ];
    } else {
      return [
        FlatButton(
          child: const Text('I\'m going!'),
          onPressed: () => attendAndUpdate(session, true),
        ),
        FlatButton(
          child: const Text('Not free then'),
          onPressed: () => attendAndUpdate(session, false),
        ),
      ];
    }
  }
}
