import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station_model.dart';

final stationsProvider = StreamProvider<List<StationModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('stations')
      .snapshots()
      .map((snap) => snap.docs
        .map((d) => StationModel.fromMap(d.id, d.data()))
        .toList());
});