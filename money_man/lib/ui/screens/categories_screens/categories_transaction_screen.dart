import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:money_man/core/models/category_model.dart';
import 'package:money_man/core/models/super_icon_model.dart';
import 'package:money_man/core/services/firebase_firestore_services.dart';
import 'package:money_man/ui/screens/transaction_screens/select_other_source.dart';
import 'package:provider/provider.dart';

class CategoriesTransactionScreen extends StatefulWidget {
  final String walletId;

  const CategoriesTransactionScreen({Key key, @required this.walletId})
      : super(key: key);

  @override
  _CategoriesTransactionScreenState createState() =>
      _CategoriesTransactionScreenState();
}

class _CategoriesTransactionScreenState
    extends State<CategoriesTransactionScreen> with TickerProviderStateMixin {
  // list tab category
  final List<Tab> categoryTypeTab = [
    Tab(
      text: 'DEBT & LOAN',
    ),
    Tab(
      text: 'EXPENSE',
    ),
    Tab(
      text: 'INCOME',
    ),
  ];

  final double fontSizeText = 30;
  // Cái này để check xem element đầu tiên trong ListView chạm đỉnh chưa.
  int reachTop = 0;
  int reachAppBar = 0;

  // Tab controller cho tab bar
  TabController _tabController;

  // Text title = Text('My Account', style: TextStyle(fontSize: 30, color: Colors.white, fontFamily: 'Montserrat', fontWeight: FontWeight.bold));
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
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _firestore = Provider.of<FirebaseFireStoreService>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        //extendBodyBehindAppBar: true,
        appBar: AppBar(
          leadingWidth: 250.0,
          leading: MaterialButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios, color: Colors.white),
                Hero(
                    tag: 'alo',
                    child: Text('More',
                        style: Theme.of(context).textTheme.headline6)),
              ],
            ),
          ),
          //),
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
              child: Text(
                  ''
                  'Categories',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montseratt',
                      fontSize: 17.0))),
          bottom: TabBar(
            unselectedLabelColor: Colors.grey[500],
            labelColor: Colors.white,
            indicatorColor: Colors.yellow[700],
            physics: NeverScrollableScrollPhysics(),
            isScrollable: true,
            indicatorWeight: 3.0,
            controller: _tabController,
            tabs: categoryTypeTab,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: categoryTypeTab.map((e) {
            return StreamBuilder<List<MyCategory>>(
                stream: _firestore.categoryStream,
                builder: (context, snapshot) {
                  final _listCategories = snapshot.data ?? [];
                  final _selectCateTab = _listCategories
                      .where((element) =>
                          element.type ==
                          categoryTypeTab[_tabController.index]
                              .text
                              .toLowerCase())
                      .toList();
                  return ListView.builder(
                      physics: BouncingScrollPhysics(),
                      controller: _controller,
                      itemCount: _selectCateTab.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: SuperIcon(
                              iconPath: _selectCateTab[index].iconID,
                              size: 35.0),
                          title: Text(_selectCateTab[index].name,
                              style: Theme.of(context).textTheme.subtitle1),
                          onTap: () async {
                            if (_selectCateTab[index].name == 'Repayment') {
                              var result = await showCupertinoModalBottomSheet(
                                  isDismissible: true,
                                  backgroundColor: Colors.grey[900],
                                  context: context,
                                  builder: (context) => SelectOtherSourceScreen(
                                      title: 'Select payment source',
                                      titleAtEnd: 'Tap to pay off other debt',
                                      criteria: 'Debt',
                                      walletId: widget.walletId));
                              if (result != null) {
                                Navigator.pop(
                                    context, [_selectCateTab[index], result]);
                              }
                            } else if (_selectCateTab[index].name ==
                                'Debt Collection') {
                              var result = await showCupertinoModalBottomSheet(
                                  backgroundColor: Colors.grey[900],
                                  context: context,
                                  builder: (context) => SelectOtherSourceScreen(
                                      title: 'Select debt collection source',
                                      titleAtEnd:
                                          'Tap to receive other debt collection',
                                      criteria: 'Loan',
                                      walletId: widget.walletId));
                              if (result != null) {
                                Navigator.pop(
                                    context, [_selectCateTab[index], result]);
                              }
                            } else
                              Navigator.pop(context, _selectCateTab[index]);
                          },
                        );
                      });
                });
          }).toList(),
        ),
      ),
    );
  }
}
