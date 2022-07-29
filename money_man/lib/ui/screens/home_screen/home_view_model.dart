import 'package:money_man/base/base_view_model.dart';
import 'package:money_man/core/models/wallet_model.dart';

class HomeViewModel extends BaseController {
  Wallet wallet;

  getData() async {
    showLoading();
    wallet = await fireStore.currentWallet;
    hideLoading();
  }
}