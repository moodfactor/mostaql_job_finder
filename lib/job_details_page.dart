// job_details_page.dart
// This file defines the JobDetailsPage widget for displaying detailed information about a job. 
// It fetches job details from the ScrapingService and displays them in a structured format.
// The page includes sections for project details, employer information, and a proposal submission section.
// It also handles loading states and errors gracefully, providing a user-friendly experience.

import 'package:flutter/material.dart';
import 'package:mostaql_job_finder/models/job.dart';
import 'package:mostaql_job_finder/services/scraping_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:ui'; // Import for ImageFilter

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detailedJob = await _scrapingService.fetchJobDetails(widget.job.url);

      if (mounted) {
        print('Original description length: ${_jobDetails.description.length}');
        print('Detailed description length: ${detailedJob.description.length}');
        print('Using description: ${detailedJob.description.isNotEmpty ? "detailed" : "original"}');
        
        setState(() {
          // Use copyWith to merge new details into the existing job object
          _jobDetails = _jobDetails.copyWith(
            // Only update fields that were successfully scraped
            title: detailedJob.title.isNotEmpty ? detailedJob.title : _jobDetails.title,
            description: detailedJob.description.isNotEmpty ? detailedJob.description : _jobDetails.description,
            author: detailedJob.author.isNotEmpty ? detailedJob.author : _jobDetails.author,
            postTime: detailedJob.postTime.isNotEmpty ? detailedJob.postTime : _jobDetails.postTime,
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
            _buildDetailRow('حالة المشروع', _jobDetails.status),
            _buildDetailRow('الميزانية', _jobDetails.budget),
            _buildDetailRow('مدة التنفيذ', _jobDetails.executionDuration),
            _buildDetailRow('عدد العروض', '${_jobDetails.offerCount}'),
            _buildDetailRow('تاريخ النشر', _jobDetails.postTime),
            
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
            _buildDetailRow('تاريخ التسجيل', _jobDetails.employerRegistrationDate),
            _buildDetailRow('معدل التوظيف', _jobDetails.employerHiringRate),
            _buildDetailRow('المشاريع المفتوحة', _jobDetails.employerOpenProjects),
            _buildDetailRow('التواصلات الجارية', _jobDetails.employerOngoingCommunications),
          ],
        ),
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

    // --- WIDGETS ---

  // Helper to show placeholder text for missing data
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value ?? 'غير محدد', // Show placeholder if value is null
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15, color: value == null ? Colors.grey : null),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: Colors.transparent, // Make card transparent to show blur effect
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.3), // Adjust opacity for glass effect
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }


  // --- WIDGET BUILDERS ---


  /// Creates a styled chip for displaying a skill.
  Widget _buildSkillChip(String skill) {
    return Chip(
      label: Text(skill),
      backgroundColor: Colors.blue.withOpacity(0.8),
      labelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }

  /// The main build method that constructs the entire page UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _jobDetails.title.isNotEmpty ? _jobDetails.title : "تفاصيل المشروع",
          overflow: TextOverflow.ellipsis,
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
              ),
            ),
          ),
        ),
        actions: [
          // Refresh button is disabled during the loading state.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchJobDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[300], size: 60),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          onPressed: _fetchJobDetails,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        // --- Card for Project Description ---
                        _buildCard(
                          title: 'تفاصيل المشروع',
                          children: [
                            Text(
                              _jobDetails.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              _jobDetails.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(height: 1.5, fontSize: 16),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              minLines: 1,
                              maxLines: null,
                            ),
                          ],
                        ),

                        // --- Card for Project Info ---
                        _buildCard(
                          title: 'بطاقة المشروع',
                          children: [
                            _buildDetailRow('حالة المشروع', _jobDetails.status),
                            _buildDetailRow('الميزانية', _jobDetails.budget),
                            _buildDetailRow('مدة التنفيذ', _jobDetails.executionDuration),
                            _buildDetailRow('تاريخ النشر', _jobDetails.postTime),
                            _buildDetailRow('عدد العروض', '${_jobDetails.offerCount}'),
                          ],
                        ),
                        
                        // --- Card for Skills (only shows if skills exist) ---
                        if (_jobDetails.skills != null && _jobDetails.skills!.isNotEmpty)
                          _buildCard(
                            title: 'المهارات المطلوبة',
                            children: [
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: _jobDetails.skills!.map(_buildSkillChip).toList(),
                              )
                            ],
                          ),

                        // --- Card for Employer (only shows if employer details exist) ---
                        if (_jobDetails.employerName != null)
                          _buildCard(
                            title: 'صاحب المشروع',
                            children: [
                              _buildDetailRow('الاسم', _jobDetails.employerName),
                              _buildDetailRow('التخصص', _jobDetails.employerProfession),
                              _buildDetailRow('تاريخ التسجيل', _jobDetails.employerRegistrationDate),
                              _buildDetailRow('معدل التوظيف', _jobDetails.employerHiringRate),
                              _buildDetailRow('المشاريع المفتوحة', _jobDetails.employerOpenProjects),
                              _buildDetailRow('التواصلات الجارية', _jobDetails.employerOngoingCommunications),
                            ],
                          ),
                          
                        // --- Card for Submitting a Proposal ---
                        _buildCard(
                          title: 'تقدم للمشروع',
                          children: [
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
                            const SizedBox(height: 16),
                            const Center(
                              child: Text(
                                'لا يوجد عروض بعد.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
} 