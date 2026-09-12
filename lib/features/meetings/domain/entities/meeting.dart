import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums.dart';

/// A scheduled meeting (interview, deal room call, consultation, etc.).
class Meeting extends Equatable {
  const Meeting({
    required this.id,
    required this.title,
    this.withId = '',
    required this.withName,
    this.withRole = 'Participant',
    required this.startTime,
    this.durationMinutes,
    required this.status,
    this.withAvatar,
    this.hostId,
    this.hostName,
    this.hostAvatar,
    this.isVideo = true,
    this.meetingLink = 'https://meet.goexperts.example/room',
    this.agenda = '',
    this.participants = const [],
  });

  final String id;
  final String title;
  final String withId;
  final String withName;
  final String withRole;
  final String? withAvatar;
  final String? hostId;
  final String? hostName;
  final String? hostAvatar;
  final DateTime startTime;
  final int? durationMinutes;
  final EntityStatus status;
  final bool isVideo;
  final String meetingLink;
  final String agenda;
  final List<String> participants;

  DateTime get endTime =>
      startTime.add(Duration(minutes: durationMinutes ?? 0));
  bool get isUpcoming => startTime.isAfter(DateTime.now());

  @override
  List<Object?> get props => [
    id,
    title,
    withId,
    withName,
    withRole,
    withAvatar,
    hostId,
    hostName,
    hostAvatar,
    startTime,
    durationMinutes,
    status,
    isVideo,
    meetingLink,
    agenda,
    participants,
  ];
}
