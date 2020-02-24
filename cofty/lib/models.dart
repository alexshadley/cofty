import 'dart:convert' as convert;

final dayName = {
  0: 'Monday',
  1: 'Tuesday',
  2: 'Wednesday',
  3: 'Thursday',
  4: 'Friday',
  5: 'Saturday',
  6: 'Sunday'
};

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

class Session {
  final int id;
  final DateTime day;
  final int hour;
  final bool accepted;
  final bool pending;

  Session(int id, DateTime day, int hour, bool accepted, bool pending)
      : this.id = id,
        this.day = day,
        this.hour = hour,
        this.accepted = accepted,
        this.pending = pending;

  static Session fromJson(payload) {
    return Session(payload['id'], DateTime.parse(payload['day']),
        payload['hour'], payload['accepted'], payload['pending']);
  }

  dynamic toJson() {
    return {
      'id': this.id,
      'day': this.day,
      'hour': this.hour,
      'accepted': this.accepted,
      'pending': this.pending,
    };
  }
}
