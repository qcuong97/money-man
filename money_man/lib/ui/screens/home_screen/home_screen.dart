import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:money_man/ui/screens/home_screen/home_view_model.dart';
import 'package:money_man/ui/screens/introduction_screens/first_step_first_wallet_screen.dart';
import 'package:money_man/ui/screens/planning_screens/planning_screen.dart';
import 'package:money_man/core/models/wallet_model.dart';
import 'package:money_man/core/services/firebase_firestore_services.dart';
import 'package:money_man/ui/screens/account_screens/account_screen.dart';
import 'package:money_man/ui/screens/report_screens/report_screen.dart';
import 'package:money_man/ui/screens/shared_screens/loading_screen.dart';
import 'package:money_man/ui/screens/transaction_screens/add_transaction_screen.dart';
import 'package:money_man/ui/screens/transaction_screens/transaction_screen.dart';
import 'package:money_man/ui/style.dart';
import 'package:provider/provider.dart';

import '../../../core/services/firebase_authentication_services.dart';
import '../../../locator.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  int theme;
  final viewModel = locator<HomeViewModel>();

  void _onItemTap(int index, Wallet wallet) {
    if (selectedIndex != index) {
      if (index == 2) {
        showCupertinoModalBottomSheet(
            isDismissible: true,
            backgroundColor: Style.boxBackgroundColor,
            context: context,
            builder: (context) => AddTransactionScreen(currentWallet: wallet));
      } else
        selectedIndex = index;
    }
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      int result = await getTheme();
      setState(() {
        theme = result;
        Style.changeTheme(theme);
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      viewModel.getData();
    });
    super.initState();
  }

  getTheme() async {
    final firestore =
        locator<FirebaseFireStoreService>();
    return firestore.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>.value(
        value: viewModel,
        child: Consumer<HomeViewModel>(
          builder: (context, model, child) {
            List<Widget> _screens = [
              TransactionScreen(currentWallet: model.wallet),
              ReportScreen(currentWallet: model.wallet),
              AddTransactionScreen(currentWallet: model.wallet),
              PlanningScreen(currentWallet: model.wallet),
              AccountScreen(),
            ];

            if (model.isLoading) {
              return LoadingScreen();
            } else if (model.wallet == null) {
              return FirstStepForFirstWallet();
            } else
              return Scaffold(
                backgroundColor: Style.boxBackgroundColor2,
                body: _screens.elementAt(selectedIndex),
                bottomNavigationBar: BottomAppBar(
                  notchMargin: 5,
                  shape: CircularNotchedRectangle(),
                  color: Style.backgroundColor,
                  child: BottomNavigationBar(
                      type: BottomNavigationBarType.fixed,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      items: <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                          icon: Icon(Icons.account_balance_wallet_rounded,
                              size: 25.0),
                          label: 'Transactions',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.analytics_sharp, size: 25.0),
                          label: 'Report',
                          //backgroundColor: Colors.grey[500],
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.add_circle,
                            color: Colors.transparent,
                            size: 0.0,
                          ),
                          label: '',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.article_sharp, size: 25.0),
                          label: 'Planning',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.account_circle, size: 25.0),
                          label: 'Account',
                        ),
                      ],
                      selectedLabelStyle: TextStyle(
                        fontFamily: Style.fontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontFamily: Style.fontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                      selectedItemColor: Style.foregroundColor,
                      unselectedItemColor:
                      Style.foregroundColor.withOpacity(0.54),
                      unselectedFontSize: 12.0,
                      selectedFontSize: 12.0,
                      currentIndex: selectedIndex,
                      onTap: (index) => _onItemTap(index, model.wallet)),
                ),
                floatingActionButton: FloatingActionButton(
                  child: Icon(
                    Icons.add_rounded,
                    size: 30,
                  ),
                  onPressed: () {
                    _onItemTap(2, model.wallet);
                  },
                  backgroundColor: Style.primaryColor,
                  elevation: 0,
                ),
                floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
              );
          },
        ));
    // hello there
  }

  Stream<FirebaseFireStoreService> getStreamOfMyModel() { //                        <--- Stream
    return Stream<FirebaseFireStoreService>.value(FirebaseFireStoreService(uid: ""));
  }
}
