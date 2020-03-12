import 'package:cofty/availability_view.dart';
import 'package:cofty/crud_service.dart' as crud;
import 'package:cofty/group_view.dart';
import 'package:cofty/groups_menu.dart';
import 'package:cofty/models.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'calendar_view.dart';
import 'session_view.dart';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

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
      home: AppWidget(title: 'Flutter Demo Home Page'),
    );
  }
}

class AppWidget extends StatefulWidget {
  AppWidget({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _AppWidgetState createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  User user;

  int navIndex = 0;

  Widget renderBody() {
    if (this.user == null) {
      return Text('Loading');
    }

    if (this.navIndex == 0) {
      return SessionView(user: this.user);
    } else if (this.navIndex == 1) {
      return GroupsMenu(user: this.user);
    } else {
      return CalendarView(user: this.user);
    }
  }

  @override
  void initState() {
    super.initState();

    _firebaseMessaging.requestNotificationPermissions();

    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount acct) async {
      var user = await crud.getUser(acct.id);
      if (user != null) {
        setState(() => this.user = user);
      } else {
        user = await crud.registerUser(User(
            acct.id, acct.displayName, await _firebaseMessaging.getToken()));
        setState(() => this.user = user);
      }
    });

    googleSignIn.signIn();
  }

  updateNavIndex(int index) {
    setState(() {
      this.navIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: renderBody(),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: this.navIndex,
          onTap: updateNavIndex,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.local_cafe), title: Text('Dates')),
            BottomNavigationBarItem(
                icon: Icon(Icons.group), title: Text('Groups')),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today), title: Text('Availability'))
          ]),
    );
  }
}
