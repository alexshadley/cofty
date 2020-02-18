import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:cofty/models.dart';

final apiUrl = 'https://cofty-api-smepkzphmq-uc.a.run.app';

final headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
};

Future<User> registerUser(User user) async {
  var res = await http.get(
    apiUrl + '/users?gid=eq.${user.gid}',
  );

  var payload = convert.jsonDecode(res.body);
  return User.fromJson(payload[0]);
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
