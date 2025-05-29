import 'package:flutter/cupertino.dart';
import 'package:haflaway/services/balance_service.dart';
import 'package:haflaway/services/plan_service.dart';

class BalanceProvider extends ChangeNotifier {
  final BalanceService _balanceService;

  BalanceProvider(this._balanceService, this._eventPlanService);
  /* balance */
  JpUser? _balance;
  String? _userId;
  List<BalanceTransaction> _transactions = [];
  Stream<JpUser>? _balanceStream;
  Stream<List<BalanceTransaction>>? _transactionsStream;

  JpUser? get balance => _balance;
  String? get userId => _userId;
  List<BalanceTransaction> get transactions => _transactions;

  startWatchingBalance(String userId) {
    _userId = userId;

    _balanceStream = _balanceService.watchBalance(userId);
    _balanceStream?.listen((balance) {
      _balance = balance;
      notifyListeners();
    });
  }

  startWatchingTransactions(String userId) {
    _transactionsStream = _balanceService.watchTransactions(userId);
    _transactionsStream?.listen((transactions) {
      _transactions = transactions;
      notifyListeners();
    });
  }
  /* balance */

  final EventPlanService _eventPlanService;
  EventPlan? _eventPlan;
  String? _eventPlanId;
  Stream<EventPlan>? _eventPlanStream;
  EventPlan? get eventPlan => _eventPlan;

  startWatchingEventPlan({planId}) {
    _eventPlanId = planId;
    _eventPlanStream = _eventPlanService.watchEventPlan(
      eventPlanId: _eventPlanId,
    );
    _eventPlanStream?.listen((eventPlan) {
      _eventPlan = eventPlan;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _eventPlanStream = null;
    _transactionsStream = null;
    _balanceStream = null;
    super.dispose();
  }
}
