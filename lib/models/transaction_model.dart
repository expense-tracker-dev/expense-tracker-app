
class TransactionModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String? accountId;
  final String? note;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    this.accountId,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'isIncome': isIncome,
      'date': date.toIso8601String(),
      'accountId': accountId,
      'note': note,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      isIncome: json['isIncome'] as bool,
      date: DateTime.parse(json['date'] as String),
      accountId: json['accountId'] as String?,
      note: json['note'] as String?,
    );
  }
}
