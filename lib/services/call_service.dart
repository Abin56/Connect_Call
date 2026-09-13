import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/call_model.dart';

/// Firestore reads and writes for call history records. Figuring out "who
/// is calling whom right now" is handled by ZEGOCLOUD's own call-invitation
/// system (see CallingService) -- this service just saves the history
/// that comes out of that.
class CallService {
  final FirebaseFirestore _firestore;

  CallService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _calls =>
      _firestore.collection(AppConstants.callsCollection);

  Future<String> createCall(CallModel call) async {
    final doc = await _calls.add(call.toMap());
    return doc.id;
  }

  Future<void> updateCallStatus(
    String callId, {
    required CallStatus status,
    DateTime? endedAt,
    int? durationInSeconds,
  }) {
    final updates = <String, dynamic>{'status': status.name};
    if (endedAt != null) updates['endedAt'] = Timestamp.fromDate(endedAt);
    if (durationInSeconds != null) {
      updates['durationInSeconds'] = durationInSeconds;
    }
    return _calls.doc(callId).update(updates);
  }

  /// A backup "call ended" write for when the caller's own write might not
  /// happen, say if the caller's device lost the call first. Finds the doc
  /// by [zegoCallId] and only writes if it's still `connected`, so a late
  /// write never overwrites a status that's already final.
  Future<void> endConnectedCall(
    String zegoCallId, {
    required DateTime endedAt,
    required int durationInSeconds,
  }) {
    return _resolveConnectedCall(
      zegoCallId,
      status: CallStatus.ended,
      endedAt: endedAt,
      durationInSeconds: durationInSeconds,
    );
  }

  /// Same backup path as [endConnectedCall], but for a mid-call network
  /// drop reported by the receiver's device rather than a clean hangup.
  Future<void> disconnectConnectedCall(
    String zegoCallId, {
    required DateTime endedAt,
    required int durationInSeconds,
  }) {
    return _resolveConnectedCall(
      zegoCallId,
      status: CallStatus.disconnected,
      endedAt: endedAt,
      durationInSeconds: durationInSeconds,
    );
  }

  Future<void> _resolveConnectedCall(
    String zegoCallId, {
    required CallStatus status,
    required DateTime endedAt,
    required int durationInSeconds,
  }) async {
    final snapshot = await _calls
        .where('zegoCallId', isEqualTo: zegoCallId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return;
    final doc = snapshot.docs.first.reference;

    await _firestore.runTransaction((transaction) async {
      final current = await transaction.get(doc);
      if (current.data()?['status'] != CallStatus.connected.name) return;
      transaction.update(doc, {
        'status': status.name,
        'endedAt': Timestamp.fromDate(endedAt),
        'durationInSeconds': durationInSeconds,
      });
    });
  }

  /// All calls involving [userId], newest first. Runs the "as caller" and
  /// "as receiver" queries separately and merges them on the client,
  /// since Firestore can't OR across two fields in one query.
  Stream<List<CallModel>> watchCallHistory(String userId) {
    late final StreamController<List<CallModel>> controller;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? callerDocs;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? receiverDocs;
    StreamSubscription? callerSub;
    StreamSubscription? receiverSub;

    void emitMerged() {
      if (callerDocs == null || receiverDocs == null) return;
      final calls = <String, CallModel>{};
      for (final doc in [...callerDocs!, ...receiverDocs!]) {
        // Skip a broken doc (like an unrecognized enum value) instead of
        // breaking the whole merged history stream.
        try {
          calls[doc.id] = CallModel.fromMap(doc.id, doc.data());
        } on FormatException catch (error) {
          debugPrint('CallService.watchCallHistory: skipping malformed call doc: $error');
        }
      }
      final list = calls.values.toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      controller.add(list);
    }

    controller = StreamController<List<CallModel>>(
      onListen: () {
        callerSub = _calls
            .where('callerId', isEqualTo: userId)
            .snapshots()
            .listen((snapshot) {
              callerDocs = snapshot.docs;
              emitMerged();
            }, onError: controller.addError);
        receiverSub = _calls
            .where('receiverId', isEqualTo: userId)
            .snapshots()
            .listen((snapshot) {
              receiverDocs = snapshot.docs;
              emitMerged();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await callerSub?.cancel();
        await receiverSub?.cancel();
      },
    );

    return controller.stream;
  }
}
