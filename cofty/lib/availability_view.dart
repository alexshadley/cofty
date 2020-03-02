import 'package:cofty/crud_service.dart' as crud;
import 'package:cofty/models.dart';
import 'package:flutter/material.dart';

class AvailabilityView extends StatefulWidget {
  final User user;

  AvailabilityView({Key key, @required this.user}) : super(key: key);

  @override
  _AvailabilityViewState createState() => _AvailabilityViewState();
}

class _AvailabilityViewState extends State<AvailabilityView> {
  // hours from 8am to 5pm
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

  increaseDay() {
    setState(() {
      this.day = (this.day + 1) % 7;
    });
  }

  decreaseDay() {
    setState(() {
      this.day = (this.day - 1) % 7;
    });
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
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                    onPressed: decreaseDay, child: Icon(Icons.chevron_left))
              ],
            ),
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                      Text(dayName[this.day],
                          style: DefaultTextStyle.of(context)
                              .style
                              .apply(fontSizeFactor: 2.0))
                    ].cast<Widget>() +
                    this
                        .hours
                        .map((h) => GestureDetector(
                            onTap: () => toggleHour(this.day, h),
                            child: Container(
                                child: Center(
                                    child: Text(hourName[h],
                                        style: DefaultTextStyle.of(context)
                                            .style
                                            .apply(color: Colors.white)
                                            .apply(fontSizeFactor: 1.2))),
                                margin: EdgeInsets.only(top: 5.0),
                                color: this
                                        .obligations
                                        .contains(hourToString(this.day, h))
                                    ? Colors.grey
                                    : Colors.lightBlue,
                                width: 160.0,
                                height: 40.0)))
                        .toList()),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                    onPressed: increaseDay, child: Icon(Icons.chevron_right))
              ],
            )
          ],
        ));
  }
}
