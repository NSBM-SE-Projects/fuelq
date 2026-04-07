import 'package:cloud_firestore/cloud_firestore.dart';

class CardModel {
  final String id;
  final String last4;
  final String bank;
  final String cardholderName;
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;
  final DateTime createdAt;

  const CardModel({
    required this.id,
    required this.last4,
    required this.bank,
    required this.cardholderName,
    required this.expiryMonth,
    required this.expiryYear,
    this.isDefault = false,
    required this.createdAt,
  });

  String get expiryDisplay =>
      '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().substring(2)}';

  String get maskedNumber => '•••• •••• •••• $last4';

  factory CardModel.fromMap(String id, Map<String, dynamic> map) => CardModel(
    id: id,
    last4: map['last4'] as String? ?? '',
    bank: map['bank'] as String? ?? '',
    cardholderName: map['cardholderName'] as String? ?? '',
    expiryMonth: (map['expiryMonth'] as num?)?.toInt() ?? 1,
    expiryYear: (map['expiryYear'] as num?)?.toInt() ?? 2026,
    isDefault: map['isDefault'] as bool? ?? false,
    createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'last4': last4,
    'bank': bank,
    'cardholderName': cardholderName,
    'expiryMonth': expiryMonth,
    'expiryYear': expiryYear,
    'isDefault': isDefault,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
