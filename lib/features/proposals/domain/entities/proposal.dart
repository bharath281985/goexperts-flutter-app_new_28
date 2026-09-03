import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums.dart';

/// A proposal a freelancer submits to a project (and that a client reviews).
class Proposal extends Equatable {
  const Proposal({
    required this.id,
    required this.projectTitle,
    required this.freelancerName,
    required this.bidAmount,
    required this.isHourly,
    required this.coverLetter,
    required this.status,
    required this.submittedAt,
    this.projectId,
    this.projectDescription,
    this.clientId,
    this.clientName,
    this.freelancerId,
    this.freelancerAvatar,
    this.contractId,
    this.deliveryDays = 14,
    this.freelancerRating = 4.8,
    this.attachments = const [],
  });

  final String id;
  final String? projectId;
  final String projectTitle;
  final String? projectDescription;
  final String? clientId;
  final String? clientName;
  final String? freelancerId;
  final String freelancerName;
  final String? freelancerAvatar;
  final String? contractId;
  final double bidAmount;
  final bool isHourly;
  final String coverLetter;
  final EntityStatus status;
  final DateTime submittedAt;
  final int deliveryDays;
  final double freelancerRating;
  final List<String> attachments;

  Proposal copyWith({
    EntityStatus? status,
    String? contractId,
    String? projectDescription,
  }) => Proposal(
    id: id,
    projectId: projectId,
    projectTitle: projectTitle,
    projectDescription: projectDescription ?? this.projectDescription,
    clientId: clientId,
    clientName: clientName,
    freelancerId: freelancerId,
    freelancerName: freelancerName,
    freelancerAvatar: freelancerAvatar,
    contractId: contractId ?? this.contractId,
    bidAmount: bidAmount,
    isHourly: isHourly,
    coverLetter: coverLetter,
    status: status ?? this.status,
    submittedAt: submittedAt,
    deliveryDays: deliveryDays,
    freelancerRating: freelancerRating,
    attachments: attachments,
  );

  @override
  List<Object?> get props => [
    id,
    projectId,
    projectTitle,
    projectDescription,
    status,
    freelancerId,
    clientId,
    contractId,
  ];
}
