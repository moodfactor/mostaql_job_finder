// Enhanced scraping service to capture all job details like the website
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
        final author =
            element.querySelector('td > a.user-card-name')?.text.trim() ?? '';
        final postTime = element.querySelector('time')?.text.trim() ?? '';
        final offerCountString =
            element.querySelector('td > div > span')?.text.trim() ?? '0';
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

  /// Fetches all details from the job page, based on the provided screenshots.
  Future<Job> fetchJobDetails(String jobUrl) async {
    final response = await http.get(Uri.parse(jobUrl));

    if (response.statusCode == 200) {
      final document = parse(response.body);

      // --- Main Project Details (Right Side) ---
      final title = document.querySelector('h1.project-title')?.text.trim() ?? '';

      // This selector grabs the entire description block, preserving all text and structure.
      final descriptionContainer = document.querySelector('div.project-description-card > .card-body');
      final description = descriptionContainer?.text.trim().replaceAll(RegExp(r'\s+\n'), '\n\n') ?? '';

      // --- Project Card (بطاقة المشروع - Left Sidebar) ---
      String? status;
      String? postTime;
      String? budget;
      String? executionDuration;
      
      final projectDetailsItems = document.querySelectorAll('div.project-details-card__meta-item');
      for (var item in projectDetailsItems) {
        final label = item.querySelector('.project-details-card__meta-item-label')?.text.trim();
        final value = item.querySelector('.project-details-card__meta-item-value')?.text.trim();

        if (value == null) continue;

        switch (label) {
          case 'حالة المشروع':
            status = item.text.trim(); // Get full text including the status chip
            break;
          case 'تاريخ النشر':
            postTime = value;
            break;
          case 'الميزانية':
            budget = value;
            break;
          case 'مدة التنفيذ':
            executionDuration = value;
            break;
        }
      }
      // The green status chip at the top is another place to find the status.
      status ??= document.querySelector('.project-details-card__status bdi')?.text.trim();


      // --- Skills (المهارات) ---
      final skills = document.querySelectorAll('ul.skills__list > li.skills__item > a').map((e) => e.text.trim()).toList();
      
      // --- Employer Card (صاحب المشروع - Left Sidebar) ---
      final employerCard = document.querySelector('div.profile-card');
      final employerName = employerCard?.querySelector('h5.profile-card__title > a')?.text.trim();
      final employerProfession = employerCard?.querySelector('span.profile-card__specialization')?.text.trim();
      final author = employerName ?? '';

      // --- Employer Statistics ---
      String? employerRegistrationDate;
      String? employerHiringRate;
      String? employerOpenProjects;
      String? employerProjectsInProgress; // For 'مشاريع قيد التنفيذ'
      String? employerOngoingCommunications;
      
      final employerMetaItems = employerCard?.querySelectorAll('.profile-card__meta > div');
      if (employerMetaItems != null) {
          for(var item in employerMetaItems) {
              // Using text query selectors for robustness against class changes
              final label = item.querySelector('.profile-card__meta-key')?.text.trim();
              final value = item.querySelector('.profile-card__meta-value')?.text.trim();

              if (value == null) continue;
              
              switch (label) {
                case 'تاريخ التسجيل':
                  employerRegistrationDate = value;
                  break;
                case 'معدل التوظيف':
                  // The hiring rate is inside a nested div, so we get the parent text
                  employerHiringRate = label != null ? item.text.replaceAll(label, '').trim() : item.text.trim();
                  break;
                case 'المشاريع المفتوحة':
                  employerOpenProjects = value;
                  break;
                case 'مشاريع قيد التنفيذ':
                  employerProjectsInProgress = value;
                  break;
                case 'التواصلات الجارية':
                  employerOngoingCommunications = value;
                  break;
              }
          }
      }

      // We use 0 for offerCount as it's not present on the details page.
      // The value from the list page will be preserved by the `copyWith` method.
      return Job(
        title: title,
        description: description,
        author: author,
        postTime: postTime ?? '',
        offerCount: 0, // Not available on this page, will be kept from initial job object
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
    } else {
      throw Exception('Failed to load job details. Status code: ${response.statusCode}');
    }
  }
}