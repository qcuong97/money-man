import 'package:flutter/foundation.dart';
import 'package:money_man/core/services/firebase_firestore_services.dart';

import '../locator.dart';
import '../others/context_utils.dart';


class BaseController extends ChangeNotifier {
  final fireStore = locator<FirebaseFireStoreService>();
  bool isLoading = false;

  showLoading() {
    ContextUtils.ins.showLoading();
    isLoading = true;
  }

  hideLoading() {
    ContextUtils.ins.hideLoading();
    isLoading = false;
    onRefresh();
  }

  onRefresh() {
    notifyListeners();
  }
}
