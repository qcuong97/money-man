import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:money_man/core/models/super_icon_model.dart';
import 'package:money_man/core/models/wallet_model.dart';
import 'package:money_man/core/services/firebase_authentication_services.dart';
import 'package:money_man/core/services/firebase_firestore_services.dart';
import 'package:money_man/ui/screens/planning_screens/event_screen/add_event.dart';
import 'package:money_man/ui/screens/planning_screens/event_screen/applied_event.dart';
import 'package:money_man/ui/screens/planning_screens/event_screen/current_applied_event.dart';
import 'package:money_man/ui/screens/wallet_selection_screens/wallet_selection.dart';
import 'package:money_man/ui/style.dart';
import 'package:provider/provider.dart';

// Này là trang chủ của event nè
class EventScreen extends StatefulWidget {
  final Wallet currentWallet; // truyền vào ví hiện tại

  const EventScreen({Key key, this.currentWallet}) : super(key: key);
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen>
    with TickerProviderStateMixin {
  // Truyền vào tab controller
  TabController _tabController;
  // ví hiện tại
  Wallet _wallet;

  @override
  void initState() {
    // Khởi tạo các giá trị
    super.initState();
    _wallet = widget.currentWallet != null
        ? widget.currentWallet
        : Wallet(
            id: 'id',
            name: 'defaultName',
            amount: 100,
            currencyID: 'USD',
            iconID: 'assets/icons/wallet_2.svg');
    _tabController = new TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Tham chiếu đến các hàm của firebase
    final _firestore = Provider.of<FirebaseFireStoreService>(context);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Style.appBarColor,
                leading: IconButton(
                  icon: Icon(
                    Style.backIcon,
                    color: Style.foregroundColor,
                  ),
                  // Thoát nè
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                title: Text(
                  "Event",
                  style: TextStyle(
                    fontFamily: Style.fontFamily,
                    fontSize: 17.0,
                    fontWeight: FontWeight.w600,
                    color: Style.foregroundColor,
                  ),
                ),
                actions: [
                  GestureDetector(
                    // Thay đổi ví nè
                    onTap: () async {
                      buildShowDialog(context, _wallet.id);
                    },
                    child: Container(
                      padding: EdgeInsets.only(left: 20.0),
                      child: Row(
                        children: [
                          SuperIcon(
                            iconPath: _wallet.iconID,
                            size: 25.0,
                          ),
                          Icon(Icons.arrow_drop_down,
                              color: Style.foregroundColor)
                        ],
                      ),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(40),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TabBar(
                      labelStyle: TextStyle(
                        fontFamily: Style.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.0,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontFamily: Style.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.0,
                      ),
                      unselectedLabelColor:
                          Style.foregroundColor.withOpacity(0.54),
                      labelColor: Style.foregroundColor,
                      isScrollable: true,
                      controller: _tabController,
                      indicatorColor: Style.primaryColor,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(
                            child: Container(
                          width: 120,
                          child: Center(
                            child: Text(
                              "Running",
                            ),
                          ),
                        )),
                        Tab(
                            child: Container(
                          width: 120,
                          child: Center(
                            child: Text(
                              "Finished",
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                elevation: 0,
                centerTitle: true,
              ),
              // Stream lấy ví hiện tại
              body: StreamBuilder<Object>(
                  stream: _firestore.currentWallet,
                  builder: (context, snapshot) {
                    _wallet = snapshot.data ??
                        Wallet(
                            id: 'id',
                            name: 'defaultName',
                            amount: 100,
                            currencyID: 'USD',
                            iconID: 'assets/icons/wallet_2.svg');
                    return Container(
                        color: Style.backgroundColor,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            CurrentlyAppliedEvent(
                              wallet: _wallet,
                            ),
                            AppliedEvent(
                              wallet: _wallet,
                            ),
                          ],
                        ));
                  }),
              floatingActionButton: FloatingActionButton(
                child: Icon(
                  Icons.add_rounded,
                  size: 30,
                ),
                backgroundColor: Style.primaryColor,
                elevation: 0,
                // Thêm event
                onPressed: () async {
                  await showCupertinoModalBottomSheet(
                      isDismissible: true,
                      backgroundColor: Colors.grey[900],
                      context: context,
                      builder: (context) => AddEvent(
                            wallet: _wallet,
                          ));
                },
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.startTop,
            )));
  }

// hàm gọi khi thay đổi ví, nó hiện cái màn hình chọn ví lên á
  void buildShowDialog(BuildContext context, id) async {
    final _auth = locator<FirebaseAuthService>();
    final _firebase =
        Provider.of<FirebaseFireStoreService>(context, listen: false);
    final result = await showCupertinoModalBottomSheet(
        isDismissible: true,
        backgroundColor: Style.backgroundColor,
        context: context,
        builder: (context) {
          return Provider(
              create: (_) {
                return FirebaseFireStoreService(uid: _auth.currentUser.uid);
              },
              child: WalletSelectionScreen(
                id: id,
              ));
        });
    final updateWallet = await _firebase.getWalletByID(result);
    setState(() {
      _wallet = updateWallet;
    });
  }
}
