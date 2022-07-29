import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:money_man/core/models/super_icon_model.dart';
import 'package:money_man/core/services/firebase_authentication_services.dart';
import 'package:money_man/main.dart';
import 'package:money_man/ui/screens/account_screens/about_screen.dart';
import 'package:money_man/ui/screens/account_screens/my_wallets_screen.dart';
import 'package:money_man/ui/screens/account_screens/setting_screen.dart';
import 'package:money_man/ui/screens/categories_screens/categories_account_screen.dart';
import 'package:money_man/ui/style.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../locator.dart';
import 'account_detail_screen.dart';
import 'help_screens/help_screens.dart';

// Màn hình của tab account
class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Test();
  }
}

class Test extends StatefulWidget {
  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {
  // Link dẫn đến repo source code của đồ án
  String exploreURL = "https://github.com/ltk84/money-man/";

  // Cái này để check xem element đầu tiên trong ListView chạm đỉnh chưa.
  int reachTop = 0;
  int reachAppBar = 0;

  //
  Text title = Text('More',
      style: TextStyle(
          fontSize: 30,
          color: Style.foregroundColor,
          fontFamily: Style.fontFamily,
          fontWeight: FontWeight.bold));
  Text emptyTitle = Text('',
      style: TextStyle(
          fontSize: 30,
          color: Style.foregroundColor,
          fontFamily: Style.fontFamily,
          fontWeight: FontWeight.bold));

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
    if (_controller.offset >= title.style.fontSize - 5) {
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
  }

  @override
  Widget build(BuildContext context) {
    // Biến tham chiếu đến các chức năng của firebase
    final _auth = locator<FirebaseAuthService>();
    return Scaffold(
        backgroundColor: Style.backgroundColor,
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
                  color: Colors.grey[
                          reachAppBar == 1 ? (reachTop == 1 ? 800 : 850) : 900]
                      .withOpacity(0.2),
                ),
              ),
            ),
          ),
          title: AnimatedOpacity(
              opacity: reachTop == 1 ? 1 : 0,
              duration: Duration(milliseconds: 100),
              child: Text('More',
                  style: TextStyle(
                    color: Style.foregroundColor,
                    fontFamily: Style.fontFamily,
                    fontSize: 17.0,
                    fontWeight: FontWeight.w600,
                  ))),
        ),
        // Stream builder để lấy thông tin người dùng hiện tại
        body: StreamBuilder<User>(
            stream: _auth.userStream,
            builder: (context, snapshot) {
              User _user = snapshot.data;
              return ListView(
                physics: BouncingScrollPhysics(),
                controller: _controller,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 0, 0, 8.0),
                    child: reachTop == 0
                        ? Hero(
                            tag: 'alo',
                            child: Material(
                                color: Colors.transparent, child: title))
                        : emptyTitle,
                  ),
                  // Thông tin người dùng hiện tại
                  Container(
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      decoration: BoxDecoration(
                          color: Style.boxBackgroundColor,
                          border: Border(
                              top: BorderSide(
                                width: 0.1,
                                color: Style.foregroundColor.withOpacity(0.12),
                              ),
                              bottom: BorderSide(
                                width: 0.1,
                                color: Style.foregroundColor.withOpacity(0.12),
                              ))),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: Style.foregroundColor,
                            radius: 30.0,
                            child: Text(
                              (_user == null)
                                  ? ''
                                  : (_user.displayName != '' &&
                                          _user.displayName != null)
                                      ? _user.displayName.substring(0, 1)
                                      : 'Y',
                              style: TextStyle(
                                  color: Style.primaryColor,
                                  fontSize: 30.0,
                                  fontFamily: Style.fontFamily,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                                (_user == null)
                                    ? ''
                                    : (_user.displayName != '' &&
                                            _user.displayName != null)
                                        ? _user.displayName
                                        : (_user.phoneNumber != null
                                            ? _user.phoneNumber
                                            : 'Your name'),
                                style: TextStyle(
                                    color: Style.foregroundColor,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: Style.fontFamily,
                                    fontSize: 15.0)),
                          ),
                          Text(
                              (_user == null)
                                  ? ''
                                  : _user.email == null
                                      ? 'Your email'
                                      : (_user.email != ''
                                          ? _user.email
                                          : 'Your email'),
                              style: TextStyle(
                                  color:
                                      Style.foregroundColor.withOpacity(0.54),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: Style.fontFamily,
                                  fontSize: 13.0)),
                          SizedBox(
                            height: 20.0,
                          ),
                          Divider(
                            height: 5,
                            thickness: 0.1,
                            color: Style.foregroundColor,
                          ),
                          ListTile(
                            minLeadingWidth: 30,
                            // Chuyển hướng đến trang tùy chọn tài khoản (gồm thay đổi mật khẩu, đăng xuất)
                            onTap: () {
                              Navigator.push(
                                  context,
                                  PageTransition(
                                      child: AccountDetail(
                                        user: _user,
                                      ),
                                      type: PageTransitionType.rightToLeft));
                            },
                            dense: true,
                            leading: SuperIcon(
                              iconPath:
                                  'assets/images/account_screen/user2.svg',
                              size: 25,
                            ),
                            title: Text('My Account',
                                style: TextStyle(
                                    color: Style.foregroundColor,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: Style.fontFamily)),
                            subtitle: Text('Your infomation',
                                style: TextStyle(
                                    color:
                                        Style.foregroundColor.withOpacity(0.54),
                                    fontWeight: FontWeight.w400,
                                    fontFamily: Style.fontFamily,
                                    fontSize: 13.0)),
                            trailing: Icon(Icons.chevron_right,
                                color: Style.foregroundColor.withOpacity(0.54)),
                          )
                        ],
                      )),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 35, 0, 0),
                    decoration: BoxDecoration(
                        color: Style.boxBackgroundColor,
                        border: Border(
                            top: BorderSide(
                              width: 0.1,
                              color: Style.foregroundColor.withOpacity(0.12),
                            ),
                            bottom: BorderSide(
                              width: 0.1,
                              color: Style.foregroundColor.withOpacity(0.12),
                            ))),
                    child: Column(
                      children: [
                        ListTile(
                          minLeadingWidth: 30,
                          // Chuyển đến thông tin các ví
                          onTap: () {
                            Navigator.push(
                                context,
                                PageTransition(
                                    child: MyWalletScreen(),
                                    type: PageTransitionType.rightToLeft));
                          },
                          dense: true,
                          leading: SuperIcon(
                            iconPath:
                                'assets/images/account_screen/wallet2.svg',
                            size: 25,
                          ),
                          title: Text('My Wallets',
                              style: TextStyle(
                                  color: Style.foregroundColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: Style.fontFamily,
                                  fontSize: 14.0)),
                          trailing: Icon(Icons.chevron_right,
                              color: Style.foregroundColor.withOpacity(0.54)),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(60, 0, 0, 0),
                          child: Divider(
                            height: 0,
                            thickness: 0.1,
                            color: Style.foregroundColor,
                          ),
                        ),
                        ListTile(
                          minLeadingWidth: 30,
                          //Chuyển đến thông tin các category
                          onTap: () {
                            Navigator.push(
                                context,
                                PageTransition(
                                    child: CategoriesScreen(),
                                    type: PageTransitionType.rightToLeft));
                          },
                          dense: true,
                          leading: SuperIcon(
                            iconPath:
                                'assets/images/account_screen/category.svg',
                            size: 25,
                          ),
                          title: Text('Categories',
                              style: TextStyle(
                                  color: Style.foregroundColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: Style.fontFamily,
                                  fontSize: 14.0)),
                          trailing: Icon(Icons.chevron_right,
                              color: Style.foregroundColor.withOpacity(0.54)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 35, 0, 0),
                    decoration: BoxDecoration(
                        color: Style.boxBackgroundColor,
                        border: Border(
                            top: BorderSide(
                              width: 0.1,
                              color: Style.foregroundColor.withOpacity(0.12),
                            ),
                            bottom: BorderSide(
                              width: 0.1,
                              color: Style.foregroundColor.withOpacity(0.12),
                            ))),
                    child: Column(
                      children: [
                        ListTile(
                          minLeadingWidth: 30,
                          // Vào git hub của team
                          onTap: () {
                            launchURL(exploreURL);
                          },
                          dense: true,
                          leading: SuperIcon(
                            iconPath:
                                'assets/images/account_screen/explore.svg',
                            size: 25,
                          ),
                          title: Text('Explore',
                              style: TextStyle(
                                  color: Style.foregroundColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: Style.fontFamily,
                                  fontSize: 14.0)),
                          trailing: Icon(Icons.chevron_right,
                              color: Style.foregroundColor.withOpacity(0.54)),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(60, 0, 0, 0),
                          child: Divider(
                            height: 0,
                            thickness: 0.1,
                            color: Style.foregroundColor,
                          ),
                        ),
                        ListTile(
                          minLeadingWidth: 30,
                          // Chuyển đến trang tùy chọn câu hỏi, hướng dẫn, gửi phản hồi
                          onTap: () {
                            Navigator.push(
                                context,
                                PageTransition(
                                    child: HelpScreens(),
                                    type: PageTransitionType.rightToLeft));
                          },
                          dense: true,
                          leading: SuperIcon(
                            iconPath: 'assets/images/account_screen/help.svg',
                            size: 25,
                          ),
                          title: Text('Help & Support',
                              style: TextStyle(
                                  color: Style.foregroundColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: Style.fontFamily,
                                  fontSize: 14.0)),
                          trailing: Icon(Icons.chevron_right,
                              color: Style.foregroundColor.withOpacity(0.54)),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(60, 0, 0, 0),
                          child: Divider(
                            height: 0,
                            thickness: 0.1,
                            color: Style.foregroundColor,
                          ),
                        ),
                        ListTile(
                          minLeadingWidth: 30,
                          // Chuyển đến cài đặt (gồm cài đặt theme)
                          onTap: () async {
                            int tempCurrentTheme = Style.currentTheme;
                            await Navigator.push(
                                context,
                                PageTransition(
                                    child: SettingScreen(),
                                    type: PageTransitionType.rightToLeft));
                            if (tempCurrentTheme != Style.currentTheme)
                              App.restartApp(context);
                          },
                          dense: true,
                          leading: SuperIcon(
                            iconPath:
                                'assets/images/account_screen/setting.svg',
                            size: 25,
                          ),
                          title: Text('Settings',
                              style: TextStyle(
                                  color: Style.foregroundColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: Style.fontFamily,
                                  fontSize: 14.0)),
                          trailing: Icon(Icons.chevron_right,
                              color: Style.foregroundColor.withOpacity(0.54)),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(60, 0, 0, 0),
                          child: Divider(
                            height: 0,
                            thickness: 0.1,
                            color: Style.foregroundColor,
                          ),
                        ),
                        ListTile(
                          minLeadingWidth: 30,
                          // Chuyển hướng đến thông tin về ứng dụng, thông tin các thành viên của team
                          onTap: () {
                            Navigator.push(
                                context,
                                PageTransition(
                                    child: AboutScreen(),
                                    type: PageTransitionType.rightToLeft));
                          },
                          dense: true,
                          leading: SuperIcon(
                            iconPath: 'assets/images/account_screen/about.svg',
                            size: 25,
                          ),
                          title: Text('About',
                              style: TextStyle(
                                  color: Style.foregroundColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: Style.fontFamily,
                                  fontSize: 14.0)),
                          trailing: Icon(Icons.chevron_right,
                              color: Style.foregroundColor.withOpacity(0.54)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 5.0,
                  )
                ],
              );
            }));
  }

// Này là hàm dùng cho chuyển hướng vào trang github của team
  void launchURL(String url) async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';
}
