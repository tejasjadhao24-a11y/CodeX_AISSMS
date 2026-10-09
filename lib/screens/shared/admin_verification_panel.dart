import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_lift/core/theme/app_colors.dart';
import 'package:campus_lift/services/socket_service.dart';

class Student {
  final String id;
  final String name;
  final String college;
  final String prn;
  final String status;
  final String email;

  Student({
    required this.id,
    required this.name,
    required this.college,
    required this.prn,
    required this.status,
    required this.email,
  });
}

class AdminVerificationPanel extends StatefulWidget {
  const AdminVerificationPanel({super.key});

  @override
  State<AdminVerificationPanel> createState() => _AdminVerificationPanelState();
}

class _AdminVerificationPanelState extends State<AdminVerificationPanel> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAdminSocket());
  }

  Future<void> _initAdminSocket() async {
    try {
      final socketService = Provider.of<SocketService>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      socketService.joinAdminRoom(token);
      socketService.onSosTriggered((data) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚨 SOS Alert received: User ${data['user_id']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      });
    } catch (e) {
      debugPrint('[AdminPanel] Error initializing admin socket: $e');
    }
  }

  @override
  void dispose() {
    try {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.leaveAdminRoom();
    } catch (_) {}
    super.dispose();
  }

  final List<Student> _pendingStudents = [
    Student(
      id: '1',
      name: 'Rajesh Kumar',
      college: 'IIT Delhi',
      prn: '2024001',
      status: 'Pending',
      email: 'rajesh@iitd.ac.in',
    ),
    Student(
      id: '2',
      name: 'Priya Sharma',
      college: 'Delhi University',
      prn: 'DU2024002',
      status: 'Pending',
      email: 'priya@du.ac.in',
    ),
    Student(
      id: '3',
      name: 'Arjun Singh',
      college: 'BITS Pilani',
      prn: 'BP2024003',
      status: 'Pending',
      email: 'arjun@bitspilani.ac.in',
    ),
  ];

  final List<Student> _approvedStudents = [
    Student(
      id: '4',
      name: 'Neha Verma',
      college: 'VIT Vellore',
      prn: 'VIT2024004',
      status: 'Approved',
      email: 'neha@vit.ac.in',
    ),
    Student(
      id: '5',
      name: 'Aditya Patel',
      college: 'NIT Trichy',
      prn: 'NIT2024005',
      status: 'Approved',
      email: 'aditya@nitt.ac.in',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Admin Verification Panel',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Pending (${_pendingStudents.length})',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _selectedTab == 0
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Approved',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _selectedTab == 1
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedTab == 0
                ? _buildPendingStudents()
                : _buildApprovedStudents(),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingStudents() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingStudents.length,
      itemBuilder: (context, index) {
        return _buildStudentCard(context, _pendingStudents[index], true);
      },
    );
  }

  Widget _buildApprovedStudents() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _approvedStudents.length,
      itemBuilder: (context, index) {
        return _buildStudentCard(context, _approvedStudents[index], false);
      },
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    Student student,
    bool isPending,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.college,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withValues(alpha: 0.1)
                        : AppColors.ecoGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    student.status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isPending ? Colors.orange : AppColors.ecoGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRN',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.prn,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Email',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 200,
                      child: Text(
                        student.email,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action Buttons
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _showRejectDialog(context, student);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.alertRed),
                      ),
                      child: Text(
                        'Reject',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.alertRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _approveStudent(context, student);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ecoGreen,
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _viewDetails(context, student);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderGrey),
                  ),
                  child: const Text('View Details'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _approveStudent(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve ${student.name}?'),
        content: const Text(
          'This student will gain access to CampusLift. An approval notification will be sent to their email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${student.name} has been approved'),
                  backgroundColor: AppColors.ecoGreen,
                ),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject ${student.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${student.name} has been rejected'),
                  backgroundColor: AppColors.alertRed,
                ),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _viewDetails(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name:', student.name),
              _buildDetailRow('Email:', student.email),
              _buildDetailRow('College:', student.college),
              _buildDetailRow('PRN:', student.prn),
              _buildDetailRow('Status:', student.status),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.ecoGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Status: Verified Student\n'
                  'Document Verified: Yes\n'
                  'Submitted: 2024-03-05',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
