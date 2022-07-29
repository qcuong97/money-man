import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:money_man/core/models/bill_model.dart';
import 'package:money_man/core/models/budget_model.dart';
import 'package:money_man/core/models/category_model.dart';
import 'package:money_man/core/models/event_model.dart';
import 'package:money_man/core/models/recurring_transaction_model.dart';
import 'package:money_man/core/models/repeat_option_model.dart';
import 'package:money_man/core/models/transaction_model.dart';
import 'package:money_man/core/models/wallet_model.dart';
import 'package:date_util/date_util.dart';

class FirebaseFireStoreService {
  final String uid;

  FirebaseFireStoreService({@required this.uid});

  // reference tới collection users
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');
  // reference tới collection categories
  final CollectionReference categories =
      FirebaseFirestore.instance.collection('categories');

  // WALLET START//

  // update id của wallet đang được chọn
  Future<String> updateSelectedWallet(String walletID) async {
    // lấy wallet thông qua id
    Wallet wallet;
    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletID)
        .get()
        .then((value) {
      print(walletID);
      wallet = Wallet.fromMap(value.data());
    }).catchError((error) => print(error));

    // update ví đang được chọn lên database
    await users
        .doc(uid)
        .update({'currentWallet': wallet.toMap()})
        .then((value) => print('updated!'))
        .catchError((onError) {
          print(onError);
          return onError.toString();
        });

    return wallet.id;
  }

  // add first wallet
  Future addFirstWallet(Wallet wallet) async {
    double amount = wallet.amount;
    wallet.amount = 0;
    // lấy doc reference để auto generate id của doc
    DocumentReference docRef = users.doc(uid).collection('wallets').doc();
    wallet.id = docRef.id;

    // thêm ví vào collection wallets và set wallet đang được chọn
    await docRef
        .set(wallet.toMap())
        .then((value) => print('add wallet to collection wallets'))
        .catchError((error) => print(error.toString()));

    await users
        .doc(uid)
        .set({'currentWallet': wallet.toMap()})
        .then((value) => print('set selected wallet'))
        .catchError((error) => print(error));

    // set category là "Other Income"
    MyCategory category;
    await categories.where('name', isEqualTo: 'Other Income').get().then(
        (value) => category = MyCategory.fromMap(value.docs.first.data()));

    // add  transaction
    MyTransaction trans = MyTransaction(
        id: 'id',
        amount: amount,
        date: DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day),
        currencyID: wallet.currencyID,
        category: category,
        note: 'Initial Balance');
    await addTransaction(wallet, trans);
  }

  // stream của wallet hiện tại đang được chọn
  Future<Wallet> get currentWallet async {
    var res = users.doc(uid).snapshots().map((event) {
      return Wallet.fromMap(event.get('currentWallet'));
    });
    if (res != null && (await res.isEmpty) == false) {
      return res.first;
    }
    return null;
  }

  // add wallet
  Future addWallet(Wallet wallet) async {
    DocumentReference walletRef = users.doc(uid).collection('wallets').doc();
    wallet.id = walletRef.id;
    MyCategory category;

    double amount = wallet.amount;
    wallet.amount = 0;

    await walletRef
        .set(wallet.toMap())
        .then((value) => print('wallet added!'))
        .catchError((error) {
      print(error);
      return error.toString();
    });

    // set catergory "Other Income"
    await categories.where('name', isEqualTo: 'Other Income').get().then(
        (value) => category = MyCategory.fromMap(value.docs.first.data()));

    MyTransaction trans = MyTransaction(
        id: 'id',
        amount: amount,
        date: DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day),
        currencyID: wallet.currencyID,
        category: category,
        note: 'Adjust Balance');
    await addTransaction(wallet, trans);

    return wallet.id;
  }

  // edit wallet
  Future updateWallet(Wallet wallet) async {
    await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .update(wallet.toMap())
        .then((value) => print('Edit success!'))
        .catchError((error) {
      print(error);
      return error.toString();
    });
  }

  // detele wallet
  Future deleteWallet(String walletID) async {
    var length = 0;
    CollectionReference wallets = users.doc(uid).collection('wallets');
    await wallets.get().then((value) {
      length = value.size;
    }).catchError((error) => print(error));
    // trường họp chỉ có 1 ví
    if (length == 1) return 'only 1 wallet';

    // trường hợp có nhiều hơn 1 ví
    // xóa ví
    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletID)
        .delete()
        .then((value) => print('deleted success!'))
        .catchError((error) {
      return error.toString();
    });

    // thiết lập lại ví đang được chọn
    Wallet firstWallet;
    await users.doc(uid).collection('wallets').get().then((value) async {
      firstWallet = Wallet.fromMap(value.docs.first.data());
      await updateSelectedWallet(firstWallet.id);
    });
    return firstWallet.id;
  }

  // convert from snapshot
  List<Wallet> _walletFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((e) => Wallet.fromMap(e.data())).toList();
  }

  // get stream wallet
  Stream<List<Wallet>> get walletStream {
    return users
        .doc(uid)
        .collection('wallets')
        .snapshots()
        .map(_walletFromSnapshot);
  }

  // get wallet by id
  Future<Wallet> getWalletByID(String id) async {
    return await users
        .doc(uid)
        .collection('wallets')
        .doc(id)
        .get()
        .then((value) => Wallet.fromMap(value.data()));
  }

  // adjust wallet's balance
  Future adjustBalance(Wallet wallet, double amount) async {
    double transactionAmount;
    MyCategory category;

    transactionAmount = amount - wallet.amount;
    if (transactionAmount > 0)
      await categories.where('name', isEqualTo: 'Other Income').get().then(
          (value) => category = MyCategory.fromMap(value.docs.first.data()));
    else {
      await categories.where('name', isEqualTo: 'Other Expense').get().then(
          (value) => category = MyCategory.fromMap(value.docs.first.data()));
      transactionAmount = -transactionAmount;
    }

    MyTransaction trans = MyTransaction(
        id: 'id',
        amount: transactionAmount,
        date: DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day),
        currencyID: wallet.currencyID,
        category: category,
        note: 'Adjust Balance');
    await addTransaction(wallet, trans);
  }

  // WALLET END//

  // TRANSACTION START//

  // get transaction by id
  Future getTransactionByID(String id, String walletId) async {
    MyTransaction transaction;

    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('transactions')
        .doc(id)
        .get()
        .then((value) => transaction = MyTransaction.fromMap(value.data()));

    return transaction;
  }

  // detele instance inside collection transactionIdList
  Future deleteInstanceInTransactionIdList(
      String transactionId, String walletId) async {
    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('transactionIdDebtLoan')
        .doc(transactionId)
        .delete();
  }

  // update debt loan transaction after add
  Future updateDebtLoanTransationAfterAdd(MyTransaction debtLoanTransaction,
      MyTransaction addedTransaction, Wallet wallet) async {
    // tính toán lại tiền extraAmountInfo
    debtLoanTransaction.extraAmountInfo -= addedTransaction.amount;
    await updateTransaction(debtLoanTransaction, wallet);

    // thêm vào list transactionIdDebtLoan
    await addTransactionIdIntoTransListOfDebtLoan(
        debtLoanTransaction.id, addedTransaction.id, wallet.id);
  }

  // update debt loan transaction after edit
  Future updateDebtLoanTransationAfterEdit(MyTransaction oldTransaction,
      MyTransaction editedTransaction, Wallet wallet) async {
    String debtLoanTransactionId;
    MyTransaction debtLoanTransaction;

    // Lây id transactionDebtLoan từ danh sách transactionIdDebtLoan
    await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('transactionIdDebtLoan')
        .where('transactionIdList', arrayContainsAny: [editedTransaction.id])
        .get()
        .then((value) => {
              if (value.docs.isNotEmpty)
                debtLoanTransactionId = value.docs.first.id
            });

    if (debtLoanTransactionId == null) return 1;

    // từ id đã lấy ở trên để lấy transaction từ collection transactions
    await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('transactions')
        .doc(debtLoanTransactionId)
        .get()
        .then((value) =>
            {debtLoanTransaction = MyTransaction.fromMap(value.data())});

    if (debtLoanTransaction == null) return 1;

    if (debtLoanTransaction.amount < editedTransaction.amount) return;

    // tính toán lại số tiền extraAmountInfo
    debtLoanTransaction.extraAmountInfo += oldTransaction.amount;
    debtLoanTransaction.extraAmountInfo -= editedTransaction.amount;
    await updateTransaction(debtLoanTransaction, wallet);

    return 1;
  }

  // update debt loan transaction after delete
  Future updateDebtLoanTransationAfterDelete(
      MyTransaction deletedTransaction, Wallet wallet) async {
    String debtLoanTransactionId;
    MyTransaction debtLoanTransaction;

    // từ id đã lấy ở trên để lấy transaction từ collection transactions
    await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('transactionIdDebtLoan')
        .where('transactionIdList', arrayContainsAny: [deletedTransaction.id])
        .get()
        .then((value) => {
              if (value.docs.isNotEmpty)
                debtLoanTransactionId = value.docs.first.id
            });

    if (debtLoanTransactionId == null) return;

    // Lây id transactionDebtLoan từ danh sách transactionIdDebtLoan
    await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('transactions')
        .doc(debtLoanTransactionId)
        .get()
        .then((value) =>
            {debtLoanTransaction = MyTransaction.fromMap(value.data())});

    if (debtLoanTransaction == null) return;

    // tính toán lại số tiền extraAmountInfo
    debtLoanTransaction.extraAmountInfo += deletedTransaction.amount;
    await updateTransaction(debtLoanTransaction, wallet);

    // xóa transaction khỏi transactionIdDebtLoan
    await deleteTransactionIdFromTransactionListOfDebtLoan(
        debtLoanTransaction.id, deletedTransaction.id, wallet.id);
  }

  // search transaction in debt & loan
  Future<List<MyTransaction>> searchTransactionInDebtLoan(
      String transactionId, String walletId) async {
    List<dynamic> transactionIdList = [];

    // lấy id từ list
    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('transactionIdDebtLoan')
        .doc(transactionId)
        .get()
        .then((value) => {
              if (value.exists)
                {transactionIdList = value.data().entries.first.value}
            });

    // từ các id lấy transaction
    List<MyTransaction> transactionList = [];
    if (transactionIdList.isNotEmpty) {
      for (int i = 0; i < transactionIdList.length; i++) {
        await users
            .doc(uid)
            .collection('wallets')
            .doc(walletId)
            .collection('transactions')
            .doc(transactionIdList[i])
            .get()
            .then((value) => {
                  if (value.exists)
                    transactionList.add(MyTransaction.fromMap(value.data())),
                });
      }
    }

    // return listTrans;
    return transactionList;
  }

  // delete transaction khỏi transactionIdDebtLoan
  Future deleteTransactionIdFromTransactionListOfDebtLoan(
      String transactionIdDebtLoan,
      String transactionId,
      String walletId) async {
    List<dynamic> transactionIdList = [];

    // lấy list transactionIdDebtLoan
    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('transactionIdDebtLoan')
        .doc(transactionIdDebtLoan)
        .get()
        .then((value) => {
              if (value.exists)
                {transactionIdList = value.data()['transactionIdList']}
            });

    // remove transaction khỏi list
    transactionIdList.remove(transactionId);

    // update lại list lên database
    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('transactionIdDebtLoan')
        .doc(transactionIdDebtLoan)
        .set({'transactionIdList': FieldValue.arrayUnion(transactionIdList)})
        .then((value) => print('remove transaction into id list sucess'))
        .catchError((error) => print(error));
  }

  // add transaction id into sepcial list for debt loan transaction
  Future addTransactionIdIntoTransListOfDebtLoan(String transactionIdDebtLoan,
      String transactionId, String walletId) async {
    List<dynamic> transactionIdList = [];

    // lấy list về
    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('transactionIdDebtLoan')
        .doc(transactionIdDebtLoan)
        .get()
        .then((value) => {
              if (value.exists)
                {transactionIdList = value.data()['transactionIdList']}
            });

    // thêm transaction vào list
    transactionIdList.add(transactionId);

    // update lại list lên database
    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('transactionIdDebtLoan')
        .doc(transactionIdDebtLoan)
        .set({'transactionIdList': FieldValue.arrayUnion(transactionIdList)})
        .then((value) => print('add transaction into id list sucess'))
        .catchError((error) => print(error));
  }

  // get list of transaction with criteria
  Future<List<MyTransaction>> getListOfTransactionWithCriteria(
      String criteria, String walletId) async {
    List<MyTransaction> list = [];
    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('transactions')
        .where('category.name', isEqualTo: criteria)
        .where('extraAmountInfo', isNotEqualTo: 0)
        .get()
        .then((value) {
      print('get complete with criteria: $criteria');
      value.docs.map((e) => list.add(MyTransaction.fromMap(e.data()))).toList();
    }).catchError((error) => print(error));
    return list;
  }

  // add transaction
  Future<MyTransaction> addTransaction(
      Wallet wallet, MyTransaction transaction) async {
    // lấy reference của list transaction để lấy auto-generate id
    final transactionRef = users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('transactions')
        .doc();

    // Update amount của wallet
    if (transaction.category.type == 'expense')
      wallet.amount -= transaction.amount;
    else if (transaction.category.type == 'income')
      wallet.amount += transaction.amount;
    else {
      if (transaction.category.name == 'Debt') {
        wallet.amount += transaction.amount;
        transaction.extraAmountInfo = transaction.amount;
      } else if (transaction.category.name == 'Loan') {
        wallet.amount -= transaction.amount;
        transaction.extraAmountInfo = transaction.amount;
      } else if (transaction.category.name == 'Repayment') {
        wallet.amount -= transaction.amount;
      } else {
        wallet.amount += transaction.amount;
      }
    }

    // gán id cho transaction
    transaction.id = transactionRef.id;

    // thực hiện add transaction
    await transactionRef
        .set(transaction.toMap())
        .then((value) => print('transaction added!'))
        .catchError((error) => print(error));

    // update searchList để sau này dùng cho việc search transaction
    List<String> searchList = splitNumber(transaction.amount.toInt());
    await transactionRef
        .update({'amountSearch': FieldValue.arrayUnion(searchList)}).catchError(
            (error) => print(error));

    // udpate wallet trong list và wallet đang được chọn
    await updateWallet(wallet);
    await updateSelectedWallet(wallet.id);

    return transaction;
  }

  // tách số amount để tạo thành searchList
  List<String> splitNumber(int number) {
    String strNum = number.toString();
    List<String> list = [];
    String total = '';
    for (int i = 0; i < strNum.length; i++) {
      String char = strNum[i];
      total += char;
      list.add(total);
    }
    return list;
  }

  // stream đến transaction của wallet đang được chọn
  Stream<List<MyTransaction>> transactionStream(Wallet wallet, dynamic limit) {
    if (limit == 'full') {
      return users
          .doc(uid)
          .collection('wallets')
          .doc(wallet.id)
          .collection('transactions')
          .snapshots()
          .map(_transactionFromSnapshot);
    } else {
      return users
          .doc(uid)
          .collection('wallets')
          .doc(wallet.id)
          .collection('transactions')
          .limit(limit)
          .orderBy('date', descending: true)
          .snapshots()
          .map(_transactionFromSnapshot);
    }
  }

  // convert từ snapshot thành transaction
  List<MyTransaction> _transactionFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((e) {
      return MyTransaction.fromMap(e.data());
    }).toList();
  }

  // delete transaction by id
  Future deleteTransaction(MyTransaction transaction, Wallet wallet) async {
    await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('transactions')
        .doc(transaction.id)
        .delete()
        .then((value) => print('transaction deleted!'))
        .catchError((error) {
      print(error);
    });

    // update transaction amount
    if (transaction.category.type == 'expense')
      wallet.amount += transaction.amount;
    else if (transaction.category.type == 'income')
      wallet.amount -= transaction.amount;
    else {
      if (transaction.category.name == 'Debt') {
        wallet.amount -= transaction.amount;
      } else if (transaction.category.name == 'Loan') {
        wallet.amount += transaction.amount;
      } else if (transaction.category.name == 'Repayment') {
        wallet.amount += transaction.amount;
      } else {
        wallet.amount -= transaction.amount;
      }
    }

    // update event khi add transaction
    if (transaction.eventID != "") {
      final event = await getEventByID(transaction.eventID, wallet);
      Event _event = event;
      if (_event != null) {
        if (transaction.category.type == 'expense')
          _event.spent += transaction.amount;
        else
          _event.spent -= transaction.amount;
        _event.transactionIdList
            .removeWhere((element) => element == transaction.id);
        await updateEvent(_event, wallet);
      }
    }

    // update lại wallet
    await updateWallet(wallet);
    await updateSelectedWallet(wallet.id);
  }

  // update transaction
  Future updateTransaction(MyTransaction transaction, Wallet wallet) async {
    // Lấy reference đến collection transactions
    CollectionReference transactionRef = users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('transactions');

    // Lấy transaction cũ
    MyTransaction oldTransaction;
    await transactionRef.doc(transaction.id).get().then((value) {
      oldTransaction = MyTransaction.fromMap(value.data());
    });

    // Tính toán để lấy lại amount cũ của ví
    if (oldTransaction.category.type == 'expense')
      wallet.amount += oldTransaction.amount;
    else if (oldTransaction.category.type == 'income')
      wallet.amount -= oldTransaction.amount;
    else {
      if (oldTransaction.category.name == 'Debt') {
        wallet.amount -= oldTransaction.amount;
      } else if (oldTransaction.category.name == 'Loan') {
        wallet.amount += oldTransaction.amount;
      } else if (oldTransaction.category.name == 'Repayment') {
        wallet.amount += oldTransaction.amount;
      } else {
        wallet.amount -= oldTransaction.amount;
      }
    }

    // Tính toán lấy amount mới của ví
    if (transaction.category.type == 'expense')
      wallet.amount -= transaction.amount;
    else if (transaction.category.type == 'income')
      wallet.amount += transaction.amount;
    else {
      if (transaction.category.name == 'Debt') {
        wallet.amount += transaction.amount;
        // transaction.note += ' from someone';
      } else if (transaction.category.name == 'Loan') {
        wallet.amount -= transaction.amount;
        // transaction.note += ' to someone';
      } else if (transaction.category.name == 'Repayment') {
        wallet.amount -= transaction.amount;
      } else {
        wallet.amount += transaction.amount;
      }
    }

    //lấy event cũ
    if (oldTransaction.eventID != "") {
      Event oldEvent;
      CollectionReference eventRef = users
          .doc(uid)
          .collection('wallets')
          .doc(wallet.id)
          .collection('events');

      await eventRef.doc(oldTransaction.eventID).get().then((value) {
        oldEvent = Event.fromMap(value.data());
      });

      //Tính toán lại spent cho event cũ
      if (oldTransaction.category.type == 'expense')
        oldEvent.spent += oldTransaction.amount;
      else
        oldEvent.spent -= oldTransaction.amount;

      //Loại bỏ transaction khỏi event cũ
      oldEvent.transactionIdList
          .removeWhere((element) => element == oldTransaction.id);

      //update cho event cũ
      await updateEvent(oldEvent, wallet);

      //update cho event mới
      if (transaction.eventID == oldEvent.id)
        await updateEventAmountAndTransList(oldEvent, wallet, transaction);
      else if (transaction.eventID != "") {
        Event event = await getEventByID(transaction.eventID, wallet);
        await updateEventAmountAndTransList(event, wallet, transaction);
      }
    } else if (transaction.eventID != "" && oldTransaction.eventID == "") {
      Event event = await getEventByID(transaction.eventID, wallet);
      await updateEventAmountAndTransList(event, wallet, transaction);
    }

    // update transaction
    await transactionRef.doc(transaction.id).update(transaction.toMap());

    // update searchList để sau này dùng cho việc search transaction
    List<String> searchList = splitNumber(transaction.amount.toInt());
    await transactionRef
        .doc(transaction.id)
        .update({'amountSearch': FieldValue.arrayUnion(searchList)});

    // update ví trong list và ví đang được chọn
    await updateWallet(wallet);
    await updateSelectedWallet(wallet.id);
  }

  // update transaction sau khi delete event
  Future updateTransactionAfterDeletingEvent(
      MyTransaction transaction, Wallet wallet) async {
    CollectionReference transactionRef = users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('transactions');
    transaction.eventID = "";
    // Lấy transaction cũ
    await transactionRef.doc(transaction.id).update(transaction.toMap());
  }

  // Query transaction by category
  Future<List<MyTransaction>> queryTransactionByCategoryOrAmount(
      String searchPattern, Wallet wallet) async {
    double number = double.tryParse(searchPattern);
    List<MyTransaction> listTrans = [];

    // trường hợp search bằng số
    if (number != null) {
      int intNum = number.toInt();
      await users
          .doc(uid)
          .collection('wallets')
          .doc(wallet.id)
          .collection('transactions')
          .where('amountSearch', arrayContainsAny: [intNum.toString()])
          .get()
          .then((value) {
            if (value.docs.isNotEmpty) {
              value.docs.forEach((element) {
                MyTransaction trans = MyTransaction.fromMap(element.data());
                if (!listTrans.contains(trans)) listTrans.add(trans);
              });
            }
          });
    } else {
      // trường hợp tìm theo category
      searchPattern = searchPattern.toLowerCase();
      List<List<String>> cateName = [[]];
      int index = 0;

      // dựa trên searchPattern để tìm kiếm category thích hợp trong collection categories
      await categories
          .where('searchIndex', arrayContainsAny: [searchPattern])
          .get()
          .then((value) => value.docs.map((e) {
                MyCategory a = MyCategory.fromMap(e.data());
                // print(a.name);
                if (cateName[index].length == 10) {
                  cateName.add([]);
                  index++;
                }
                cateName[index].add(a.name);
              }).toList());

      // Dựa trên list categories ở trên để tìm kiếm các transaction thỏa điều kiện

      for (int i = 0; i < cateName.length; i++) {
        for (int j = 0; j < cateName[i].length; j++)
          await users
              .doc(uid)
              .collection('wallets')
              .doc(wallet.id)
              .collection('transactions')
              .where('category.name', isEqualTo: cateName[i][j])
              .get()
              .then((value) {
            if (value.docs.isNotEmpty) {
              value.docs.forEach((element) {
                MyTransaction trans = MyTransaction.fromMap(element.data());
                if (!listTrans.contains(trans)) listTrans.add(trans);
              });
            }
          });
      }
    }
    return listTrans;
  }

  // TRANSACTION END//

  // CATERGORY START//

  // get stream list category
  Stream<List<MyCategory>> get categoryStream {
    return categories.snapshots().map(_categoryFromSnapshot);
  }

  // convert từ snapshot thành category
  List<MyCategory> _categoryFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((e) {
      return MyCategory.fromMap(e.data());
    }).toList();
  }

  // add instance cate
  void addCate() async {
    final cateRef = categories.doc();
    MyCategory cat = MyCategory(
        id: cateRef.id, name: '', type: 'expense', iconID: 'defaultID');
    await cateRef
        .set(cat.toMap())
        .then((value) => print('added!'))
        .catchError((error) => print(error));
  }

  // Lấy category bằng id
  Future<MyCategory> getCategoryByID(String id) async {
    return categories
        .doc(id)
        .get()
        .then((value) => MyCategory.fromMap(value.data()));
  }

  // CATERGORY END //

  // USER START //
  Stream<String> get userName {
    return users.doc(uid).snapshots().map(_userNameFromSnapshot);
  }

  // set theme của user
  Future setTheme(int theme) async {
    await users
        .doc(uid)
        .update({'theme': theme})
        .then((value) => print('update theme to $theme'))
        .catchError((error) => print(error));
  }

  Future getTheme() async {
    int theme = 0;
    await users.doc(uid).get().then((value) => {theme = value.get('theme')});
    return theme;
  }

  String _userNameFromSnapshot(DocumentSnapshot snapshot) {
    return snapshot.get(FieldPath(['userName'])).toString();
  }
  // USER END //

  // BUDGET START //

  // lấy list các transaction dành cho budget
  Future<List<MyTransaction>> getListOfTransactionWithCriteriaForBudget(
      String criteria, String walletId) async {
    List<MyTransaction> list = [];
    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('transactions')
        .where('category.name', isEqualTo: criteria)
        .get()
        .then((value) {
      value.docs.map((e) => list.add(MyTransaction.fromMap(e.data()))).toList();
    }).catchError((error) => print(error));
    return list;
  }

  // add budget
  Future addBudget(Budget budget, Wallet wallet) async {
    // lấy reference đến collection budgets
    final budgetsRef = users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('budgets')
        .doc();

    // lấy auto id gán cho budget
    budget.id = budgetsRef.id;

    // tính toán spent và gán spent cho budget
    budget.spent = await calculateBudgetSpent(budget);

    // thực hiện add budget
    await budgetsRef
        .set(budget.toMap())
        .then((value) => print('budget added!'))
        .catchError((error) => print(error));
  }

  Future<double> calculateBudgetSpent(Budget budget) async {
    // khai báo biến spent (số tiền của các transaction thỏa yêu cầu của budget)
    double spent = 0;
    List<MyTransaction> listTrans = [];

    // dựa trên category để lấy các transaction thỏa yêu cầu => tính toán spent
    await users
        .doc(uid)
        .collection('wallets')
        .doc(budget.walletId)
        .collection('transactions')
        .where('category.id', isEqualTo: budget.category.id)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        value.docs.forEach((element) {
          MyTransaction trans = MyTransaction.fromMap(element.data());
          if (!listTrans.contains(trans)) listTrans.add(trans);
        });
        for (int i = 0; i < listTrans.length; i++)
          if (listTrans[i]
                      .date
                      .compareTo(budget.endDate.add(Duration(days: 1))) <
                  0 &&
              listTrans[i].date.compareTo(budget.beginDate) >= 0)
            spent += listTrans[i].amount;
      }
    });
    return spent;
  }

  // tính toán spent của budget
  Future<double> calculateBudgetSpentFromDay(
      Budget budget, DateTime dateTime) async {
    double spent = 0;
    List<MyTransaction> listTrans = [];

    // dựa trên category để lấy các transaction thỏa yêu cầu => tính toán spent
    await users
        .doc(uid)
        .collection('wallets')
        .doc(budget.walletId)
        .collection('transactions')
        .where('category.id', isEqualTo: budget.category.id)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        value.docs.forEach((element) {
          MyTransaction trans = MyTransaction.fromMap(element.data());
          if (!listTrans.contains(trans)) listTrans.add(trans);
        });
        for (int i = 0; i < listTrans.length; i++)
          //listTrans[i].date.isBefore(dateTime.add(Duration(days: 1))) &&
          //budget.beginDate.isBefore(listTrans[i].date)
          if (listTrans[i].date.compareTo(dateTime.add(Duration(days: 1))) <
                  0 &&
              listTrans[i].date.compareTo(budget.beginDate) >= 0)
            spent += listTrans[i].amount;
      }
    });
    return spent;
  }

  // Stream budget dùng để hiển thị list các budget đã có dựa trên wallet id
  // tìm chỗ thích hợp để đặt 1 streambuilder<List<Budget>> để lấy dữ liệu
  // khuyến khích đặt ở screen gốc (budget_home) để có sẵn dữ liệu rồi truyền vào các screen child sẽ dễ hơn
  Stream<List<Budget>> budgetStream(String walletId) {
    return users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('budgets')
        .snapshots()
        .map(_budgetFromSnapshot);
  }

//Stream budget dùng để hiển thị list các budget có cùng category với transaction
  Stream<List<Budget>> budgetTransactionStream(
      MyTransaction transaction, String walletID) {
    return users
        .doc(uid)
        .collection('wallets')
        .doc(walletID)
        .collection('budgets')
        .where('category.id', isEqualTo: transaction.category.id)
        .snapshots()
        .map(_budgetFromSnapshot);
  }

  // convert budget from snapshot (hàm này convert từ dữ liệu firebase thành budget)
  List<Budget> _budgetFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((e) {
      print(e.data());
      return Budget.fromMap(e.data());
    }).toList();
  }

  // edit budget
  Future updateBudget(Budget budget, Wallet wallet) async {
    // user thay đổi thông tin budget thì có thể thay đổi category
    // nên spent sẽ có thể bị tính lại từ đầu => tính toán spent
    // gán spent cho budget
    budget.spent = await calculateBudgetSpent(budget);

    // thực hiện update budget
    await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('budgets')
        .doc(budget.id)
        .update(budget.toMap())
        .then((value) => print('budget updated!'))
        .catchError((error) => print(error));
  }

  // delete budget
  Future deleteBudget(String walletId, String budgetId) async {
    // thực hiện delete budget thôi
    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('budgets')
        .doc(budgetId)
        .delete()
        .then((value) => print('budget deleted!'))
        .catchError((error) => print(error));
  }

  // BUDGET END //

  // BILL START //

  // add bill
  Future addBill(Bill bill, Wallet wallet) async {
    final billsRef = users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('bills')
        .doc();
    bill.id = billsRef.id;
    await billsRef
        .set(bill.toMap())
        .then((value) => print('bill added!'))
        .catchError((error) => print('error'));
  }

  // edit bill
  Future updateBill(Bill bill, Wallet wallet) async {
    await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('bills')
        .doc(bill.id)
        .update(bill.toMap())
        .then((value) => print('bill updated!'))
        .catchError((error) => print(error));
  }

  // delete bill
  Future deleteBill(Bill bill, Wallet wallet) async {
    await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('bills')
        .doc(bill.id)
        .delete();
  }

  // Stream list bill
  Stream<List<Bill>> billStream(String walletId) {
    return users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('bills')
        .snapshots()
        .map(_billFromSnapshot);
  }

  // convert bill from snapshot (hàm này convert từ dữ liệu firebase thành budget)
  List<Bill> _billFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((e) {
      print(e.data());
      return Bill.fromMap(e.data());
    }).toList();
  }

  // BILL END //

  // RECURRING TRANSACTION START //

  // add recurring transaction
  Future addRecurringTransaction(
      RecurringTransaction reTrans, Wallet wallet) async {
    final reTranssRef = users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('recurring transactions')
        .doc();
    reTrans.id = reTranssRef.id;
    await reTranssRef
        .set(reTrans.toMap())
        .then((value) => print('recurring transaction added!'))
        .catchError((error) => print('error'));
  }

  // edit recurring transaction
  Future updateRecurringTransaction(
      RecurringTransaction reTrans, Wallet wallet) async {
    await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('recurring transactions')
        .doc(reTrans.id)
        .update(reTrans.toMap())
        .then((value) => print('recurring transaction updated!'))
        .catchError((error) => print(error));
  }

  // delete recurring transaction
  Future deleteRecurringTransaction(
      RecurringTransaction reTrans, Wallet wallet) async {
    await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('recurring transactions')
        .doc(reTrans.id)
        .delete();
  }

  // stream list recurring transaction
  Stream<List<RecurringTransaction>> recurringTransactionStream(
      String walletId) {
    return users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('recurring transactions')
        .snapshots()
        .map(_recurringTransactionFromSnapshot);
  }

  // convert budget from snapshot (hàm này convert từ dữ liệu firebase thành budget)
  List<RecurringTransaction> _recurringTransactionFromSnapshot(
      QuerySnapshot snapshot) {
    return snapshot.docs.map((e) {
      print(e.data());
      return RecurringTransaction.fromMap(e.data());
    }).toList();
  }

  // lấy danh sách các transaction cần thực hiện trong hôm nay (của recurring transaction)
  Future getListRecurringTransactionToBeExecute(String walletId) async {
    DateTime now =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    List<RecurringTransaction> todayRecurringTransList = await users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('recurring transactions')
        .where('repeatOption.beginDateTime', isLessThanOrEqualTo: now)
        .where('isFinished', isEqualTo: false)
        .get()
        .then((value) => List<RecurringTransaction>.from(value.docs
            .map((e) => RecurringTransaction.fromMap(e.data()))
            .toList()));
    return todayRecurringTransList;
  }

  // thực hiện add transaction của recurring transaction
  Future executeRecurringTransaction(Wallet wallet) async {
    // lấy danh sách cần thực hiện hôm nay
    List<RecurringTransaction> todayList =
        await getListRecurringTransactionToBeExecute(wallet.id);

    // nếu không có thì return
    if (todayList.isEmpty) return -1;

    // todayList = checkValidRecurringList(todayList);

    // thực hiện add transaction dựa trên list đã lấy ở trên và trả về danh sách id
    List<String> transactionIdList =
        await addTransactionOfRecurringTransaction(todayList, wallet);

    // nếu danh sách id có
    if (transactionIdList.isNotEmpty) {
      // thực hiện update begin date của recurring transaction
      await updateNewBeginDateOfRecurringTransaction(
          todayList, transactionIdList, wallet);
      return 1;
    } else
      return -1;
  }

  // update begin date của recurring transaction
  Future updateNewBeginDateOfRecurringTransaction(
      List<RecurringTransaction> todayList,
      List<String> transactionIdList,
      Wallet wallet) async {
    // index cho transaction id list
    int index = 0;

    // map today list để xử lý
    todayList.map((RecurringTransaction recurringTrans) async {
      // tính toán next date
      // trường hợp for thì lấy extra type info -1

      recurringTrans.repeatOption.beginDateTime =
          _calculateNextDate(recurringTrans);

      if (recurringTrans.repeatOption.type == 'for') {
        recurringTrans.repeatOption.extraTypeInfo =
            (int.parse(recurringTrans.repeatOption.extraTypeInfo.toString()) -
                    1)
                .toString();
        if (int.parse(recurringTrans.repeatOption.extraTypeInfo) <= 0) {
          recurringTrans.isFinished = true;
        }
      } else if (recurringTrans.repeatOption.type == 'until') {
        if (recurringTrans.repeatOption.beginDateTime
            .isAfter(recurringTrans.repeatOption.extraTypeInfo)) {
          recurringTrans.isFinished = true;
        }
      }

      // lấy transaction id list add vào recurring transaction
      recurringTrans.transactionIdList.add(transactionIdList[index]);
      index = index + 1;

      // update lại recurring transaction
      await updateRecurringTransaction(recurringTrans, wallet);
    }).toList();
  }

  // thực hiện việc add transaction của recurring transaction
  Future<List<String>> addTransactionOfRecurringTransaction(
      List<RecurringTransaction> todayList, Wallet wallet) async {
    List<String> transactionIdList = [];

    // thực hiện add transaction rồi lưu id lại vào transactionIdList
    for (int i = 0; i < todayList.length; i++) {
      RecurringTransaction recurringTrans = todayList[i];
      MyTransaction transaction = MyTransaction(
          id: 'id',
          amount: recurringTrans.amount,
          note: recurringTrans.note,
          date: recurringTrans.repeatOption.beginDateTime,
          currencyID: wallet.currencyID,
          category: recurringTrans.category);
      transaction = await addTransaction(wallet, transaction);
      transactionIdList.add(transaction.id);
    }
    return transactionIdList;
  }

  // tính toán next date cho recurring transaction
  DateTime _calculateNextDate(RecurringTransaction recurringTrans) {
    DateUtil dateUtility = DateUtil();
    RepeatOption repeatOption = recurringTrans.repeatOption;
    DateTime nextDate;

    // trường hợp daily
    if (repeatOption.frequency == 'daily') {
      nextDate = repeatOption.beginDateTime
          .add(Duration(days: repeatOption.rangeAmount));
    }
    // trường hợp weekly
    else if (repeatOption.frequency == 'weekly') {
      nextDate = repeatOption.beginDateTime
          .add(Duration(days: 7 * repeatOption.rangeAmount));
    }
    // trường hợp monthly
    else if (repeatOption.frequency == 'monthly') {
      DateTime beginDate = repeatOption.beginDateTime;
      int days = dateUtility.daysInMonth(beginDate.month, beginDate.year) *
          repeatOption.rangeAmount;
      nextDate = beginDate.add(Duration(days: days));
    }
    // trường hợp yearly
    else {
      DateTime beginDate = repeatOption.beginDateTime;
      int days = (dateUtility.leapYear(beginDate.year) == true ? 365 : 366) *
          repeatOption.rangeAmount;
      nextDate = beginDate.add(Duration(days: days));
    }
    return nextDate;
  }

  // thực hiện add transaction của recurring transaction ngay lập tức (tương tự trên)
  Future executeInstantRecurringTransaction(
      RecurringTransaction recurringTransaction, Wallet wallet) async {
    if (recurringTransaction.isFinished == true) return -1;
    List<String> transactionIdList = await addTransactionOfRecurringTransaction(
        [recurringTransaction], wallet);

    if (transactionIdList.isNotEmpty) {
      await updateNewBeginDateOfRecurringTransaction(
          [recurringTransaction], transactionIdList, wallet);
      return 1;
    } else {
      return -1;
    }
  }

  // RECURRING TRANSACTION END //

  // EVENT START //

  // add event
  Future addEvent(Event event, Wallet wallet) async {
    // lấy reference tới collection events
    final eventsRef = users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('events')
        .doc();

    // gán id cho event
    event.id = eventsRef.id;

    // thực hiện add event
    await eventsRef
        .set(event.toMap())
        .then((value) => print('event added!'))
        .catchError((error) => print(error));
  }

  // edit event
  Future updateEvent(Event event, Wallet wallet) async {
    // thực hiện upudate event
    await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('events')
        .doc(event.id)
        .update(event.toMap())
        .then((value) => print('event updated!'))
        .catchError((error) => print(error));
  }

  // update event amount and transaction id list (dùng sau khi add, edit transaction mà có liên quan event)
  Future updateEventAmountAndTransList(
      Event event, Wallet wallet, MyTransaction transaction) async {
    // dựa trên type của category để xử lý spent
    // trường hợp type = incone
    if (transaction.category.type == 'income')
      event.spent += transaction.amount;
    // trường hợp type = expense
    else if (transaction.category.type == 'expense')
      event.spent -= transaction.amount;
    // trường hợp type = deft & loan

    // add id của transaction vào list (sau này muốn display thì thông qua 1 hàm get)
    event.transactionIdList.add(transaction.id);

    // update lại event với thông tin mới
    await updateEvent(event, wallet);
  }

  // delete event
  Future deleteEvent(String eventId, String walletId) async {
    await users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('events')
        .doc(eventId)
        .delete();
  }

  // Stream list event để display các event đang có của wallet
  Stream<List<Event>> eventStream(String walletId) {
    return users
        .doc(uid)
        .collection('wallets')
        .doc(walletId)
        .collection('events')
        .snapshots()
        .map(_eventFromSnapshot);
  }

  // convert event from snapshot (hàm này convert từ dữ liệu firebase thành event)
  List<Event> _eventFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((e) {
      print(e.data());
      return Event.fromMap(e.data());
    }).toList();
  }

  Future<Event> getEventByID(String id, Wallet wallet) async {
    return await users
        .doc(uid)
        .collection('wallets')
        .doc(wallet.id)
        .collection('events')
        .doc(id)
        .get()
        .then((value) => Event.fromMap(value.data()));
  }

  // EVENT END //
}
