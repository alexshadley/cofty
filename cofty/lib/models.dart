import 'dart:convert' as convert;

class User {
  final String gid;
  final String name;

  User(String gid, String name)
      : this.gid = gid,
        this.name = name;

  static User fromJson(payload) {
    return User(payload['gid'], payload['name']);
  }
}

class Group {
  final int id;
  final String accessCode;

  Group(int id, String accessCode)
      : this.id = id,
        this.accessCode = accessCode;

  static Group fromJson(payload) {
    return Group(payload['id'], payload['access_code']);
  }
}
