import 'dart:typed_data';
import 'dart:ui';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_man/core/services/firebase_authentication_services.dart';
import 'package:money_man/ui/screens/report_screens/analytic_revenue_expenditure_screen.dart';
import 'package:money_man/ui/screens/report_screens/bar_chart.dart';
import 'package:money_man/ui/screens/report_screens/pie_chart.dart';
import 'package:money_man/ui/screens/report_screens/analytic_pie_chart_screen.dart';
import 'package:money_man/ui/screens/report_screens/share_report/utils.dart';
import 'package:money_man/ui/screens/report_screens/share_report/widget_to_image.dart';
import 'package:money_man/ui/screens/report_screens/share_screen.dart';
import 'package:money_man/ui/widgets/money_symbol_formatter.dart';
import 'package:page_transition/page_transition.dart';
import '../../style.dart';
import 'package:money_man/ui/screens/wallet_selection_screens/wallet_selection.dart';
import 'package:money_man/core/models/transaction_model.dart';
import 'package:money_man/core/models/category_model.dart';
import 'package:money_man/core/models/wallet_model.dart';
import 'package:provider/provider.dart';
import 'package:money_man/core/services/firebase_firestore_services.dart';

class ReportForThisPeriodScreen extends StatefulWidget {
  Wallet currentWallet;
  DateTime beginDate;
  DateTime endDate;
  ReportForThisPeriodScreen(
      {Key key, this.currentWallet, this.endDate, this.beginDate})
      : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _ReportForThisPeriodScreen();
  }
}

class _ReportForThisPeriodScreen extends State<ReportForThisPeriodScreen>
    with TickerProviderStateMixin {
  GlobalKey key1;
  GlobalKey key2;
  GlobalKey key3;
  Uint8List bytes1;
  Uint8List bytes2;
  Uint8List bytes3;

  final double fontSizeText = 30;
  // Cái này để check xem element đầu tiên trong ListView chạm đỉnh chưa.
  int reachTop = 0;
  int reachAppBar = 0;

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

  // biến của ví hiện tại
  Wallet wallet;

  // Khởi tạo mốc thời gian cần thống kê.
  DateTime beginDate;
  DateTime endDate;
  String dateDescript = 'This month';

  @override
  void initState() {
    beginDate = widget.beginDate ??
        DateTime(DateTime.now().year, DateTime.now().month, 1);
    endDate = widget.endDate ??
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    _controller = ScrollController();
    _controller.addListener(_scrollListener);
    super.initState();
    wallet = widget.currentWallet == null
        ? Wallet(
            id: 'id',
            name: 'defaultName',
            amount: 0,
            currencyID: 'USD',
            iconID: 'assets/icons/wallet_2.svg')
        : widget.currentWallet;
  }

  @override
  void didUpdateWidget(covariant ReportForThisPeriodScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    wallet = widget.currentWallet ??
        Wallet(
            id: 'id',
            name: 'defaultName',
            amount: 0,
            currencyID: 'USD',
            iconID: 'assets/icons/wallet_2.svg');
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirebaseFireStoreService>(context);
    return DefaultTabController(
      length: 300,
      child: Scaffold(
          backgroundColor: Style.backgroundColor,
          extendBodyBehindAppBar: true,
          appBar: new AppBar(
            backgroundColor: Style.backgroundColor,
            centerTitle: true,
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
                    color: Colors.grey[reachAppBar == 1
                            ? (reachTop == 1 ? 800 : 850)
                            : 900]
                        .withOpacity(0.2),
                  ),
                ),
              ),
            ),
            leadingWidth: 70,
            leading: GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
              },
              child: Container(
                child: Icon(Icons.arrow_back_ios),
              ),
            ),
            title: GestureDetector(
              onTap: () async {},
              child: Container(
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: <Widget>[
                        Text(
                          'This period',
                          style: TextStyle(
                            fontFamily: Style.fontFamily,
                            fontWeight: FontWeight.w600,
                            color: Style.foregroundColor,
                            fontSize: 14.0,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(beginDate) +
                              " - " +
                              DateFormat('dd/MM/yyyy').format(endDate),
                          style: TextStyle(
                              fontFamily: Style.fontFamily,
                              color: Style.foregroundColor.withOpacity(0.7),
                              fontSize: 12.0,
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              Hero(
                tag: 'shareButton',
                child: MaterialButton(
                  child: Icon(Icons.ios_share, color: Style.foregroundColor),
                  onPressed: () async {
                    final bytes1 = await Utils.capture(key1);
                    final bytes2 = await Utils.capture(key2);
                    final bytes3 = await Utils.capture(key3);

                    setState(() {
                      this.bytes1 = bytes1;
                      this.bytes2 = bytes2;
                      this.bytes3 = bytes3;
                    });

                    showCupertinoModalBottomSheet(
                        isDismissible: true,
                        backgroundColor: Style.boxBackgroundColor,
                        context: context,
                        builder: (context) => ShareScreen(
                            bytes1: this.bytes1,
                            bytes2: this.bytes2,
                            bytes3: this.bytes3));
                  },
                ),
              ),
            ],
          ),
          body: StreamBuilder<Object>(
              stream: firestore.transactionStream(wallet, 'full'),
              builder: (context, snapshot) {
                List<MyTransaction> transactionList = snapshot.data ?? [];
                List<MyCategory> incomeCategoryList = [];
                List<MyCategory> expenseCategoryList = [];

                double openingBalance = 0;
                double closingBalance = 0;
                double income = 0;
                double expense = 0;

                transactionList.forEach((element) {
                  if (element.date.isBefore(beginDate)) {
                    if (element.category.type == 'expense')
                      openingBalance -= element.amount;
                    else if (element.category.type == 'income')
                      openingBalance += element.amount;
                  }
                  if (element.date.compareTo(endDate) <= 0) {
                    if (element.category.type == 'expense') {
                      closingBalance -= element.amount;
                      if (element.date.compareTo(beginDate) >= 0) {
                        expense += element.amount;

                        if (!expenseCategoryList.any((categoryElement) {
                          if (categoryElement.name == element.category.name)
                            return true;
                          else
                            return false;
                        })) {
                          expenseCategoryList.add(element.category);
                        }
                      }
                    } else if (element.category.type == 'income') {
                      closingBalance += element.amount;
                      if (element.date.compareTo(beginDate) >= 0) {
                        income += element.amount;
                        if (!incomeCategoryList.any((categoryElement) {
                          if (categoryElement.name == element.category.name)
                            return true;
                          else
                            return false;
                        })) {
                          incomeCategoryList.add(element.category);
                        }
                      }
                    }
                  }
                });

                transactionList = transactionList
                    .where((element) =>
                        element.date.compareTo(beginDate) >= 0 &&
                        element.date.compareTo(endDate) <= 0 &&
                        element.category.type != 'debt & loan')
                    .toList();
                return Container(
                  color: Style.backgroundColor,
                  child: ListView(
                    controller: _controller,
                    physics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                        decoration: BoxDecoration(
                            color: Style.backgroundColor,
                            border: Border(
                              bottom: BorderSide(
                                color: Style.foregroundColor.withOpacity(0.24),
                                width: 0.5,
                              ),
                            )),
                        child: WidgetToImage(
                          builder: (key) {
                            this.key1 = key;

                            return Container(
                              color: Style
                                  .backgroundColor, // để lúc export ra không bị transparent.
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              'Opening balance',
                                              style: TextStyle(
                                                color: Style.foregroundColor
                                                    .withOpacity(0.7),
                                                fontFamily: Style.fontFamily,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 15,
                                              ),
                                            ),
                                            MoneySymbolFormatter(
                                              checkOverflow: true,
                                              text: openingBalance,
                                              currencyId: wallet.currencyID,
                                              textStyle: TextStyle(
                                                color: Style.foregroundColor,
                                                fontFamily: Style.fontFamily,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 20,
                                                height: 1.5,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              'Closing balance',
                                              style: TextStyle(
                                                color: Style.foregroundColor
                                                    .withOpacity(0.7),
                                                fontFamily: Style.fontFamily,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 15,
                                              ),
                                            ),
                                            MoneySymbolFormatter(
                                              checkOverflow: true,
                                              text: closingBalance,
                                              currencyId: wallet.currencyID,
                                              textStyle: TextStyle(
                                                color: Style.foregroundColor,
                                                fontFamily: Style.fontFamily,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 20,
                                                height: 1.5,
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  Divider(
                                    color:
                                        Style.foregroundColor.withOpacity(0.12),
                                    thickness: 1,
                                    height: 20,
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Hero(
                                    tag: 'netIncomeChart',
                                    child: Material(
                                      color: Style.backgroundColor,
                                      child: Column(
                                        children: [
                                          Text('Net Income',
                                              style: TextStyle(
                                                color: Style.foregroundColor
                                                    .withOpacity(0.7),
                                                fontFamily: Style.fontFamily,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 16,
                                              )),
                                          MoneySymbolFormatter(
                                              text: closingBalance -
                                                  openingBalance,
                                              currencyId: wallet.currencyID,
                                              textStyle: TextStyle(
                                                color: (closingBalance -
                                                            openingBalance) >
                                                        0
                                                    ? Style.incomeColor
                                                    : (closingBalance -
                                                                openingBalance) ==
                                                            0
                                                        ? Style.foregroundColor
                                                        : Style.expenseColor,
                                                fontFamily: Style.fontFamily,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 26,
                                                height: 1.5,
                                              )),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  PageTransition(
                                                      childCurrent: this.widget,
                                                      child:
                                                          AnalyticRevenueAndExpenditureScreen(
                                                        currentWallet: wallet,
                                                        beginDate: beginDate,
                                                        endDate: endDate,
                                                      ),
                                                      type: PageTransitionType
                                                          .rightToLeft));
                                            },
                                            child: Container(
                                              width: 450,
                                              height: 200,
                                              child: BarChartScreen(
                                                  currentList: transactionList,
                                                  beginDate: beginDate,
                                                  endDate: endDate),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: WidgetToImage(
                                  builder: (key) {
                                    this.key2 = key;

                                    return Container(
                                      color: Style
                                          .backgroundColor, // để lúc export ra không bị transparent.
                                      child: Column(
                                        children: <Widget>[
                                          Text(
                                            'Income',
                                            style: TextStyle(
                                              color: Style.foregroundColor
                                                  .withOpacity(0.7),
                                              fontFamily: Style.fontFamily,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 16,
                                            ),
                                            textAlign: TextAlign.start,
                                          ),
                                          MoneySymbolFormatter(
                                            checkOverflow: true,
                                            text: income,
                                            currencyId: wallet.currencyID,
                                            textStyle: TextStyle(
                                              color: Style.incomeColor2,
                                              fontFamily: Style.fontFamily,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 24,
                                              height: 1.5,
                                            ),
                                            textAlign: TextAlign.start,
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  PageTransition(
                                                      childCurrent: this.widget,
                                                      child:
                                                          AnalyticPieChartScreen(
                                                        currentWallet: wallet,
                                                        type: 'income',
                                                        beginDate: beginDate,
                                                        endDate: endDate,
                                                      ),
                                                      type: PageTransitionType
                                                          .rightToLeft));
                                            },
                                            child: Container(
                                              color: Colors.transparent,
                                              child: PieChartScreen(
                                                  isShowPercent: false,
                                                  currentList: transactionList,
                                                  categoryList:
                                                      incomeCategoryList,
                                                  total: income),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                child: WidgetToImage(
                                  builder: (key) {
                                    this.key3 = key;

                                    return Container(
                                      color: Style
                                          .backgroundColor, // để lúc export ra không bị transparent.
                                      child: Column(children: <Widget>[
                                        Text(
                                          'Expense',
                                          style: TextStyle(
                                            color: Style.foregroundColor
                                                .withOpacity(0.7),
                                            fontFamily: Style.fontFamily,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.start,
                                        ),
                                        MoneySymbolFormatter(
                                          checkOverflow: true,
                                          text: expense,
                                          currencyId: wallet.currencyID,
                                          textStyle: TextStyle(
                                            color: Style.expenseColor,
                                            fontFamily: Style.fontFamily,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 24,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.start,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                PageTransition(
                                                    childCurrent: this.widget,
                                                    child:
                                                        AnalyticPieChartScreen(
                                                      currentWallet: wallet,
                                                      type: 'expense',
                                                      beginDate: beginDate,
                                                      endDate: endDate,
                                                    ),
                                                    type: PageTransitionType
                                                        .rightToLeft));
                                          },
                                          child: Container(
                                            color: Colors.transparent,
                                            child: PieChartScreen(
                                                isShowPercent: false,
                                                currentList: transactionList,
                                                categoryList:
                                                    expenseCategoryList,
                                                total: expense),
                                          ),
                                        ),
                                      ]),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })),
    );
  }

  void buildShowDialog(BuildContext context, id) async {
    final auth = locator<FirebaseAuthService>();

    await showCupertinoModalBottomSheet(
        isDismissible: true,
        backgroundColor: Style.boxBackgroundColor,
        context: context,
        builder: (context) {
          return Provider(
              create: (_) {
                return FirebaseFireStoreService(uid: auth.currentUser.uid);
              },
              child: WalletSelectionScreen(
                id: id,
              ));
        });
  }
}
