import 'package:get_it/get_it.dart';
import 'package:money_man/core/services/firebase_authentication_services.dart';
import 'package:money_man/core/services/firebase_firestore_services.dart';

import 'others/navigation_service.dart';

GetIt locator = GetIt.instance;

setUpLocator() {
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => FirebaseAuthService());
  locator.registerLazySingleton(() => FirebaseFireStoreService(
      uid: locator<FirebaseAuthService>().currentUser.uid));
}
