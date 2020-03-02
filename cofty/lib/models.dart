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

final hourName = {
  8: '8am',
  9: '9am',
  10: '10am',
  11: '11am',
  12: '12pm',
  13: '1pm',
  14: '2pm',
  15: '3pm',
  16: '4pm',
  17: '5pm'
};

class User {
  final String gid;
  final String name;
  final String messagingToken;

  Set<int> sessionsAccepted;
  Set<int> sessionsRejected;

  User(String gid, String name, String messagingToken)
      : this.gid = gid,
        this.name = name,
        this.messagingToken = messagingToken,
        this.sessionsAccepted = new Set(),
        this.sessionsRejected = new Set();

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

/*
Ok why does Google suck at making languages? No ADTs? Can't get the string
value of enums? Don't even get me started on Go's type system. I guess I'm the
sucker for using Google languages throughout this project =/
*/
class Session {
  final int id;
  final DateTime day;
  final int hour;
  final String status;

  Session(int id, DateTime day, int hour, String status)
      : this.id = id,
        this.day = day,
        this.hour = hour,
        this.status = status;

  static Session fromJson(payload) {
    return Session(payload['id'], DateTime.parse(payload['day']),
        payload['hour'], payload['status']);
  }

  dynamic toJson() {
    return {
      'id': this.id,
      'day': this.day,
      'hour': this.hour,
      'status': this.status,
    };
  }
}

class UserSession {
  final String userId;
  final int groupId;
  final String status;

  UserSession(String userId, int groupId, String status)
      : this.userId = userId,
        this.groupId = groupId,
        this.status = status;

  static UserSession fromJson(payload) {
    return UserSession(
        payload['user_id'], payload['group_id'], payload['status']);
  }

  dynamic toJson() {
    return {
      'user_id': this.userId,
      'group_id': this.groupId,
      'status': this.status,
    };
  }
}
