import 'package:cloud_firestore/cloud_firestore.dart';

enum CallType { audio, video }

enum CallStatus {
  calling,
  ringing,
  connected,
  ended,
  rejected,
  missed,
  failed,
  disconnected,
}

class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String receiverId;
  final String receiverName;
  final CallType callType;
  final CallStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationInSeconds;
  final String? zegoCallId;

  const CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.receiverName,
    required this.callType,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.durationInSeconds = 0,
    this.zegoCallId,
  });

  /// True when [userId] placed the call rather than received it.
  bool isOutgoingFor(String userId) => callerId == userId;

  /// Throws [FormatException] if [map] contains a `callType`/`status` value
  /// this build doesn't recognize (e.g. a newer app version wrote an enum
  /// value this one predates). Callers merging many docs into one stream
  /// (see [CallService.watchCallHistory]) should catch this per-document so
  /// one malformed record can't take down the whole history stream.
  factory CallModel.fromMap(String id, Map<String, dynamic> map) {
    try {
      return CallModel(
        id: id,
        callerId: map['callerId'] as String? ?? '',
        callerName: map['callerName'] as String? ?? '',
        receiverId: map['receiverId'] as String? ?? '',
        receiverName: map['receiverName'] as String? ?? '',
        callType: CallType.values.byName(
          map['callType'] as String? ?? 'audio',
        ),
        status: CallStatus.values.byName(
          map['status'] as String? ?? 'ended',
        ),
        startedAt:
            (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
        durationInSeconds: map['durationInSeconds'] as int? ?? 0,
        zegoCallId: map['zegoCallId'] as String?,
      );
    } on ArgumentError catch (error) {
      throw FormatException(
        'CallModel.fromMap: unrecognized enum value in call doc $id: $error',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'callType': callType.name,
      'status': status.name,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt == null ? null : Timestamp.fromDate(endedAt!),
      'durationInSeconds': durationInSeconds,
      'zegoCallId': zegoCallId,
    };
  }
}
