import 'package:flutter/material.dart';
import 'package:campus_lift/core/theme/app_colors.dart';
import '../../widgets/campus_lift_logo.dart';

class College {
  final String id;
  final String name;
  final String location;

  College({required this.id, required this.name, required this.location});
}

class CollegeSelectionScreen extends StatefulWidget {
  final Function(College) onCollegeSelected;

  const CollegeSelectionScreen({super.key, required this.onCollegeSelected});

  @override
  State<CollegeSelectionScreen> createState() => _CollegeSelectionScreenState();
}

class _CollegeSelectionScreenState extends State<CollegeSelectionScreen> {
  late TextEditingController _searchController;
  College? _selectedCollege;

  final List<College> _colleges = [
    College(id: '1', name: 'COEP Technological University (COEP)', location: 'Shivajinagar, Pune'),
    College(id: '2', name: 'Pune Institute of Computer Technology (PICT)', location: 'Dhankawadi, Pune'),
    College(id: '3', name: 'Vishwakarma Institute of Technology (VIT)', location: 'Bibwewadi, Pune'),
    College(id: '4', name: 'MIT World Peace University (MIT WPU)', location: 'Kothrud, Pune'),
    College(id: '5', name: 'Symbiosis International University', location: 'Senapati Bapat Road / Lavale, Pune'),
    College(id: '6', name: 'Cummins College of Engineering for Women', location: 'Karvenagar, Pune'),
    College(id: '7', name: 'Army Institute of Technology (AIT)', location: 'Dighi, Pune'),
    College(id: '8', name: 'JSPM Rajarshi Shahu College of Engineering', location: 'Tathawade, Pune'),
    College(id: '9', name: 'Pimpri Chinchwad College of Engineering (PCCOE)', location: 'Akurdi, Pune'),
    College(id: '10', name: 'Savitribai Phule Pune University (SPPU)', location: 'Ganeshkhind, Pune'),
  ];

  late List<College> _filteredColleges;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredColleges = _colleges;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterColleges(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredColleges = _colleges;
      } else {
        _filteredColleges = _colleges
            .where(
              (college) =>
                  college.name.toLowerCase().contains(query.toLowerCase()) ||
                  college.location.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const CampusLiftLogo(
          size: 24,
          showTagline: false,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterColleges,
              decoration: InputDecoration(
                hintText: 'Search college...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          // Colleges List
          Expanded(
            child: _filteredColleges.isEmpty
                ? Center(
                    child: Text(
                      'No colleges found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filteredColleges.length,
                    itemBuilder: (context, index) {
                      final college = _filteredColleges[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCollege = college;
                            });
                            widget.onCollegeSelected(college);
                            Navigator.pop(context);
                          },
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Logo Placeholder
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        college.name
                                            .substring(0, 2)
                                            .toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // College Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          college.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          college.location,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Selection Indicator
                                  if (_selectedCollege?.id == college.id)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                    )
                                  else
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.borderGrey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
