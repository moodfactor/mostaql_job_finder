// lib/services/scraping_service.dart

import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import '../models/job.dart';

class ScrapingService {
  final Map<String, String> _categorySlugs = {
    'أعمال وخدمات استشارية': 'business',
    'برمجة، تطوير المواقع والتطبيقات': 'development',
    'هندسة، عمارة وتصميم داخلي': 'engineering-architecture',
    'تصميم، فيديو وصوتيات': 'design',
    'تسويق إلكتروني ومبيعات': 'marketing',
    'كتابة، تحرير، ترجمة ولغات': 'writing-translation',
    'دعم، مساعدة وإدخال بيانات': 'support',
    'تدريب وتعليم عن بعد': 'training',
  };


Future<List<Job>> fetchJobs({String? category, int page = 1}) async {
  String url = 'https://mostaql.com/projects';
  
  // Build URL with proper parameters
  List<String> params = [];
  
  if (category != null && _categorySlugs.containsKey(category)) {
    params.add('category=${_categorySlugs[category]}');
  }
  
  params.add('sort=latest');
  
  if (page > 1) {
    params.add('page=$page');
  }
  
  url = '$url?${params.join('&')}';

  print('Fetching jobs from URL: $url'); // Debug print
  
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
      final offerCountElement = element.querySelector('li.text-muted i.fa-ticket')?.parent;
      final offerCountString = offerCountElement?.text.trim() ?? '0';
      final offerCount = int.tryParse(offerCountString.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
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

    final title = document.querySelector('h1')?.text.trim() ?? '';

    String description = '';
    final descElement = document.querySelector('div#projectDetailsTab div.text-wrapper-div.carda__content');
    if (descElement != null) {
      description = descElement.text.trim();
    }

    String? status, postTime, budget, executionDuration;
    int offerCount = 0;

    final detailsList = document.querySelectorAll('div.meta-row');
    for (var item in detailsList) {
      final label = item.querySelector('.meta-label')?.text.trim();
      final value = item.querySelector('.meta-value')?.text.trim();

      if (label != null && value != null) {
        if (label.contains('حالة المشروع')) {
          status = value;
        } else if (label.contains('تاريخ النشر')) {
          postTime = value;
        } else if (label.contains('الميزانية')) {
          budget = value;
        } else if (label.contains('مدة التنفيذ')) {
          executionDuration = value;
        }
      }
    }

    final offerCountElement = document.querySelector('#project-bids > .heada > .heada__title');
    if (offerCountElement != null) {
      final offerCountText = offerCountElement.text.trim();
      final offerCountMatch = RegExp(r'(\d+)').firstMatch(offerCountText);
      if (offerCountMatch != null) {
        offerCount = int.tryParse(offerCountMatch.group(1)!) ?? 0;
      }
    }

    List<String> skills = [];
    final skillElements = document.querySelectorAll('ul.skills__list > li.skills__item > a');
    skills = skillElements.map((e) => e.text.trim()).toList();

    String? employerName, employerProfession, employerRegistrationDate,
        employerHiringRate, employerOpenProjects, employerProjectsInProgress,
        employerOngoingCommunications;

    final employerCard = document.querySelector('div.profile_card');
    if (employerCard != null) {
      employerName = employerCard.querySelector('h5.postcard__title.profile__name bdi')?.text.trim();
      employerProfession = employerCard.querySelector('ul.meta_items li a')?.text.trim();

      final metaItems = employerCard.querySelectorAll('table.table-meta tbody tr');
for (var item in metaItems) {
  final labelElement = item.querySelector('td:first-child span') ?? item.querySelector('td:first-child');
  final label = labelElement?.text.trim();
  final valueElement = item.querySelector('td:last-child');
  final value = valueElement?.text.trim();

  if (label != null && value != null) {
    if (label.contains('تاريخ التسجيل')) {
      employerRegistrationDate = valueElement?.querySelector('time')?.text.trim() ?? value;
    } else if (label.contains('معدل التوظيف')) {
      employerHiringRate = valueElement?.querySelector('label')?.text.trim() ?? value;
    } else if (label.contains('المشاريع المفتوحة')) {
      employerOpenProjects = value;
    } else if (label.contains('مشاريع قيد التنفيذ')) {
      employerProjectsInProgress = value;
    } else if (label.contains('التواصلات الجارية')) {
      employerOngoingCommunications = value;
    }
  }
}
    }

    return Job(
      title: title,
      description: description,
      author: employerName ?? '',
      postTime: postTime ?? '',
      offerCount: offerCount,
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
