// lib/main.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mostaql_job_finder/models/job.dart';
import 'package:mostaql_job_finder/services/scraping_service.dart';
import 'package:mostaql_job_finder/job_details_page.dart';
import 'package:mostaql_job_finder/settings_page.dart';
import 'package:shimmer/shimmer.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Mostaql Job Finder',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.lightBlue.shade100,
            cardColor: Colors.white.withOpacity(0.7),
            textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black87)),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black87),
              titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.blueGrey.shade900,
            cardColor: Colors.black.withOpacity(0.5),
            textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          themeMode: mode,
          home: const MyHomePage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrapingService _scrapingService = ScrapingService();
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  bool _isLoading = true;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'أعمال وخدمات استشارية', 'برمجة، تطوير المواقع والتطبيقات', 'هندسة، عمارة وتصميم داخلي',
    'تصميم، فيديو وصوتيات', 'تسويق إلكتروني ومبيعات', 'كتابة، تحرير، ترجمة ولغات',
    'دعم، مساعدة وإدخال بيانات', 'تدريب وتعليم عن بعد',
  ];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _searchController.addListener(() {
      _filterJobs(_searchController.text);
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs({String? category}) async {
    setState(() => _isLoading = true);
    try {
      final jobs = await _scrapingService.fetchJobs(category: category);
      setState(() {
        _jobs = jobs;
        _filteredJobs = jobs;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch jobs: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterJobs(String query) {
    final filtered = _jobs.where((job) {
      return job.title.toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() => _filteredJobs = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2))),
              ),
              child: AppBar(
                title: const Text('Mostaql Job Finder'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: _buildSearchField(theme)),
                        const SizedBox(width: 10),
                        _buildCategoryDropdown(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.blueGrey.shade900, Colors.black]
                : [Colors.lightBlue.shade100, Colors.blue.shade300],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => _fetchJobs(category: _selectedCategory),
          child: _isLoading
              ? _buildShimmerList()
              : _filteredJobs.isEmpty 
                  ? const Center(child: Text("No jobs found.", style: TextStyle(fontSize: 18)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 130, bottom: 20),
                      itemCount: _filteredJobs.length,
                      itemBuilder: (context, index) {
                        final job = _filteredJobs[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobDetailsPage(job: job),
                              ),
                            );
                          },
                          child: JobCard(job: job),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search for a job...',
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: theme.cardColor.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: const Text('All'),
          dropdownColor: theme.scaffoldBackgroundColor,
          items: [const DropdownMenuItem<String>(value: null, child: Text("All Categories"))]
              .followedBy(_categories.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))).toList(),
          onChanged: (String? newValue) {
            setState(() => _selectedCategory = newValue);
            _fetchJobs(category: _selectedCategory);
          },
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade500.withOpacity(0.5),
      highlightColor: Colors.grey.shade200.withOpacity(0.5),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 130),
        itemCount: 7,
        itemBuilder: (context, index) => const ShimmerJobCard(),
      ),
    );
  }
}

// Reusable Job Card Widget
class JobCard extends StatelessWidget {
  final Job job;
  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
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
                Text(job.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(job.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(job.postTime, style: theme.textTheme.bodySmall),
                    Text('${job.offerCount} offers', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
  }
}

// Shimmer Placeholder for the Job Card
class ShimmerJobCard extends StatelessWidget {
  const ShimmerJobCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 20, width: double.infinity, color: Colors.white),
          const SizedBox(height: 12),
          Container(height: 14, width: double.infinity, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 14, width: MediaQuery.of(context).size.width * 0.7, color: Colors.white),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(height: 12, width: 80, color: Colors.white),
              Container(height: 12, width: 60, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}