// Enhanced job.dart model with all the fields from the website
class Job {
  final String title;
  final String description;
  final String author;
  final String postTime;
  final int offerCount;
  final String url;
  
  // Project details
  String? status;
  String? budget;
  String? executionDuration;
  List<String>? skills;
  
  // Employer information
  String? employerName;
  String? employerProfession;
  String? employerRegistrationDate;
  String? employerHiringRate;
  String? employerOpenProjects;

  // Helper to parse budget to a double
  double? get parsedBudget {
    if (budget == null || budget!.isEmpty) return null;
    // Remove currency symbols and commas, then parse
    final cleanBudget = budget!.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanBudget);
  }

  // Helper to parse hiring rate to a double (percentage)
  double? get parsedEmployerHiringRate {
    if (employerHiringRate == null || employerHiringRate!.isEmpty) return null;
    // Remove percentage sign and parse
    final cleanRate = employerHiringRate!.replaceAll('%', '');
    return double.tryParse(cleanRate);
  }
  String? employerOngoingCommunications;
  String? employerProjectsInProgress;
  
  // Additional fields that might be available
  String? projectType;
  String? location;
  String? applicationDeadline;
  List<String>? attachments;
  String? clientRating;
  String? clientCountry;
  String? clientVerificationStatus;
  int? clientTotalProjects;
  int? clientCompletedProjects;
  String? clientLastSeen;
  String? projectCategory;
  String? projectSubcategory;
  bool? isUrgent;
  bool? isFeatured;
  String? paymentMethod;
  String? deliveryMethod;
  List<String>? requirements;
  String? workType; // Remote, on-site, hybrid
  String? experienceLevel;
  String? portfolioRequired;

  Job({
    required this.title,
    required this.description,
    required this.author,
    required this.postTime,
    required this.offerCount,
    required this.url,
    this.status,
    this.budget,
    this.executionDuration,
    this.skills,
    this.employerName,
    this.employerProfession,
    this.employerRegistrationDate,
    this.employerHiringRate,
    this.employerOpenProjects,
    this.employerOngoingCommunications,
    this.employerProjectsInProgress,
    this.projectType,
    this.location,
    this.applicationDeadline,
    this.attachments,
    this.clientRating,
    this.clientCountry,
    this.clientVerificationStatus,
    this.clientTotalProjects,
    this.clientCompletedProjects,
    this.clientLastSeen,
    this.projectCategory,
    this.projectSubcategory,
    this.isUrgent,
    this.isFeatured,
    this.paymentMethod,
    this.deliveryMethod,
    this.requirements,
    this.workType,
    this.experienceLevel,
    this.portfolioRequired,
  });

  Job copyWith({
    String? title,
    String? description,
    String? author,
    String? postTime,
    int? offerCount,
    String? url,
    String? status,
    String? budget,
    String? executionDuration,
    List<String>? skills,
    String? employerName,
    String? employerProfession,
    String? employerRegistrationDate,
    String? employerHiringRate,
    String? employerOpenProjects,
    String? employerOngoingCommunications,
    String? employerProjectsInProgress,   
    String? projectType,
    String? location,
    String? applicationDeadline,
    List<String>? attachments,
    String? clientRating,
    String? clientCountry,
    String? clientVerificationStatus,
    int? clientTotalProjects,
    int? clientCompletedProjects,
    String? clientLastSeen,
    String? projectCategory,
    String? projectSubcategory,
    bool? isUrgent,
    bool? isFeatured,
    String? paymentMethod,
    String? deliveryMethod,
    List<String>? requirements,
    String? workType,
    String? experienceLevel,
    String? portfolioRequired,
  }) {
    return Job(
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      postTime: postTime ?? this.postTime,
      offerCount: offerCount ?? this.offerCount,
      url: url ?? this.url,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      executionDuration: executionDuration ?? this.executionDuration,
      skills: skills ?? this.skills,
      employerName: employerName ?? this.employerName,
      employerProfession: employerProfession ?? this.employerProfession,
      employerRegistrationDate: employerRegistrationDate ?? this.employerRegistrationDate,
      employerHiringRate: employerHiringRate ?? this.employerHiringRate,
      employerOpenProjects: employerOpenProjects ?? this.employerOpenProjects,
      employerOngoingCommunications: employerOngoingCommunications ?? this.employerOngoingCommunications,
      employerProjectsInProgress: employerProjectsInProgress ?? this.employerProjectsInProgress,
      projectType: projectType ?? this.projectType,
      location: location ?? this.location,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      attachments: attachments ?? this.attachments,
      clientRating: clientRating ?? this.clientRating,
      clientCountry: clientCountry ?? this.clientCountry,
      clientVerificationStatus: clientVerificationStatus ?? this.clientVerificationStatus,
      clientTotalProjects: clientTotalProjects ?? this.clientTotalProjects,
      clientCompletedProjects: clientCompletedProjects ?? this.clientCompletedProjects,
      clientLastSeen: clientLastSeen ?? this.clientLastSeen,
      projectCategory: projectCategory ?? this.projectCategory,
      projectSubcategory: projectSubcategory ?? this.projectSubcategory,
      isUrgent: isUrgent ?? this.isUrgent,
      isFeatured: isFeatured ?? this.isFeatured,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      requirements: requirements ?? this.requirements,
      workType: workType ?? this.workType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      portfolioRequired: portfolioRequired ?? this.portfolioRequired,
    );
  }
}