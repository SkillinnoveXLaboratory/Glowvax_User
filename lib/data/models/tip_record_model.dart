class TipRecordModel {
  final String id;
  final String transactionId;
  final double amount;
  final DateTime createdAt;
  final String description;
  final String type;

  const TipRecordModel({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.createdAt,
    required this.description,
    required this.type,
  });
}
