import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:money_man/core/services/firebase_authentication_services.dart';
import 'package:money_man/ui/screens/introduction_screens/first_step_first_wallet_screen.dart';
import 'package:money_man/ui/style.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

import '../../../locator.dart';

// màn hình này xuất hiện khi người dùng mới đăng ký bằng email và cần nhập thông tin tên người dùng
class AccountInformationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AccountInformation();
  }
}

class AccountInformation extends StatefulWidget {
  @override
  _AccountInformation createState() => _AccountInformation();
}

class _AccountInformation extends State<AccountInformation> {
  // Key kiểm soát nhập liệu
  final _formKey = GlobalKey<FormState>();
  String username;
  Widget inputTile(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(30, 15, 30, 30),
      //padding: EdgeInsets.fromLTRB(20,10,20,20),
      decoration: BoxDecoration(
          color: Style.boxBackgroundColor,
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.fromLTRB(30, 10, 40, 20),
            leading: Icon(
              Icons.person_rounded,
              color: Style.foregroundColor,
              size: 30,
            ),
            title: Theme(
              data: Theme.of(context).copyWith(
                primaryColor: Style.foregroundColor,
              ),
              // Text form field để nhập tên người dùng
              child: TextFormField(
                maxLength: 20,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter your name';
                  return null;
                },
                onChanged: (val) {
                  setState(() {
                    username = val;
                  });
                  print(username);
                },
                style: TextStyle(
                    color: Style.foregroundColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    fontFamily: Style.fontFamily),
                autocorrect: false,
                decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                      color: Style.foregroundColor.withOpacity(0.12),
                      width: 1.5,
                    )),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                      color: Style.foregroundColor.withOpacity(0.12),
                      width: 2.0,
                    )),
                    errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                      color: Style.errorColor,
                      width: 1.5,
                    )),
                    focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                      color: Style.errorColor,
                      width: 2.0,
                    )),
                    errorStyle: TextStyle(
                      fontFamily: Style.fontFamily,
                      fontWeight: FontWeight.w400,
                    ),
                    counterStyle: TextStyle(
                        fontFamily: Style.fontFamily,
                        color: Style.foregroundColor.withOpacity(0.54),
                        fontSize: 12),
                    labelText: 'Enter your name',
                    labelStyle: TextStyle(
                        color: Style.foregroundColor.withOpacity(0.24),
                        fontFamily: Style.fontFamily,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Biến để tham chiếu đến các hàm thực hiện thay đổi trên firebase
    final _auth = locator<FirebaseAuthService>();
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Style.backgroundColor1,
        leadingWidth: 60.0,
        leading: RotatedBox(
            quarterTurns: 2,
            child: IconButton(
              onPressed: () {
                final _auth = FirebaseAuthService();
                _auth.signOut();
              },
              icon: Icon(
                Icons.exit_to_app,
                color: Style.foregroundColor.withOpacity(0.24),
                size: 28.0,
              ),
            )),
      ),
      body: Container(
        height: double.infinity,
        padding: EdgeInsets.only(top: 30),
        color: Style.backgroundColor1,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Center(
                  child: Container(
                      margin: EdgeInsets.symmetric(vertical: 40),
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Style.foregroundColor),
                      child: Text(
                        username == null || username.length == 0
                            ? 'M'
                            : username[0].toUpperCase(),
                        style: TextStyle(
                            color: Style.primaryColor,
                            fontSize: 65,
                            fontFamily: Style.fontFamily,
                            fontWeight: FontWeight.w400),
                      ),
                      alignment: Alignment.center),
                ),
                Text('Tell me what your name is.',
                    style: TextStyle(
                      fontFamily: Style.fontFamily,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w300,
                      color: Style.foregroundColor,
                    )),
                // chèn phần in put vào nè
                inputTile(context),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 100.0),
                  height: 45.0,
                  width: double.infinity,
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed))
                            return Colors.white;
                          return Color(
                              0xFF2FB49C); // Use the component's default.
                        },
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed))
                            return Color(0xFF2FB49C);
                          return Colors.white; // Use the component's default.
                        },
                      ),
                    ),
                    // Sau khi đặt tên xong thì tới màn hình đặt ví đầu tiên thoy
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        _auth.currentUser.updateProfile(
                          displayName: username,
                        );
                        Navigator.pushReplacement(
                            context,
                            PageTransition(
                              child: FirstStepForFirstWallet(),
                              type: PageTransitionType.scale,
                              curve: Curves.elasticInOut,
                            ));
                      }
                    },
                    child: Text('CONFIRM',
                        style: TextStyle(
                            fontSize: 15,
                            fontFamily: Style.fontFamily,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            wordSpacing: 2.0),
                        textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
