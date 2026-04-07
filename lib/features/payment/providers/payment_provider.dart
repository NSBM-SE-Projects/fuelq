import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/card_model.dart';

final savedCardsProvider = StreamProvider<List<CardModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .collection('cards')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => CardModel.fromMap(doc.id, doc.data()))
          .toList());
});

class PaymentService {
  final FirebaseFirestore _firestore;

  PaymentService(this._firestore);

  Future<CardModel> saveCard({
    required String userId,
    required String cardNumber,
    required String cardholderName,
    required int expiryMonth,
    required int expiryYear,
    required bool setAsDefault,
  }) async {
    final last4 = cardNumber.replaceAll(' ', '').substring(cardNumber.replaceAll(' ', '').length - 4);
    final cardsRef = _firestore.collection('users').doc(userId).collection('cards');

    // If setting as default, unset existing defaults
    if (setAsDefault) {
      final existing = await cardsRef.where('isDefault', isEqualTo: true).get();
      for (final doc in existing.docs) {
        await doc.reference.update({'isDefault': false});
      }
    }

    // Check if no cards exist yet — make first card default
    final allCards = await cardsRef.get();
    final shouldDefault = setAsDefault || allCards.docs.isEmpty;

    final docRef = cardsRef.doc();
    final card = CardModel(
      id: docRef.id,
      last4: last4,
      bank: _detectBank(cardNumber),
      cardholderName: cardholderName,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: shouldDefault,
      createdAt: DateTime.now(),
    );

    await docRef.set(card.toMap());
    return card;
  }

  Future<void> deleteCard({
    required String userId,
    required String cardId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('cards')
        .doc(cardId)
        .delete();
  }

  Future<void> setDefaultCard({
    required String userId,
    required String cardId,
  }) async {
    final cardsRef = _firestore.collection('users').doc(userId).collection('cards');

    final existing = await cardsRef.where('isDefault', isEqualTo: true).get();
    for (final doc in existing.docs) {
      await doc.reference.update({'isDefault': false});
    }

    await cardsRef.doc(cardId).update({'isDefault': true});
  }

  // Simulated payment — returns true if "successful"
  Future<bool> processPayment({
    required double amount,
    required String cardId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  String _detectBank(String number) {
    final cleaned = number.replaceAll(' ', '');
    if (cleaned.startsWith('4')) return 'Visa';
    if (cleaned.startsWith('5')) return 'Mastercard';
    if (cleaned.startsWith('3')) return 'Amex';
    return 'Card';
  }
}

final paymentServiceProvider = Provider((ref) {
  return PaymentService(ref.watch(firestoreProvider));
});
