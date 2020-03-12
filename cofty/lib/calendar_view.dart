import 'package:cofty/crud_service.dart' as crud;
import 'package:cofty/models.dart';
import 'package:flutter/material.dart';

class CalendarView extends StatefulWidget {
  final User user;

  CalendarView({Key key, @required this.user}) : super(key: key);

  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  // hours from 8am to 5pm
  final days = List.generate(7, (i) => i);
  final hours = List.generate(10, (i) => i + 8);

  Set<String> obligations = new Set();

  int day = 0;

  @override
  initState() {
    super.initState();

    crud.getObligations(widget.user).then((obligations) => setState(() {
          for (var o in obligations) {
            this.obligations.add(hourToString(o.day, o.hour));
          }
        }));
  }

  hourToString(int day, int hour) {
    return '${day}_${hour}';
  }

  toggleHour(int day, int hour) {
    String h = hourToString(day, hour);
    setState(() {
      if (this.obligations.contains(h)) {
        this.obligations.remove(h);
        crud.deleteObligation(new Obligation(null, widget.user.gid, day, hour));
      } else {
        this.obligations.add(h);
        crud.addObligation(new Obligation(null, widget.user.gid, day, hour));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Weekly Availability'),
        ),
        body: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            children: this.days.map((d) => buildDayColumn(d)).toList()));
  }

  Widget buildDayColumn(int day) {
    return Padding(
        padding: EdgeInsets.only(left: 3, right: 3),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                  Text(dayNameShort[day],
                      style: DefaultTextStyle.of(context)
                          .style
                          .apply(fontSizeFactor: 2.0))
                ].cast<Widget>() +
                this
                    .hours
                    .map((h) => GestureDetector(
                        onTap: () => toggleHour(day, h),
                        child: Container(
                            child: Center(
                                child: Text(hourName[h],
                                    style: DefaultTextStyle.of(context)
                                        .style
                                        .apply(color: Colors.white)
                                        .apply(fontSizeFactor: 1.2))),
                            color:
                                this.obligations.contains(hourToString(day, h))
                                    ? Colors.grey
                                    : Colors.lightBlue,
                            width: 80.0,
                            height: 40.0)))
                    .toList()));
  }
}
