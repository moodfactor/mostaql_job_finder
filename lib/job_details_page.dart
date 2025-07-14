// lib/ui/job_details_page.dart

import 'dart:ui';
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final detailedJob = await _scrapingService.fetchJobDetails(widget.job.url);
      if (mounted) {
        setState(() {
          _jobDetails = _jobDetails.copyWith(
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
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open URL: $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true, // Allows the body to be seen behind the AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0,
        title: Text(
          _jobDetails.title.isNotEmpty ? _jobDetails.title : "Job Details",
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
        ),
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black87),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2))),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchJobDetails,
          ),
        ],
      ),
      body: Container(
        // The beautiful gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.blueGrey.shade900, Colors.black]
                : [Colors.lightBlue.shade100, Colors.blue.shade300],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorWidget()
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          _buildDescriptionCard(),
                          _buildProjectInfoCard(),
                          if (_jobDetails.skills != null && _jobDetails.skills!.isNotEmpty) _buildSkillsCard(),
                          if (_jobDetails.employerName != null) _buildEmployerCard(),
                          _buildProposalCard(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildGlassCard({required String title, required List<Widget> children, Widget? trailing}) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
              const Divider(height: 24, thickness: 0.5),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {IconData? icon}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, size: 18, color: theme.iconTheme.color?.withOpacity(0.7)),
          if (icon != null) const SizedBox(width: 12),
          Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Flexible(
            child: Text(
              value?.trim() ?? 'غير محدد',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: value == null ? theme.textTheme.bodyLarge?.color?.withOpacity(0.5) : null,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    if (status == null || status.isEmpty) return const SizedBox.shrink();
    Color color = Colors.grey;
    String text = status;
    if (status.contains('مفتوح')) { color = Colors.green; text = 'مفتوح'; }
    if (status.contains('مغلق')) { color = Colors.red; text = 'مغلق'; }
    if (status.contains('قيد التنفيذ')) { color = Colors.orange; text = 'قيد التنفيذ'; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
  
  // --- CARD SECTION WIDGETS ---

  Widget _buildDescriptionCard() {
    return _buildGlassCard(
      title: 'تفاصيل المشروع',
      children: [
        SelectableText(
          _jobDetails.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SelectableText(
          _jobDetails.description,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      ],
    );
  }

  Widget _buildProjectInfoCard() {
    return _buildGlassCard(
      title: 'بطاقة المشروع',
      trailing: _buildStatusBadge(_jobDetails.status),
      children: [
        _buildDetailRow('الميزانية', _jobDetails.budget, icon: Icons.attach_money),
        _buildDetailRow('مدة التنفيذ', _jobDetails.executionDuration, icon: Icons.timer_outlined),
        _buildDetailRow('تاريخ النشر', _jobDetails.postTime, icon: Icons.calendar_today_outlined),
        _buildDetailRow('عدد العروض', '${_jobDetails.offerCount}', icon: Icons.group_outlined),
      ],
    );
  }
  
  Widget _buildSkillsCard() {
    return _buildGlassCard(
      title: 'المهارات المطلوبة',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _jobDetails.skills!.map((skill) => Chip(
            label: Text(skill),
            backgroundColor: Colors.blue.withOpacity(0.8),
            labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          )).toList(),
        )
      ],
    );
  }

  Widget _buildEmployerCard() {
    return _buildGlassCard(
      title: 'صاحب المشروع',
      trailing: CircleAvatar(
        backgroundColor: Colors.blueGrey,
        child: Text(_jobDetails.employerName?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      children: [
        _buildDetailRow('الاسم', _jobDetails.employerName, icon: Icons.person_outline),
        _buildDetailRow('التخصص', _jobDetails.employerProfession, icon: Icons.work_outline),
        _buildDetailRow('تاريخ التسجيل', _jobDetails.employerRegistrationDate, icon: Icons.event_available_outlined),
        _buildDetailRow('معدل التوظيف', _jobDetails.employerHiringRate, icon: Icons.star_border_outlined),
        _buildDetailRow('المشاريع المفتوحة', _jobDetails.employerOpenProjects, icon: Icons.folder_open_outlined),
      ],
    );
  }

  Widget _buildProposalCard() {
    return _buildGlassCard(
      title: 'تقدم للمشروع',
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('حساب جديد'),
                onPressed: () => _launchURL(_jobDetails.url),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('دخول'),
                onPressed: () => _launchURL(_jobDetails.url),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue.shade300),
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _fetchJobDetails,
            ),
          ],
        ),
      ),
    );
  }
}