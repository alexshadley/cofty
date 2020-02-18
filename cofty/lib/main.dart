import 'package:cofty/crud_service.dart' as crud;
import 'package:cofty/models.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: GroupsMenu(title: 'Flutter Demo Home Page'),
    );
  }
}

class GroupsMenu extends StatefulWidget {
  GroupsMenu({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _GroupsMenuState createState() => _GroupsMenuState();
}

class _GroupsMenuState extends State<GroupsMenu> {
  final User user = User("a000", "Alex Shadley");
  final codeController = TextEditingController();

  int _counter = 0;
  List<Group> groups = [];

  @override
  void initState() {
    crud.getUserGroups(this.user).then((groups) {
      setState(() {
        this.groups = groups;
      });
    });
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
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
                  child: Text('Join'),
                  onPressed: () {
                    crud
                        .joinGroupWithCode(user, codeController.text)
                        .then((status) {
                      Navigator.of(context).pop();
                    });
                  })
            ]);
      },

      // refresh groups after adding
    ).then((_) {
      crud.getUserGroups(user).then((groups) {
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
        title: Text(widget.title),
      ),
      body: ListView(
        children: this
            .groups
            .map((group) => ListTile(title: Text(group.accessCode)))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGroupDialog,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
