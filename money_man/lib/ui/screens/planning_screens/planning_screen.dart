import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:money_man/core/models/super_icon_model.dart';
import 'package:money_man/core/models/wallet_model.dart';
import 'package:money_man/ui/screens/planning_screens/bills_screens/bills_main_screen.dart';
import 'package:money_man/ui/screens/planning_screens/budget_screens/budget_home.dart';
import 'package:money_man/ui/screens/planning_screens/recurring_transaction_screens/recurring_transaction_main_screen.dart';
import 'package:money_man/ui/screens/planning_screens/budget_screens/budget_home.dart';
import 'package:money_man/ui/screens/planning_screens/event_screen/event_home.dart';
import 'package:money_man/ui/style.dart';
import 'package:page_transition/page_transition.dart';

class PlanningScreen extends StatefulWidget {
  Wallet currentWallet;

  PlanningScreen({Key key, this.currentWallet}) : super(key: key);

  @override
  _PlanningScreenState createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  Wallet _wallet;

  final double fontSizeText = 30;
  // Cái này để check xem element đầu tiên trong ListView chạm đỉnh chưa.
  int reachTop = 0;
  int reachAppBar = 0;
  //
  // Text title = Text('Planning', style: TextStyle(fontSize: 30, color: Colors.white, fontFamily: 'Montserrat', fontWeight: FontWeight.bold));
  // Text emptyTitle = Text('', style: TextStyle(fontSize: 30, color: Colors.white, fontFamily: 'Montserrat', fontWeight: FontWeight.bold));

  // Phần này để check xem mình đã Scroll tới đâu trong ListView
  ScrollController _controller = ScrollController();
  _scrollListener() {
    if (_controller.offset > 0) {
      setState(() {
        reachAppBar = 1;
      });
    } else {
      setState(() {
        reachAppBar = 0;
      });
    }
    if (_controller.offset >= fontSizeText - 5) {
      setState(() {
        reachTop = 1;
      });
    } else {
      setState(() {
        reachTop = 0;
      });
    }
  }

  @override
  void initState() {
    _controller = ScrollController();
    _controller.addListener(_scrollListener);
    super.initState();
    _wallet = widget.currentWallet == null
        ? Wallet(
            id: 'id',
            name: 'defaultName',
            amount: 0,
            currencyID: 'USD',
            iconID: 'assets/icons/wallet_2.svg')
        : widget.currentWallet;
  }

  @override
  void didUpdateWidget(covariant PlanningScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    _wallet = widget.currentWallet ??
        Wallet(
            id: 'id',
            name: 'defaultName',
            amount: 100,
            currencyID: 'USD',
            iconID: 'assets/icons/wallet_2.svg');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Style.backgroundColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: AnimatedOpacity(
              opacity: reachAppBar == 1 ? 1 : 0,
              duration: Duration(milliseconds: 0),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: reachTop == 1 ? 25 : 500,
                    sigmaY: 25,
                    tileMode: TileMode.values[0]),
                child: AnimatedContainer(
                  duration: Duration(
                      milliseconds:
                          reachAppBar == 1 ? (reachTop == 1 ? 100 : 0) : 0),
                  //child: Container(
                  //color: Colors.transparent,
                  color: Colors.grey[
                          reachAppBar == 1 ? (reachTop == 1 ? 800 : 850) : 900]
                      .withOpacity(0.2),
                  //),
                ),
              ),
            ),
          ),
          title: AnimatedOpacity(
              opacity: reachTop == 1 ? 1 : 0,
              duration: Duration(milliseconds: 100),
              child: Text('Planning',
                  style: TextStyle(
                      fontSize: 50,
                      color: Style.foregroundColor,
                      fontFamily: Style.fontFamily,
                      fontWeight: FontWeight.bold))),
        ),
        body: ListView(
          physics:
              BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          controller: _controller,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8.0),
                child: reachTop == 0
                    ? Hero(
                        tag: 'alo',
                        child: Text('Planning',
                            style: TextStyle(
                                fontSize: 50,
                                color: Style.foregroundColor,
                                fontFamily: Style.fontFamily,
                                fontWeight: FontWeight.bold)))
                    : Text('',
                        style: TextStyle(
                            fontSize: 30,
                            color: Style.foregroundColor,
                            fontFamily: Style.fontFamily,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(110.0, 20.0, 110.0, 10.0),
              //padding: EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 10.0),
              decoration: BoxDecoration(
                color: Color(0xff5eb4e7),
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BudgetScreen()));
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    child: Column(
                      children: [
                        SuperIcon(
                          iconPath: 'assets/images/budget.svg',
                          size: 45,
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Text('BUDGET',
                            style: TextStyle(
                                color: Style.foregroundColor,
                                fontWeight: FontWeight.w600,
                                fontFamily: Style.fontFamily,
                                fontSize: 15.0)),
                      ],
                    ),
                  )),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(110.0, 10.0, 110.0, 10.0),
              decoration: BoxDecoration(
                color: Color(0xfff3653f),
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: TextButton(
                  onPressed: () {
                    print('planing' + widget.currentWallet.id);
                    print('planing' + _wallet.id);
                    Navigator.push(
                      context,
                      PageTransition(
                          child: BillsMainScreen(
                            currentWallet: _wallet,
                          ),
                          type: PageTransitionType.rightToLeft),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    child: Column(
                      children: [
                        SuperIcon(
                          iconPath: 'assets/images/bill.svg',
                          size: 45,
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Text('BILLS',
                            style: TextStyle(
                                color: Style.foregroundColor,
                                fontWeight: FontWeight.w600,
                                fontFamily: Style.fontFamily,
                                fontSize: 15.0)),
                      ],
                    ),
                  )),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(110.0, 10.0, 110.0, 10.0),
              //padding: EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 10.0),
              decoration: BoxDecoration(
                color: Color(0xffe2d839),
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                          child: EventScreen(),
                          type: PageTransitionType.rightToLeft),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    child: Column(
                      children: [
                        SuperIcon(
                          iconPath: 'assets/images/event.svg',
                          size: 45,
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Text('EVENTS',
                            style: TextStyle(
                                color: Style.foregroundColor,
                                fontWeight: FontWeight.w600,
                                fontFamily: Style.fontFamily,
                                fontSize: 15.0)),
                      ],
                    ),
                  )),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(110.0, 10.0, 110.0, 10.0),
              //padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
              decoration: BoxDecoration(
                color: Color(0xff65f33f),
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                          child:
                              RecurringTransactionMainScreen(wallet: _wallet),
                          type: PageTransitionType.rightToLeft),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    child: Column(
                      children: [
                        SuperIcon(
                          iconPath: 'assets/images/recurring.svg',
                          size: 45,
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Text('RECURRING',
                            style: TextStyle(
                                color: Style.foregroundColor,
                                fontWeight: FontWeight.w600,
                                fontFamily: Style.fontFamily,
                                fontSize: 15.0)),
                      ],
                    ),
                  )),
            ),
          ],
        ));
  }
}
