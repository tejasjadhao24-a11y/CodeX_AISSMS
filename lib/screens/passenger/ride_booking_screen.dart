import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:campus_lift/core/theme/app_colors.dart';
import 'package:campus_lift/widgets/campus_lift_logo.dart';
import 'package:campus_lift/widgets/primary_button.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ride_provider.dart';
import '../../core/providers/user_provider.dart';

class RideBookingScreen extends StatefulWidget {
  final String? initialPickup;
  final String? initialDropoff;

  const RideBookingScreen({
    super.key,
    this.initialPickup,
    this.initialDropoff,
  });

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  late TextEditingController _pickupController;
  late TextEditingController _dropController;
  DateTime? _selectedDateTime;
  bool _isLoading = false;
  String _selectedGender = 'All'; // 'All', 'Female', 'Male'

  final List<String> campusPlaces = [
    'VIT Pune - Main Gate',
    'VIT Pune - Hostel Block A',
    'VIT Pune - Hostel Block B',
    'VIT Pune - Hostel Block C',
    'VIT Pune - Academic Block',
    'VIT Pune - Library',
    'VIT Pune - Cafeteria',
    'VIT Pune - Sports Complex',
    'Katraj',
    'Swargate',
    'Pune Station',
    'Shivajinagar',
    'Deccan',
    'Kothrud',
    'Hinjewadi',
    'Viman Nagar',
    'Kharadi',
    'Hadapsar',
    'Camp',
    'FC Road',
    'JM Road',
    'Baner',
    'Aundh',
    'Wakad',
    'Pimpri',
    'Chinchwad',
    'PCMC',
    'Nashik Phata',
  ];

  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController(text: widget.initialPickup ?? '');
    _dropController = TextEditingController(text: widget.initialDropoff ?? '');
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  Future<void> _requestRide() async {
    final fromLocation = _pickupController.text.trim();
    final toLocation = _dropController.text.trim();

    if (fromLocation.isEmpty || toLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both pickup and destination')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final success = await rideProvider.requestRide(
        fromLocation: fromLocation, 
        toLocation: toLocation, 
        fromLat: 18.4624, 
        fromLng: 73.8670, 
        toLat: 18.4700, 
        toLng: 73.8750, 
        scheduledTime: _selectedDateTime,
        genderPreference: _selectedGender == 'All' ? null : _selectedGender,
        userProvider: userProvider,
      ); 

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pushNamed(
          '/ride-waiting',
          arguments: {
            'fromLocation': fromLocation,
            'toLocation': toLocation,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(rideProvider.errorMessage ?? 'Failed to request ride')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Input Card
              Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Leaving From
                        Autocomplete<String>(
                          initialValue: TextEditingValue(text: _pickupController.text),
                          optionsBuilder: (TextEditingValue value) {
                            if (value.text.isEmpty) return const Iterable<String>.empty();
                            return campusPlaces.where((place) =>
                                place.toLowerCase().contains(value.text.toLowerCase()));
                          },
                          onSelected: (String selection) {
                            _pickupController.text = selection;
                          },
                          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                            // Sync the Autocomplete controller with our state controller
                            if (controller.text != _pickupController.text && _pickupController.text.isNotEmpty) {
                              controller.text = _pickupController.text;
                            }
                            controller.addListener(() {
                               _pickupController.text = controller.text;
                            });
                            
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onSubmitted: (_) => onSubmitted(),
                              decoration: InputDecoration(
                                labelText: 'Leaving From',
                                hintText: 'Enter pickup location',
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return _buildAutocompleteOptions(context, onSelected, options);
                          },
                        ),
                        const Divider(height: 1, color: AppColors.borderGrey),
                        // Going To
                        Autocomplete<String>(
                          initialValue: TextEditingValue(text: _dropController.text),
                          optionsBuilder: (TextEditingValue value) {
                            if (value.text.isEmpty) return const Iterable<String>.empty();
                            return campusPlaces.where((place) =>
                                place.toLowerCase().contains(value.text.toLowerCase()));
                          },
                          onSelected: (String selection) {
                            _dropController.text = selection;
                          },
                          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                            // Sync
                            if (controller.text != _dropController.text && _dropController.text.isNotEmpty) {
                              controller.text = _dropController.text;
                            }
                            controller.addListener(() {
                               _dropController.text = controller.text;
                            });

                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onSubmitted: (_) => onSubmitted(),
                              decoration: InputDecoration(
                                labelText: 'Going To',
                                hintText: 'Enter destination',
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return _buildAutocompleteOptions(context, onSelected, options);
                          },
                        ),
                        const Divider(height: 1, color: AppColors.borderGrey),
                        // Date & Time
                        InkWell(
                          onTap: _selectDateTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.calendar_today_outlined,
                                    color: AppColors.accentBlue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date & Time',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                      ),
                                      Text(
                                        _selectedDateTime == null 
                                            ? 'Now' 
                                            : '${_selectedDateTime!.day}/${_selectedDateTime!.month} ${_selectedDateTime!.hour}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.borderGrey),
                        // Passengers
                        InkWell(
                          onTap: () {
                            // TODO: Implement passenger selector
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.people_outlined,
                                    color: AppColors.ecoGreen,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Passengers',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                      ),
                                      Text(
                                        '1 passenger', // TODO: Show selected count
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.borderGrey),
                        // Driver Preference
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    child: const Icon(
                                      Icons.wc_outlined,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Driver Preference',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.textMuted,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedGender == 'All'
                                              ? 'All Drivers'
                                              : '$_selectedGender Only',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    _buildGenderChip('All', 'All Drivers'),
                                    const SizedBox(width: 8),
                                    _buildGenderChip('Female', 'Female Only'),
                                    const SizedBox(width: 8),
                                    _buildGenderChip('Male', 'Male Only'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.1, end: 0, duration: 400.ms),
              const SizedBox(height: 32),
              // Find Ride Button
              PrimaryButton(
                text: 'Find Ride',
                onPressed: _requestRide,
                isLoading: _isLoading,
                height: 60,
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.1, end: 0, duration: 500.ms),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderChip(String value, String label) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        if (_selectedGender != value) {
          setState(() {
            _selectedGender = value;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderGrey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAutocompleteOptions(BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width - 96,
          constraints: const BoxConstraints(maxHeight: 250),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderGrey),
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return ListTile(
                leading: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                title: Text(option, style: const TextStyle(fontWeight: FontWeight.w500)),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }
}
