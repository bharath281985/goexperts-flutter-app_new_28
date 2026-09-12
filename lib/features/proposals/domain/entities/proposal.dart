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
    this.clientAvatar,
    this.freelancerId,
    this.freelancerAvatar,
    this.contractId,
    this.deliveryDays = 14,
    this.freelancerRating = 4.8,
    this.attachments = const [],
    this.isOwner = false,
  });

  final String id;
  final String? projectId;
  final String projectTitle;
  final String? projectDescription;
  final String? clientId;
  final String? clientName;
  final String? clientAvatar;
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
  final bool isOwner;

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
    clientAvatar: clientAvatar,
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
    isOwner: isOwner,
  );

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? json['project']?['id']?.toString(),
      projectTitle: json['projectTitle']?.toString() ?? '',
      projectDescription: json['projectDescription']?.toString() ?? json['project']?['description']?.toString(),
      clientId: json['clientId']?.toString() ?? json['project']?['client']?.toString(),
      clientName: json['clientName']?.toString(),
      clientAvatar: json['clientAvatar']?.toString(),
      freelancerId: json['freelancerId']?.toString(),
      freelancerName: json['freelancerName']?.toString() ?? 'Freelancer',
      freelancerAvatar: json['freelancerAvatar']?.toString(),
      contractId: json['contractId']?.toString(),
      bidAmount: double.tryParse(json['bidAmount']?.toString() ?? '0') ?? 0,
      isHourly: json['isHourly'] == true,
      coverLetter: json['coverLetter']?.toString() ?? '',
      status: EntityStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status']?.toString().toUpperCase() ?? ''),
        orElse: () => EntityStatus.pending,
      ),
      submittedAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      deliveryDays: int.tryParse(json['deliveryTime']?.toString() ?? '14') ?? 14,
      freelancerRating: double.tryParse(json['freelancerRating']?.toString() ?? '4.8') ?? 4.8,
      attachments: (json['attachments'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isOwner: json['isOwner'] == true,
    );
  }

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
    bidAmount,
    isHourly,
    coverLetter,
    submittedAt,
    deliveryDays,
    freelancerRating,
    attachments,
    isOwner,
  ];
}
