import 'package:flutter/material.dart';
import 'package:mostaql_job_finder/models/job.dart';
import 'package:mostaql_job_finder/services/scraping_service.dart';
import 'package:url_launcher/url_launcher.dart';

class JobDetailsPage extends StatefulWidget {
  final Job job;

  const JobDetailsPage({super.key, required this.job});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  late Job _jobDetails;
  bool _isLoading = true;
  String? _errorMessage;
  final ScrapingService _scrapingService = ScrapingService();

  @override
  void initState() {
    super.initState();
    _jobDetails = widget.job;
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final detailedJob = await _scrapingService.fetchJobDetails(widget.job.url);

      if (mounted) {
        setState(() {
          _jobDetails = _jobDetails.copyWith(
            title: detailedJob.title.isNotEmpty ? detailedJob.title : _jobDetails.title,
            description: detailedJob.description.isNotEmpty ? detailedJob.description : _jobDetails.description,
            author: detailedJob.author.isNotEmpty ? detailedJob.author : _jobDetails.author,
            postTime: detailedJob.postTime.isNotEmpty ? detailedJob.postTime : _jobDetails.postTime,
            offerCount: detailedJob.offerCount > 0 ? detailedJob.offerCount : _jobDetails.offerCount,
            status: detailedJob.status,
            budget: detailedJob.budget,
            executionDuration: detailedJob.executionDuration,
            skills: detailedJob.skills,
            employerName: detailedJob.employerName,
            employerProfession: detailedJob.employerProfession,
            employerRegistrationDate: detailedJob.employerRegistrationDate,
            employerHiringRate: detailedJob.employerHiringRate,
            employerOpenProjects: detailedJob.employerOpenProjects,
            employerOngoingCommunications: detailedJob.employerOngoingCommunications,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching job details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load job details. Please try again.';
        });
      }
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open URL: $e')),
        );
      }
    }
  }

  Widget _buildStatusChip(String? status) {
    if (status == null) return const SizedBox.shrink();
    
    Color chipColor = Colors.green;
    String displayStatus = status;
    
    if (status.contains('مفتوح') || status.contains('open')) {
      chipColor = Colors.green;
      displayStatus = 'مفتوح';
    } else if (status.contains('مغلق') || status.contains('closed')) {
      chipColor = Colors.red;
    } else if (status.contains('قيد التنفيذ') || status.contains('in progress')) {
      chipColor = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayStatus,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildProjectCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'بطاقة المشروع',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(_jobDetails.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildProjectDetailRow('حالة المشروع', _jobDetails.status),
            _buildProjectDetailRow('الميزانية', _jobDetails.budget),
            _buildProjectDetailRow('مدة التنفيذ', _jobDetails.executionDuration),
            _buildProjectDetailRow('عدد العروض', '${_jobDetails.offerCount}'),
            _buildProjectDetailRow('تاريخ النشر', _jobDetails.postTime),
            
            if (_jobDetails.skills != null && _jobDetails.skills!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'المهارات',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _jobDetails.skills!.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployerCard() {
    if (_jobDetails.employerName == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'صاحب المشروع',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Employer basic info
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    _jobDetails.employerName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _jobDetails.employerName ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_jobDetails.employerProfession != null)
                        Text(
                          _jobDetails.employerProfession!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Employer statistics
            _buildEmployerStatRow('تاريخ التسجيل', _jobDetails.employerRegistrationDate),
            _buildEmployerStatRow('معدل التوظيف', _jobDetails.employerHiringRate),
            _buildEmployerStatRow('المشاريع المفتوحة', _jobDetails.employerOpenProjects),
            _buildEmployerStatRow('التواصلات الجارية', _jobDetails.employerOngoingCommunications),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployerStatRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildJobDescription() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل المشروع',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _jobDetails.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _jobDetails.description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitProposalSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تقدم للمشروع',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _launchURL(_jobDetails.url),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('حساب جديد'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _launchURL(_jobDetails.url),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('دخول'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'لا يوجد عروض بعد.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _jobDetails.title.isNotEmpty ? _jobDetails.title : "تفاصيل المشروع",
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchJobDetails,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _launchURL(_jobDetails.url),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchJobDetails,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildJobDescription(),
                      _buildProjectCard(),
                      _buildEmployerCard(),
                      _buildSubmitProposalSection(),
                    ],
                  ),
                ),
    );
  }
}