// lib/main.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mostaql_job_finder/models/filter_model.dart';
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
              backgroundColor: Colors.transparent, elevation: 0,
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
              backgroundColor: Colors.transparent, elevation: 0,
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
  bool _isApplyingAdvancedFilters = false;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
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
      final jobs = await _scrapingService.fetchJobs(category: category);
      setState(() {
        _jobs = jobs;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch jobs: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyFilters() async {
    if (_activeFilters.areAdvancedFiltersActive && !_isLoading) {
      setState(() => _isApplyingAdvancedFilters = true);
    }

    List<Job> tempFiltered = _jobs.where((job) {
      final searchMatch = _searchController.text.isEmpty || job.title.toLowerCase().contains(_searchController.text.toLowerCase());
      final offerMatch = switch (_activeFilters.offerRange) {
        OfferRange.lessThan5 => job.offerCount < 5,
        OfferRange.from5to10 => job.offerCount >= 5 && job.offerCount <= 10,
        OfferRange.from10to20 => job.offerCount >= 10 && job.offerCount <= 20,
        OfferRange.moreThan20 => job.offerCount > 20,
        _ => true,
      };
      return searchMatch && offerMatch;
    }).toList();

    if (_activeFilters.areAdvancedFiltersActive) {
      final jobsToDetail = tempFiltered.take(15).toList();
      final futures = jobsToDetail.map((job) => _scrapingService.fetchJobDetails(job.url).catchError((e) => job)).toList();
      
      final detailedJobs = await Future.wait(futures);
      
      Map<String, Job> detailedJobsMap = {for (var j in detailedJobs) j.url: j};

      for (int i = 0; i < tempFiltered.length; i++) {
        if (detailedJobsMap.containsKey(tempFiltered[i].url)) {
           final detailedJob = detailedJobsMap[tempFiltered[i].url]!;
           tempFiltered[i] = tempFiltered[i].copyWith(
              budget: detailedJob.budget,
              employerHiringRate: detailedJob.employerHiringRate,
           );
        }
      }

      tempFiltered = tempFiltered.where((job) {
        final hiringRateMatch = switch (_activeFilters.hiringRate) {
          HiringRate.moreThan0 => job.parsedEmployerHiringRate != null && job.parsedEmployerHiringRate! > 0,
          HiringRate.moreThan50 => job.parsedEmployerHiringRate != null && job.parsedEmployerHiringRate! >= 50,
          HiringRate.moreThan75 => job.parsedEmployerHiringRate != null && job.parsedEmployerHiringRate! >= 75,
          _ => true,
        };
        if (_activeFilters.hiringRate != HiringRate.any && job.parsedEmployerHiringRate == null) {
          return false;
        }

        final budgetMatch = job.parsedBudget == null || 
                            (_activeFilters.budget.end == 2000 ? job.parsedBudget! >= _activeFilters.budget.start : 
                            (job.parsedBudget! >= _activeFilters.budget.start && job.parsedBudget! <= _activeFilters.budget.end));
        if ((_activeFilters.budget.start != 0 || _activeFilters.budget.end != 2000) && job.parsedBudget == null) {
          return false;
        }

        return hiringRateMatch && budgetMatch;
      }).toList();
    }

    setState(() {
      _filteredJobs = tempFiltered;
      _isApplyingAdvancedFilters = false;
    });
  }

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
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Filters", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                TextButton(onPressed: () {
                                  setModalState(() => _activeFilters = JobFilters());
                                }, child: const Text("Reset"))
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                const Text("Budget (USD)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                RangeSlider(
                                  values: _activeFilters.budget,
                                  min: 0,
                                  max: 2000,
                                  divisions: 40,
                                  labels: RangeLabels(
                                    '\${_activeFilters.budget.start.round()}',
                                    _activeFilters.budget.end == 2000 ? '\$2000+' : '\${_activeFilters.budget.end.round()}'
                                  ),
                                  onChanged: (values) => setModalState(() => _activeFilters.budget = values),
                                ),
                                const SizedBox(height: 20),
                                
                                const Text("Number of Offers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                Wrap(
                                  spacing: 8.0,
                                  children: OfferRange.values.map((range) {
                                    final text = range.toString().split('.').last
                                        .replaceAll('from', '').replaceAll('to', '-').replaceAll('lessThan', '< ').replaceAll('moreThan', '> ');
                                    return ChoiceChip(
                                      label: Text(text),
                                      selected: _activeFilters.offerRange == range,
                                      onSelected: (selected) {
                                        if(selected) setModalState(() => _activeFilters.offerRange = range);
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),

                                const Text("Hiring Rate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                Wrap(
                                  spacing: 8.0,
                                  children: HiringRate.values.map((rate) {
                                    final text = rate.toString().split('.').last.replaceAll('moreThan', '> ') + '%';
                                    return ChoiceChip(
                                      label: Text(text),
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
                color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2))),
              ),
              child: AppBar(
                title: const Text('Mostaql Job Finder'),
                actions: [
                  IconButton(
                    icon: Icon(_activeFilters.isAnyFilterActive ? Icons.filter_alt : Icons.filter_alt_off_outlined),
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
      body: Stack(
        children: [
          Container(
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
                      ? const Center(child: Text("No jobs found with these criteria.", style: TextStyle(fontSize: 18)))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 130, bottom: 20),
                          itemCount: _filteredJobs.length,
                          itemBuilder: (context, index) {
                            return JobCard(job: _filteredJobs[index]);
                          },
                        ),
            ),
          ),
          if (_isApplyingAdvancedFilters)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Applying Advanced Filters...", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
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
      ),
    );
  }
}

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