enum CallType {
  outgoing('OUTGOING'),
  incoming('INCOMING'),
  missed('MISSED');

  final String value;
  const CallType(this.value);

  static CallType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OUTGOING':
        return CallType.outgoing;
      case 'INCOMING':
        return CallType.incoming;
      case 'MISSED':
        return CallType.missed;
      default:
        throw ArgumentError('Invalid call type: $value');
    }
  }
}

enum CallOutcome {
  answered('ANSWERED'),
  noAnswer('NO_ANSWER'),
  busy('BUSY'),
  voicemail('VOICEMAIL'),
  callbackRequested('CALLBACK_REQUESTED');

  final String value;
  const CallOutcome(this.value);

  static CallOutcome fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ANSWERED':
        return CallOutcome.answered;
      case 'NO_ANSWER':
        return CallOutcome.noAnswer;
      case 'BUSY':
        return CallOutcome.busy;
      case 'VOICEMAIL':
        return CallOutcome.voicemail;
      case 'CALLBACK_REQUESTED':
        return CallOutcome.callbackRequested;
      default:
        throw ArgumentError('Invalid call outcome: $value');
    }
  }

  String get displayName {
    switch (this) {
      case CallOutcome.answered:
        return 'Answered';
      case CallOutcome.noAnswer:
        return 'No Answer';
      case CallOutcome.busy:
        return 'Busy';
      case CallOutcome.voicemail:
        return 'Voicemail';
      case CallOutcome.callbackRequested:
        return 'Callback Requested';
    }
  }
}

class CallLog {
  final String? id;
  final String userId;
  final String userName;
  final CallType callType;
  final int duration; // in seconds
  final String? notes;
  final CallOutcome? outcome;
  final DateTime createdAt;

  CallLog({
    this.id,
    required this.userId,
    required this.userName,
    required this.callType,
    required this.duration,
    this.notes,
    this.outcome,
    required this.createdAt,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['_id'] as String?,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      callType: CallType.fromString(json['callType'] as String),
      duration: json['duration'] as int,
      notes: json['notes'] as String?,
      outcome: json['outcome'] != null
          ? CallOutcome.fromString(json['outcome'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'userId': userId,
      'userName': userName,
      'callType': callType.value,
      'duration': duration,
      if (notes != null) 'notes': notes,
      if (outcome != null) 'outcome': outcome!.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper method to format duration as MM:SS
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Helper method to get call type icon
  String get callTypeIcon {
    switch (callType) {
      case CallType.outgoing:
        return '📞';
      case CallType.incoming:
        return '📱';
      case CallType.missed:
        return '❌';
    }
  }

  // Helper method to get call type display name
  String get callTypeDisplayName {
    switch (callType) {
      case CallType.outgoing:
        return 'Outgoing';
      case CallType.incoming:
        return 'Incoming';
      case CallType.missed:
        return 'Missed';
    }
  }
}
