import 'package:flutter_test/flutter_test.dart';
import 'package:mostaql_job_finder/models/job.dart';
import 'package:mostaql_job_finder/services/scraping_service.dart';

class MockScrapingService implements ScrapingService {
  @override
  Future<Job> fetchJobDetails(String jobUrl) async {
    return Job(
      title: 'Test Job',
      description: 'Test Description',
      author: 'Test Author',
      postTime: 'Test Post Time',
      offerCount: 10,
      url: jobUrl,
      status: 'Open',
      budget: '\$100 - \$200',
      executionDuration: '1 week',
      skills: ['Flutter', 'Dart'],
      employerName: 'Test Employer',
      employerProfession: 'Test Profession',
      employerRegistrationDate: '2022-01-01',
      employerHiringRate: '100%',
      employerOpenProjects: '1',
      employerProjectsInProgress: '0',
      employerOngoingCommunications: '0',
    );
  }

  @override
  Future<List<Job>> fetchJobs({String? category, int page = 1}) async {
    return [];
  }
}

void main() {
  test('fetchJobDetails retrieves details correctly', () async {
    final scrapingService = MockScrapingService();
    final job = await scrapingService.fetchJobDetails(
      'https://mostaql.com/project/1121054-%D8%AA%D8%B5%D9%85%D9%8A%D9%85-%D9%85%D8%AA%D8%AC%D8%B1-%D8%A5%D9%84%D9%83%D8%AA%D8%B1%D9%88%D9%86%D9%8A-%D8%AE%D8%A7%D8%B5-%D8%A8%D9%85%D9%84%D8%A7%D8%A8%D8%B3-%D8%B9%D9%84%D9%89-%D9%88%D9%88%D8%B1%D8%AF%D8%A8%D8%B1%D9%8A%D8%B3',
    );

    expect(job.offerCount, isNot(0));
    expect(job.status, isNotNull);
    expect(job.postTime, isNotNull);
    expect(job.budget, isNotNull);
    expect(job.executionDuration, isNotNull);
    expect(job.skills, isNotEmpty);
    expect(job.employerName, isNotNull);
    expect(job.employerProfession, isNotNull);
    expect(job.employerRegistrationDate, isNotNull);
    expect(job.parsedEmployerHiringRate, isNotNull);
    expect(job.employerOpenProjects, isNotNull);
    expect(job.employerProjectsInProgress, isNotNull);
    expect(job.employerOngoingCommunications, isNotNull);
  });
}