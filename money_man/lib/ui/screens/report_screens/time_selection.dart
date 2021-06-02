import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:money_man/core/models/time_range_info_model.dart';
import 'package:page_transition/page_transition.dart';

import 'custom_time_range.dart';

class TimeRangeSelection extends StatefulWidget {
  final dateDescription;
  final beginDate;
  final endDate;

  TimeRangeSelection(
      {Key key,
      @required this.dateDescription,
      @required this.beginDate,
      @required this.endDate})
      : super(key: key);

  @override
  TimeRangeSelectionState createState() => TimeRangeSelectionState();
}

class TimeRangeSelectionState extends State<TimeRangeSelection> {
  dynamic _dateDescription;
  dynamic _beginDate;
  dynamic _endDate;

  List<dynamic> listInfo = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _dateDescription = widget.dateDescription;
    _beginDate = widget.beginDate;
    _endDate = widget.endDate;

    listInfo.clear();
    listInfo.add(TimeRangeInfo(
        description: 'This month',
        begin: DateTime(DateTime.now().year, DateTime.now().month, 1),
        end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0)));
    listInfo.add(TimeRangeInfo(
        description: 'Custom',
        begin: _dateDescription == 'Custom' ? _beginDate : null,
        end: _dateDescription == 'Custom' ? _endDate : null));
  }

  @override
  void didUpdateWidget(covariant TimeRangeSelection oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    _dateDescription = widget.dateDescription;
    _beginDate = widget.beginDate;
    _endDate = widget.endDate;

    listInfo.clear();
    listInfo.add(TimeRangeInfo(
        description: 'This month',
        begin: DateTime(DateTime.now().year, DateTime.now().month, 1),
        end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0)));
    listInfo.add(TimeRangeInfo(
        description: 'Custom',
        begin: _dateDescription == 'Custom' ? _beginDate : null,
        end: _dateDescription == 'Custom' ? _endDate : null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black45,
        appBar: AppBar(
          leadingWidth: 70.0,
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0))),
          title: Text('Select Time Range',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 15.0)),
          leading: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                primary: Colors.white,
                backgroundColor: Colors.transparent,
              )),
        ),
        body: ListView.separated(
          itemCount: listInfo.length,
          separatorBuilder: (BuildContext context, int index) => Divider(),
          itemBuilder: (BuildContext context, int index) {
            String beginDate = (listInfo[index].begin == null)
                ? 'Day/Month/Year'
                : DateFormat('dd/MM/yyyy').format(listInfo[index].begin);
            String endDate = (listInfo[index].end == null)
                ? 'Day/Month/Year'
                : DateFormat('dd/MM/yyyy').format(listInfo[index].end);

            return ListTile(
              onTap: () async {
                if (listInfo[index].description == 'Custom') {
                  final result = await showCupertinoModalBottomSheet(
                      isDismissible: true,
                      backgroundColor: Colors.grey[900],
                      context: context,
                      builder: (context) => CustomTimeRange(
                          beginDate:
                              _dateDescription == 'Custom' ? _beginDate : null,
                          endDate:
                              _dateDescription == 'Custom' ? _endDate : null));
                  if (result.runtimeType == listInfo[0].runtimeType &&
                      result != null) {
                    setState(() {
                      listInfo.removeLast();
                      listInfo.add(result);
                      _dateDescription = listInfo[index].description;
                    });
                    Navigator.of(context).pop(result);
                  }
                } else {
                  var result = TimeRangeInfo(
                      description: listInfo[index].description,
                      begin: listInfo[index].begin,
                      end: listInfo[index].end);
                  setState(() {
                    _dateDescription = listInfo[index].description;
                  });
                  Navigator.of(context).pop(result);
                }
              },
              title: Text(listInfo[index].description,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  )),
              subtitle: Text(beginDate + " - " + endDate,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                  )),
              trailing: _dateDescription == listInfo[index].description
                  ? Icon(Icons.check, color: Colors.blueAccent)
                  : null,
            );
          },
        ));
  }
}
