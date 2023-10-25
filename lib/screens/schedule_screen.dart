import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../APIfunctions/groupsAPI.dart';
import '../components/group_card.dart';
import '../utils/colors.dart';
import '../utils/globals.dart';
import '../utils/group.dart';
import '../utils/schedule_manager.dart';

class ScheduleScreen extends StatefulWidget {
  late ScheduleManager filter;

  ScheduleScreen(this.filter);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _reserveToggle = false;
  int currentMonth = DateTime.now().month;
  int currentDay = DateTime.now().day;
  Future<bool>? done;
  List<List<Group>> groups = [];
  double totalHeight = 120;
  bool reserving = false;
  bool browsing = true;

  @override
  void initState() {
    widget.filter.refreshFilter();

    done = ParseGroups();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double toggleHeight = 50;
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      color: backgroundColor,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextButton(
                onPressed: !_reserveToggle
                    ? () {
                        totalHeight == 50;
                        reserving = true;
                        browsing = false;
                        setState(() => _reserveToggle = true);
                      }
                    : null,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: Container(
                  width: 100,
                  height: toggleHeight,
                  color: _reserveToggle ? mainSchemeColor : black,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Reserve',
                      style: TextStyle(
                        color: _reserveToggle ? black : white,
                        fontSize: infoFontSize,
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _reserveToggle
                    ? () {
                        totalHeight == 120;
                        reserving = false;
                        browsing = true;
                        setState(() => _reserveToggle = false);
                      }
                    : null,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: Container(
                  width: 100,
                  height: toggleHeight,
                  color: _reserveToggle ? black : mainSchemeColor,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Browse',
                      style: TextStyle(
                        color: _reserveToggle ? white : black,
                        fontSize: infoFontSize,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ValueListenableBuilder<bool>(
                valueListenable: widget.filter.changedNotifier,
                builder: (_, value, __) {
                  if (value) {
                    done = ParseGroups();
                    widget.filter.finUpdate();
                  }
                  return FutureBuilder(
                      future: done,
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.none:
                          case ConnectionState.active:
                          case ConnectionState.waiting:
                            return const CircularProgressIndicator();
                          case ConnectionState.done:
                            if (snapshot.hasError) {
                              return Text('Error: $snapshot.error}');
                            }
                            int days = 0;

                            return CustomScrollView(
                              slivers: groups
                                  .map((list) => Section(
                                        currentMonth: widget.filter.start
                                            .add(Duration(days: days))
                                            .month,
                                        currentDay: widget.filter.start
                                            .add(Duration(days: days++))
                                            .day,
                                        groups: list,
                                        reserving: reserving,
                                        browsing: browsing,
                                        totalHeight: totalHeight,
                                      ))
                                  .toList(),
                            );
                        }
                      });
                }),
          ),
        ],
      ),
    );
  }

  Future<bool> ParseGroups() async {
    groups = [];

    DateTime end = widget.filter.end.add(const Duration(days: 1));
    Map<String, dynamic> queryDate = {};

    int j = 0;
    for (DateTime start = widget.filter.start;
        start != end;
        start = start.add(const Duration(days: 1))) {
      queryDate['date'] = DateFormat('yyyy-MM-dd').format(start);

      final res = await GroupsAPI.getSchedule(queryDate);

      if (res.statusCode != 200) {
        print(res.statusCode);
        return false;
      }
      print(res.body);
      String date = DateFormat('yyyy-MM-dd').format(start);

      var data = json.decode(res.body);
      groups.add(List.empty(growable: true));

      for (var concerts in data['scheduledTimes']) {
        Group newGroup = Group.fromDateConcert(date, concerts);
        if (groups.isNotEmpty) {
          int place = 0;
          for (int i = 0; i < groups[j].length; i++) {
            if (newGroup.date!.isBefore(groups[j][i].date!)) {
              break;
            }
            place++;
          }
          groups[j].insert(place, newGroup);
        } else {
          groups[j].add(newGroup);
        }
      }
      j++;
    }
    return true;
  }
}

class Section extends StatelessWidget {
  final int currentMonth;
  final int currentDay;
  final List<Group> groups;
  late final List<DateTime> tempList;
  bool reserving;
  bool browsing;
  double totalHeight;

  Section(
      {required this.currentMonth,
      required this.currentDay,
      required this.groups,
      required this.reserving,
      required this.browsing,
      required this.totalHeight}) {
    tempList = dateList();
  }

  List<DateTime> dateList() {
    DateTime date;
    if (currentDay == DateTime.now().day) {
      DateTime now = DateTime.now();
      if (now.minute % 20 != 0) {
        now = now.subtract(Duration(minutes: now.minute % 20));
      }
      date = DateTime(0, currentMonth, currentDay, now.hour, now.minute);
    } else {
      date = DateTime(0, currentMonth, currentDay);
    }

    List<DateTime> toRet = [];
    int hoursUntilEndOfDay = 23 - date.hour;
    int minutesUntilEndOfDay = 60 - date.minute;
    DateTime end = date.add(Duration(hours: hoursUntilEndOfDay, minutes: minutesUntilEndOfDay));
    for (DateTime start = date;
        start != end;
        start = start.add(const Duration(minutes: 20))) {
      toRet.add(start);
    }
    return toRet;
  }

  @override
  Widget build(BuildContext context) {
    int groupList = 0;
    return MultiSliver(
      pushPinnedChildren: true,
      children: <Widget>[
        SliverPinnedHeader(
            child: Column(children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            width: double.infinity,
            color: backgroundColor,
            child: Text(
              DateFormat('MMMM dd')
                  .format(DateTime(0, currentMonth, currentDay)),
              style: TextStyle(
                fontSize: 32,
                color: textColor,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const Divider(
            height: 5,
            thickness: 1,
            color: black,
          ),
        ])),
        SliverList(
            delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (groupList < groups.length &&
                groupList >= 0 &&
                tempList[index] == groups[groupList].date) {
              return GroupCard(
                group: groups[groupList],
                height: totalHeight,
                clickable: browsing,
              );
            } else {
              return GroupCard(
                date: tempList[index],
                height: totalHeight,
                clickable: reserving,
              );
            }
          },
          childCount: tempList.length,
        ))
      ],
    );
  }
}
