import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sankar_group/models/call_model.dart';

Map<String, dynamic> _validMap({String? callType, String? status}) {
  return {
    'callerId': 'caller-1',
    'callerName': 'Caller',
    'receiverId': 'receiver-1',
    'receiverName': 'Receiver',
    'callType': callType ?? 'audio',
    'status': status ?? 'ended',
    'startedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    'endedAt': null,
    'durationInSeconds': 0,
    'zegoCallId': 'zego-1',
  };
}

void main() {
  group('CallModel.fromMap', () {
    test('parses a well-formed document', () {
      final call = CallModel.fromMap('doc-1', _validMap());
      expect(call.id, 'doc-1');
      expect(call.callType, CallType.audio);
      expect(call.status, CallStatus.ended);
    });

    test('throws FormatException for an unrecognized callType', () {
      expect(
        () => CallModel.fromMap('doc-2', _validMap(callType: 'holographic')),
        throwsFormatException,
      );
    });

    test('throws FormatException for an unrecognized status', () {
      expect(
        () => CallModel.fromMap('doc-3', _validMap(status: 'teleporting')),
        throwsFormatException,
      );
    });
  });
}
