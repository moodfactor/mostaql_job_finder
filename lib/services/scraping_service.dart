// lib/services/scraping_service.dart

import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import '../models/job.dart';

class ScrapingService {
  final Map<String, String> _categorySlugs = {
    'أعمال وخدمات استشارية': 'business',
    'برمجة، تطوير المواقع والتطبيقات': 'programming',
    'هندسة، عمارة وتصميم داخلي': 'engineering-architecture',
    'تصميم، فيديو وصوتيات': 'design-video-audio',
    'تسويق إلكتروني ومبيعات': 'marketing-sales',
    'كتابة، تحرير، ترجمة ولغات': 'writing-translation',
    'دعم، مساعدة وإدخال بيانات': 'data-entry',
    'تدريب وتعليم عن بعد': 'remote-training',
  };

  Future<List<Job>> fetchJobs({String? category}) async {
    String url = 'https://mostaql.com/projects';
    if (category != null && _categorySlugs.containsKey(category)) {
      url = '$url/skill/${_categorySlugs[category]}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = parse(response.body);
      final jobElements = document.querySelectorAll('tbody > tr');
      List<Job> jobs = [];
      for (var element in jobElements) {
        final titleElement = element.querySelector('h2 > a');
        final title = titleElement?.text.trim() ?? '';
        final jobUrl = titleElement?.attributes['href'] ?? '';
        final description = element.querySelector('p')?.text.trim() ?? '';
        final author = element.querySelector('td > a.user-card-name')?.text.trim() ?? '';
        final postTime = element.querySelector('time')?.text.trim() ?? '';
        final offerCountString = element.querySelector('td > div > span')?.text.trim() ?? '0';
        final offerCount = int.tryParse(offerCountString.split(' ')[0]) ?? 0;
        jobs.add(Job(
          title: title,
          description: description,
          author: author,
          postTime: postTime,
          offerCount: offerCount,
          url: jobUrl,
        ));
      }
      return jobs;
    } else {
      throw Exception('Failed to load jobs');
    }
  }

  /// More robustly fetches all details from the job page.

Future<Job> fetchJobDetails(String jobUrl) async {
  final response = await http.get(Uri.parse(jobUrl));
  if (response.statusCode != 200) {
    throw Exception('Failed to load job details.');
  }

  final document = parse(response.body);

  final projectDetailsCard = document.querySelector('div.project-details-card');
  final employerCard = document.querySelector('div.profile-card');

  final title = document.querySelector('h1')?.text.trim() ?? '';

  // Get description
  String description = '';
  final descElement = document.querySelector('.project-description-card .card-body') ?? 
                     document.querySelector('.project-description');
  if (descElement != null) {
    description = descElement.text.trim();
  }

  // Extract project details with broader search
  String? status, postTime, budget, executionDuration;
  
  // Search entire page for project details
  final allText = document.body?.text ?? '';
  
  // Extract status
  if (allText.contains('مفتوح')) status = 'مفتوح';
  else if (allText.contains('مغلق')) status = 'مغلق';
  
  // Extract budget
  final budgetMatch = RegExp(r'(\d+)\s*(ريال|دولار|\$)').firstMatch(allText);
  if (budgetMatch != null) {
    budget = '${budgetMatch.group(1)} ${budgetMatch.group(2)}';
  }
  
  // Extract duration
  final durationMatch = RegExp(r'(\d+)\s*(يوم|أسبوع|شهر)').firstMatch(allText);
  if (durationMatch != null) {
    executionDuration = '${durationMatch.group(1)} ${durationMatch.group(2)}';
  }

  // Extract skills with multiple selectors
  List<String> skills = [];
  final skillSelectors = [
    'ul.skills__list > li.skills__item > a',
    '.skills a',
    '[class*="skill"] a',
    '.tag',
    '.badge'
  ];
  
  for (String selector in skillSelectors) {
    final skillElements = document.querySelectorAll(selector);
    if (skillElements.isNotEmpty) {
      skills = skillElements.map((e) => e.text.trim()).where((s) => s.isNotEmpty).toList();
      if (skills.isNotEmpty) break;
    }
  }

  String? employerName, employerProfession, employerRegistrationDate,
      employerHiringRate, employerOpenProjects, employerProjectsInProgress,
      employerOngoingCommunications;

  if (employerCard != null) {
    employerName = employerCard.querySelector('h5.profile-card__title a')?.text.trim();
    employerProfession = employerCard.querySelector('span.profile-card__specialization')?.text.trim();

    final metaItems = employerCard.querySelectorAll('.profile-card__meta > div');
    for (var item in metaItems) {
      final label = item.querySelector('.profile-card__meta-key')?.text.trim();
      final value = item.querySelector('.profile-card__meta-value')?.text.trim();
      if (label != null && value != null) {
        if (label.contains('تاريخ التسجيل')) employerRegistrationDate = value;
        if (label.contains('معدل توظيف')) employerHiringRate = value;
        if (label.contains('المشاريع المفتوحة')) employerOpenProjects = value;
        if (label.contains('مشاريع قيد التنفيذ')) employerProjectsInProgress = value;
        if (label.contains('التواصلات الجارية')) employerOngoingCommunications = value;
      }
    }
  }

  return Job(
    title: title,
    description: description,
    author: employerName ?? '',
    postTime: postTime ?? '',
    offerCount: 0,
    url: jobUrl,
    status: status,
    budget: budget,
    executionDuration: executionDuration,
    skills: skills.isNotEmpty ? skills : null,
    employerName: employerName,
    employerProfession: employerProfession,
    employerRegistrationDate: employerRegistrationDate,
    employerHiringRate: employerHiringRate,
    employerOpenProjects: employerOpenProjects,
    employerProjectsInProgress: employerProjectsInProgress,
    employerOngoingCommunications: employerOngoingCommunications,
  );
}

}
