// lib/models/job.dart

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
  String? employerOngoingCommunications;
  String? employerProjectsInProgress;

  // --- NEW: Helper getters for filtering ---

  // Parses the budget string (e.g., "$25.00 - $50.00") into an average number.
  double? get parsedBudget {
    if (budget == null || budget!.isEmpty) return null;
    final numbers = RegExp(r'(\d+\.?\d*)').allMatches(budget!).map((m) => double.tryParse(m.group(1) ?? ''));
    if (numbers.isEmpty) return null;
    return numbers.where((n) => n != null).map((n) => n!).reduce((a, b) => a + b) / numbers.length;
  }

  // Parses the hiring rate string (e.g., "95.00%") into a number.
  double? get parsedEmployerHiringRate {
    if (employerHiringRate == null || employerHiringRate!.isEmpty) return null;
    final cleanRate = employerHiringRate!.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanRate);
  }

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
    );
  }
}