import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../services/api_service.dart';

class CollegeInfoScreen extends StatefulWidget {
  const CollegeInfoScreen({super.key});

  @override
  State<CollegeInfoScreen> createState() => _CollegeInfoScreenState();
}

class _CollegeInfoScreenState extends State<CollegeInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  bool _isLoading = true;
  bool _isSaving = false;

  final _collegeNameController = TextEditingController(text: "Vishwakarma Institute of Technology, Pune");
  final _prnController = TextEditingController();
  final _branchController = TextEditingController();
  final _divisionController = TextEditingController();
  String? _selectedCourse;
  String? _selectedYearOfStudy;

  @override
  void initState() {
    super.initState();
    _loadCollegeData();
  }

  @override
  void dispose() {
    _collegeNameController.dispose();
    _prnController.dispose();
    _branchController.dispose();
    _divisionController.dispose();
    super.dispose();
  }

  Future<void> _loadCollegeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get('/users/profile');
      if (response != null && mounted) {
        setState(() {
          if (response['collegeName'] != null && response['collegeName'].toString().isNotEmpty) {
            _collegeNameController.text = response['collegeName'];
          } else if (response['college_name'] != null && response['college_name'].toString().isNotEmpty) {
            _collegeNameController.text = response['college_name'];
          }
          
          _prnController.text = response['prn'] ?? '';
          _branchController.text = response['branch'] ?? '';
          _divisionController.text = response['division'] ?? '';
          
          // Match course dropdown values safely
          final courseVal = response['course'];
          if (courseVal != null && const ['B.Tech', 'M.Tech', 'MBA', 'MCA', 'BCA', 'B.Sc', 'M.Sc', 'Other'].contains(courseVal)) {
            _selectedCourse = courseVal;
          }
          
          // Match year of study dropdown values safely
          final yearVal = response['yearOfStudy'] ?? response['year_of_study'];
          if (yearVal != null && const ['1st', '2nd', '3rd', '4th'].contains(yearVal)) {
            _selectedYearOfStudy = yearVal;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load college details: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveCollegeInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final patchData = {
      'collegeName': _collegeNameController.text.trim(),
      'prn': _prnController.text.trim(),
      'course': _selectedCourse,
      'branch': _branchController.text.trim(),
      'yearOfStudy': _selectedYearOfStudy,
      'division': _divisionController.text.trim(),
    };

    try {
      await _apiService.patch('/users/profile', patchData);
      
      // Update local state in UserProvider
      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false).loadUser();
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('College information updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: const Text(
          'College Information',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // College Name Field
                          TextFormField(
                            controller: _collegeNameController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your college name';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'College Name',
                              prefixIcon: const Icon(Icons.school_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // PRN Number Field
                          TextFormField(
                            controller: _prnController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your PRN / Student ID';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'PRN Number',
                              prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Course Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCourse,
                            items: const [
                              DropdownMenuItem(value: 'B.Tech', child: Text('B.Tech')),
                              DropdownMenuItem(value: 'M.Tech', child: Text('M.Tech')),
                              DropdownMenuItem(value: 'MBA', child: Text('MBA')),
                              DropdownMenuItem(value: 'MCA', child: Text('MCA')),
                              DropdownMenuItem(value: 'BCA', child: Text('BCA')),
                              DropdownMenuItem(value: 'B.Sc', child: Text('B.Sc')),
                              DropdownMenuItem(value: 'M.Sc', child: Text('M.Sc')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCourse = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select your course';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Course',
                              prefixIcon: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Branch Field
                          TextFormField(
                            controller: _branchController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your branch';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Branch',
                              prefixIcon: const Icon(Icons.account_tree_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Year of Study Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedYearOfStudy,
                            items: const [
                              DropdownMenuItem(value: '1st', child: Text('1st Year')),
                              DropdownMenuItem(value: '2nd', child: Text('2nd Year')),
                              DropdownMenuItem(value: '3rd', child: Text('3rd Year')),
                              DropdownMenuItem(value: '4th', child: Text('4th Year')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedYearOfStudy = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select your year of study';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Year of Study',
                              prefixIcon: const Icon(Icons.date_range_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Division Field
                          TextFormField(
                            controller: _divisionController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your division';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Division',
                              prefixIcon: const Icon(Icons.grid_3x3_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveCollegeInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
