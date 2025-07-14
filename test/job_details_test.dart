import 'package:flutter_test/flutter_test.dart';
import 'package:mostaql_job_finder/services/scraping_service.dart';

void main() {
  test('fetchJobDetails retrieves details correctly', () async {
    final scrapingService = ScrapingService();
    final job = await scrapingService.fetchJobDetails('https://mostaql.com/project/1121029-%D8%AA%D8%B5%D9%85%D9%8A%D9%85-%D9%87%D9%88%D9%8A%D8%A9-%D8%A8%D8%B5%D8%B1%D9%8A%D8%A9-%D9%88%D8%A8%D8%B1%D8%B2%D9%86%D8%AA%D9%8A%D8%B4%D9%86');
    
    expect(job.offerCount, isNot(0));
    expect(job.status, isNotNull);
    expect(job.postTime, isNotNull);
    expect(job.budget, isNotNull);
    expect(job.executionDuration, isNotNull);
    expect(job.skills, isNotEmpty);
    expect(job.employerName, isNotNull);
    expect(job.employerProfession, isNotNull);
    expect(job.employerRegistrationDate, isNotNull);
    expect(job.employerHiringRate, isNotNull);
    expect(job.employerOpenProjects, isNotNull);
    expect(job.employerProjectsInProgress, isNotNull);
    expect(job.employerOngoingCommunications, isNotNull);
  });
}
