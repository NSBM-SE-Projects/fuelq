import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/station_model.dart';

final stationsProvider = StreamProvider<List<StationModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('stations')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => StationModel.fromMap(d.id, d.data()))
          .toList());
});
