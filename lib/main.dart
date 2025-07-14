// main.dart
// This file is the entry point of the Flutter application.
// It sets up the MaterialApp and initializes the home page.
// The app uses a ValueNotifier for theme management and includes the main home page with job listings
// and a settings page for user preferences.
// The home page fetches job listings from the ScrapingService and displays them in a list

import 'package:flutter/material.dart';
import 'package:mostaql_job_finder/job_details_page.dart';
import 'package:mostaql_job_finder/models/job.dart';
import 'package:mostaql_job_finder/services/scraping_service.dart';
import 'package:mostaql_job_finder/settings_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

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
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          home: const MyHomePage(),
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
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _selectedCategory;

  final List<String> _categories = [
    'أعمال وخدمات استشارية',
    'برمجة، تطوير المواقع والتطبيقات',
    'هندسة، عمارة وتصميم داخلي',
    'تصميم، فيديو وصوتيات',
    'تسويق إلكتروني ومبيعات',
    'كتابة، تحرير، ترجمة ولغات',
    'دعم، مساعدة وإدخال بيانات',
    'تدريب وتعليم عن بعد',
  ];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs({String? category}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jobs = await _scrapingService.fetchJobs(category: category);
      setState(() {
        _jobs = jobs;
        _filteredJobs = jobs;
      });
    } catch (e) {
      // Handle error
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch jobs: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterJobs(String query) {
    setState(() {
      _searchQuery = query;
      _filteredJobs = _jobs
          .where((job) =>
              job.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                onChanged: _filterJobs,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
              )
            : const Text('Mostaql Job Finder'),
        actions: [
          _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _filteredJobs = _jobs;
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedCategory,
              hint: const Text('Select Category', style: TextStyle(color: Colors.white)),
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                  _fetchJobs(category: _selectedCategory);
                });
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 100,
                                height: 16,
                                color: Colors.white,
                              ),
                              Container(
                                width: 50,
                                height: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 70,
                                height: 16,
                                color: Colors.white,
                              ),
                              Container(
                                width: 80,
                                height: 36,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchJobs(category: _selectedCategory),
              child: ListView.builder(
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
                    child: Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              job.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('By: ${job.author}'),
                                Text(job.postTime),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${job.offerCount} offers'),
                                ElevatedButton(
                                  onPressed: () => _launchURL(job.url),
                                  child: const Text('View Job'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
