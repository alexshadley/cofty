import 'dart:convert' as convert;

class User {
  final String gid;
  final String name;
  final String messagingToken;

  User(String gid, String name, String messagingToken)
      : this.gid = gid,
        this.name = name,
        this.messagingToken = messagingToken;

  static User fromJson(payload) {
    return User(payload['gid'], payload['name'], payload['messaging_token']);
  }

  dynamic toJson() {
    return {
      'gid': this.gid,
      'name': this.name,
      'messaging_token': messagingToken
    };
  }
}

class Group {
  final int id;
  final String name;
  final String accessCode;

  Group(int id, String name, String accessCode)
      : this.id = id,
        this.name = name,
        this.accessCode = accessCode;

  static Group fromJson(payload) {
    return Group(payload['id'], payload['name'], payload['access_code']);
  }

  dynamic toJson() {
    return {'id': this.id, 'name': this.name, 'access_code': this.accessCode};
  }
}

class Obligation {
  final int id;
  final String userId;
  final int day;
  final int hour;

  Obligation(int id, String userId, int day, int hour)
      : this.id = id,
        this.userId = userId,
        this.day = day,
        this.hour = hour;

  static Obligation fromJson(payload) {
    return Obligation(
        payload['id'], payload['userId'], payload['day'], payload['hour']);
  }

  dynamic toJson() {
    return (this.id == null)
        ? {'user_id': this.userId, 'day': this.day, 'hour': this.hour}
        : {
            'id': this.id,
            'user_id': this.userId,
            'day': this.day,
            'hour': this.hour
          };
  }
}
