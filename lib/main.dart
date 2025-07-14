// lib/main.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mostaql_job_finder/job_details_page.dart';
import 'package:mostaql_job_finder/models/filter_model.dart';
import 'package:mostaql_job_finder/models/job.dart';
import 'package:mostaql_job_finder/services/scraping_service.dart';
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
            cardColor: Colors.white.withAlpha((0.7 * 255).round()),
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
            cardColor: Colors.black.withAlpha((0.5 * 255).round()),
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

  // --- NEW: State for filters ---
  JobFilters _activeFilters = JobFilters();

  final List<String> _categories = [
    'أعمال وخدمات استشارية', 'برمجة، تطوير المواقع والتطبيقات', 'هندسة، عمارة وتصميم داخلي',
    'تصميم، فيديو وصوتيات', 'تسويق إلكتروني ومبيعات', 'كتابة، تحرير، ترجمة ولغات',
    'دعم، مساعدة وإدخال بيانات', 'تدريب وتعليم عن بعد',
  ];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _searchController.addListener(_applyFilters);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs({String? category}) async {
    setState(() => _isLoading = true);
    try {
      // We fetch all jobs first, then apply filters client-side.
      // This is necessary because the website doesn't support API-level filtering for these new criteria.
      final jobs = await _scrapingService.fetchJobs(category: category);
      setState(() {
        _jobs = jobs;
        // After fetching, apply any active filters.
        _applyFilters();
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

  // --- NEW: Updated filtering logic ---
  void _applyFilters() {
    List<Job> filtered = List.from(_jobs);

    // Apply search query
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((job) {
        return job.title.toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
    }

    // Apply Offer Range Filter
    filtered = filtered.where((job) {
      switch (_activeFilters.offerRange) {
        case OfferRange.lessThan5:
          return job.offerCount < 5;
        case OfferRange.from5to10:
          return job.offerCount >= 5 && job.offerCount <= 10;
        case OfferRange.from10to20:
          return job.offerCount >= 10 && job.offerCount <= 20;
        case OfferRange.moreThan20:
          return job.offerCount > 20;
        case OfferRange.any:
        default:
          return true;
      }
    }).toList();
    
    // Apply Hiring Rate Filter
    filtered = filtered.where((job) {
      switch (_activeFilters.hiringRate) {
        case HiringRate.moreThan0:
          return job.parsedEmployerHiringRate != null && job.parsedEmployerHiringRate! > 0;
        case HiringRate.moreThan50:
          return job.parsedEmployerHiringRate != null && job.parsedEmployerHiringRate! >= 50;
        case HiringRate.moreThan75:
          return job.parsedEmployerHiringRate != null && job.parsedEmployerHiringRate! >= 75;
        case HiringRate.any:
        default:
          return true;
      }
    }).toList();

    // Apply Budget Filter
    filtered = filtered.where((job) {
      return (job.parsedBudget == null || 
              (job.parsedBudget! >= _activeFilters.budget.start && 
               job.parsedBudget! <= _activeFilters.budget.end));
    }).toList();

    setState(() => _filteredJobs = filtered);
  }

  // --- NEW: Method to show the filter sheet ---
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, scrollController) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        children: [
                          // Sheet Header
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Filters", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                TextButton(onPressed: () {
                                  setModalState(() => _activeFilters = JobFilters());
                                  _applyFilters();
                                }, child: const Text("Reset"))
                              ],
                            ),
                          ),
                          // Filter Options
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                // Budget Filter (Demonstration)
                                const Text("Budget (USD)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                RangeSlider(
                                  values: _activeFilters.budget,
                                  min: 0,
                                  max: 5000,
                                  divisions: 10,
                                  labels: RangeLabels('\${_activeFilters.budget.start.round()}', '\${_activeFilters.budget.end.round()}'),
                                  onChanged: (values) => setModalState(() => _activeFilters.budget = values),
                                ),
                                const SizedBox(height: 20),
                                
                                // Offer Count Filter
                                const Text("Number of Offers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                Wrap(
                                  spacing: 8.0,
                                  children: OfferRange.values.map((range) {
                                    return ChoiceChip(
                                      label: Text(range.toString().split('.').last.replaceAll('from', '').replaceAll('to', '-') + (range == OfferRange.lessThan5 ? ' offers' : '')),
                                      selected: _activeFilters.offerRange == range,
                                      onSelected: (selected) {
                                        if(selected) setModalState(() => _activeFilters.offerRange = range);
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),

                                // Hiring Rate Filter (Demonstration)
                                const Text("Hiring Rate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                Wrap(
                                  spacing: 8.0,
                                  children: HiringRate.values.map((rate) {
                                    return ChoiceChip(
                                      label: Text(rate.toString().split('.').last.replaceAll('moreThan', '> ') + '%'),
                                      selected: _activeFilters.hiringRate == rate,
                                      onSelected: (selected) {
                                        if(selected) setModalState(() => _activeFilters.hiringRate = rate);
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          // Apply Button
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  _applyFilters();
                                  Navigator.pop(context);
                                },
                                child: const Text("Apply Filters", style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
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
                color: theme.scaffoldBackgroundColor.withAlpha((0.5 * 255).round()),
                border: Border(bottom: BorderSide(color: Colors.white.withAlpha((0.2 * 255).round()))),
              ),
              child: AppBar(
                title: const Text('Mostaql Job Finder'),
                actions: [
                  // --- NEW: Filter Button ---
                  IconButton(
                    icon: Icon(_activeFilters.isAnyFilterActive ? Icons.filter_list : Icons.filter_list_off),
                    onPressed: _showFilterSheet,
                  ),
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
                        return JobCard(job: _filteredJobs[index]);
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
        fillColor: theme.cardColor.withAlpha((0.5 * 255).round()),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor.withAlpha((0.5 * 255).round()),
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
      baseColor: Colors.grey.shade500.withAlpha((0.5 * 255).round()),
      highlightColor: Colors.grey.shade200.withAlpha((0.5 * 255).round()),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 130),
        itemCount: 7,
        itemBuilder: (context, index) => const ShimmerJobCard(),
      ),
    );
  }
}

// Reusable Job Card Widget (Unchanged)
class JobCard extends StatelessWidget {
  final Job job;
  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => JobDetailsPage(job: job))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor.withAlpha((0.3 * 255).round()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha((0.2 * 255).round())),
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
      ),
    );
  }
}

// Shimmer Placeholder for the Job Card (Unchanged)
class ShimmerJobCard extends StatelessWidget {
  const ShimmerJobCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.2 * 255).round()),
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