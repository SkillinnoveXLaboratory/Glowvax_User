enum TransactionType { credit, debit }

class WalletTransactionModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.createdAt,
  });
}
