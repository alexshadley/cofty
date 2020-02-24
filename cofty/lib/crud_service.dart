import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:cofty/models.dart';

final apiUrl = 'http://35.209.4.61:3000';

final headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Prefer': 'return=representation'
};

final random = Random();

Future<User> getUser(String gid) async {
  var res = await http.get(
    apiUrl + '/users?gid=eq.${gid}',
  );

  var payload = convert.jsonDecode(res.body);
  return payload.length > 0 ? User.fromJson(payload[0]) : null;
}

Future<User> registerUser(User user) async {
  var body = user.toJson();

  var res = await http.post(apiUrl + '/users',
      body: convert.jsonEncode(body), headers: headers);

  var payload = convert.jsonDecode(res.body);
  return payload.length > 0 ? User.fromJson(payload[0]) : null;
}

Future<List<Group>> getUserGroups(User user) async {
  var res =
      await http.get(apiUrl + '/users?select=groups(*)&gid=eq.${user.gid}');

  var payload = convert.jsonDecode(res.body);
  var user_groups = payload[0]['groups'];

  return user_groups
      .map((group) => Group.fromJson(group))
      .toList()
      .cast<Group>();
}

// is this needed?
Future<Group> createGroup(Group group) async {
  var body = group.toJson();

  var res = await http.post(apiUrl + '/groups',
      body: convert.jsonEncode(body), headers: headers);

  var payload = convert.jsonDecode(res.body);
  return payload.length > 0 ? Group.fromJson(payload[0]) : null;
}

// TODO: move to backend
Future<Group> createGroupWithName(String groupName) async {
  var charCodes = List<int>.generate(6, (_) => random.nextInt(25) + 65);
  String code = String.fromCharCodes(charCodes);

  var body = {'name': groupName, 'access_code': code};

  var res = await http.post(apiUrl + '/groups',
      body: convert.jsonEncode(body), headers: headers);

  var payload = convert.jsonDecode(res.body);
  return payload.length > 0 ? Group.fromJson(payload[0]) : null;
}

Future<List<User>> getGroupUsers(Group group) async {
  var res =
      await http.get(apiUrl + '/groups?select=users(*)&id=eq.${group.id}');

  var payload = convert.jsonDecode(res.body);
  var group_users = payload[0]['users'];

  return group_users.map((user) => User.fromJson(user)).toList().cast<User>();
}

Future<bool> joinGroup(User user, Group group) async {
  var body = {'user_id': user.gid, 'group_id': group.id};

  var res = await http.post(apiUrl + '/user_groups',
      body: convert.jsonEncode(body), headers: headers);

  return true;
}

Future<bool> joinGroupWithCode(User user, String accessCode) async {
  var res = await http.get(apiUrl + '/groups?access_code=eq.${accessCode}');
  Group group = Group.fromJson(convert.jsonDecode(res.body)[0]);

  return joinGroup(user, group);
}

Future<List<Obligation>> getObligations(User user) async {
  var res = await http
      .get(apiUrl + '/users?select=obligations(*)&gid=eq.${user.gid}');

  var payload = convert.jsonDecode(res.body);
  var obligations = payload[0]['obligations'];

  return obligations
      .map((o) => Obligation.fromJson(o))
      .toList()
      .cast<Obligation>();
}

Future<Obligation> addObligation(Obligation obligation) async {
  var body = obligation.toJson();

  var res = await http.post(apiUrl + '/obligations',
      body: convert.jsonEncode(body), headers: headers);

  var payload = convert.jsonDecode(res.body);
  return payload.length > 0 ? Obligation.fromJson(payload[0]) : null;
}

Future<bool> deleteObligation(Obligation obligation) async {
  var res = await http.delete(apiUrl +
      '/obligations?user_id=eq.${obligation.userId}&day=eq.${obligation.day}&hour=eq.${obligation.hour}');

  return true;
}

Future<List<Session>> getPendingSessions(User user) async {
  var res =
      await http.get(apiUrl + '/users?select=sessions(*)&gid=eq.${user.gid}');

  var payload = convert.jsonDecode(res.body);
  var sessions = payload[0]['sessions'];

  return sessions.map(Session.fromJson).toList().cast<Session>();
}

Future<List<User>> getSessionUsers(Session session) async {
  var res =
      await http.get(apiUrl + '/sessions?select=users(*)&id=eq.${session.id}');

  var payload = convert.jsonDecode(res.body);
  var session_users = payload[0]['users'];

  return session_users.map(User.fromJson).toList().cast<User>();
}
