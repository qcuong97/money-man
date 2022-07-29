import 'package:flutter/material.dart';
import 'package:money_man/ui/screens/shared_screens/loading_screen.dart';

import '../locator.dart';
import 'navigation_service.dart';

class ContextUtils {
  static final ContextUtils _instance = ContextUtils._internal();

  static ContextUtils get ins => _instance;

  ContextUtils._internal();

  bool _isLoading = false;

  BuildContext get context =>
      locator.get<NavigationService>().navigatorKey.currentContext;

  ThemeData get theme =>
      Theme.of(locator.get<NavigationService>().navigatorKey.currentContext);

  static hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      try {
        currentFocus.focusedChild.unfocus();
      } catch (_) {}
    }
  }

  showLoading() {
    var context = locator.get<NavigationService>().navigatorKey.currentContext;
    if (context != null) {
      _isLoading = true;
      showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          builder: (context) => WillPopScope(
                onWillPop: () async => false,
                child: LoadingScreen(),
              ));
      Future.delayed(const Duration(seconds: 60), () {
        if (_isLoading) {
          hideLoading();
        }
      });
    }
  }

  hideLoading() {
    if (_isLoading) {
      _isLoading = false;
      locator.get<NavigationService>().pop();
    }
  }
}
