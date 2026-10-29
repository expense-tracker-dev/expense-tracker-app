import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_model.dart';

class TransactionService {
  static String get _storageKey {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return 'dailydhan_transactions_guest';
    }

    return 'dailydhan_transactions_$userId';
  }

  static final ValueNotifier<int> transactionUpdates =
  ValueNotifier<int>(0);

  Future<List<TransactionModel>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);

    if (stored == null) return [];

    final List<dynamic> decoded =
    jsonDecode(stored) as List<dynamic>;

    return decoded
        .map(
          (item) => TransactionModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final transactions = await getTransactions();
    transactions.insert(0, transaction);

    await _saveTransactions(transactions);
    transactionUpdates.value++;
  }

  Future<void> deleteTransaction(String id) async {
    final transactions = await getTransactions();
    transactions.removeWhere((transaction) => transaction.id == id);

    await _saveTransactions(transactions);
    transactionUpdates.value++;
  }

  Future<void> _saveTransactions(
      List<TransactionModel> transactions,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      transactions.map((transaction) => transaction.toJson()).toList(),
    );

    await prefs.setString(_storageKey, encoded);
  }
}