import 'package:flutter/material.dart';
import '../services/home_service.dart';

class HomeProvider extends ChangeNotifier {
  final HomeService _homeService = HomeService();

  bool _isLoading = false;
  String? _error;

  // User data
  String _userName = '';
  String? _userImage;
  double _rating = 0.0;
  int _reviewCount = 0;

  // Stats data
  int _earnings = 0;
  double _earningsChange = 0.0;
  int _bookings = 0;
  double _bookingsChange = 0.0;

  // Bookings list
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _pastBookings = [];

  // Date range
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _dateRangeText = '';
  String _selectedDateRange = 'This Month'; // Track selected option

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get userName => _userName;
  String? get userImage => _userImage;
  double get rating => _rating;
  int get reviewCount => _reviewCount;
  int get earnings => _earnings;
  double get earningsChange => _earningsChange;
  int get bookings => _bookings;
  double get bookingsChange => _bookingsChange;
  List<Map<String, dynamic>> get bookingsList => _upcomingBookings;
  List<Map<String, dynamic>> get pastBookingsList => _pastBookings;
  String get dateRangeText => _dateRangeText;
  String get selectedDateRange => _selectedDateRange;

  // Fetch all home data
  Future<void> fetchHomeData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Set default date range to this month if not already set
      if (_selectedDateRange == 'This Month') {
        final monthRange = HomeService.getThisMonthRange();
        _startDate = monthRange.start;
        _endDate = monthRange.end;
        _dateRangeText = HomeService.formatDateRange(_startDate, _endDate);
      }

      // Fetch user profile
      final userProfile = await _homeService.getUserProfile();
      _userName = userProfile['profileName'] ?? userProfile['name'] ?? '';

      // Get first display image if available
      if (userProfile['displayImage'] != null &&
          userProfile['displayImage'] is List &&
          (userProfile['displayImage'] as List).isNotEmpty) {
        _userImage = userProfile['displayImage'][0];
      } else {
        _userImage = null;
      }

      _rating = (userProfile['averageRating'] ?? 0).toDouble();
      _reviewCount = userProfile['totalReviews'] ?? 0;

      // Fetch bookings
      final bookingsResponse = await _homeService.getBookings(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (bookingsResponse['success'] == true && bookingsResponse['bookings'] != null) {
        final bookingsData = bookingsResponse['bookings'];

        _upcomingBookings = List<Map<String, dynamic>>.from(
            bookingsData['upcoming'] ?? []
        );

        _pastBookings = List<Map<String, dynamic>>.from(
            bookingsData['past'] ?? []
        );
      } else {
        _upcomingBookings = [];
        _pastBookings = [];
      }

      // Calculate stats
      _calculateStats();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate earnings and bookings stats
  void _calculateStats() {
    // Calculate earnings from completed bookings
    int currentEarnings = 0;
    for (var booking in [..._upcomingBookings, ..._pastBookings]) {
      if (booking['status'] == 'completed') {
        currentEarnings += (booking['amountDeducted'] ?? 0) as int;
      }
    }
    _earnings = currentEarnings;

    // TODO: Calculate earnings change percentage
    // This would require previous period data for comparison
    _earningsChange = 0.0;

    // Calculate total bookings
    int currentBookings = _upcomingBookings.length + _pastBookings.length;
    _bookings = currentBookings;

    // TODO: Calculate bookings change percentage
    // This would require previous period data for comparison
    _bookingsChange = 0.0;
  }

  // Refresh data
  Future<void> refreshData() async {
    await fetchHomeData();
  }

  // Update date range based on selection
  Future<void> updateDateRangeByOption(String option) async {
    _selectedDateRange = option;
    final now = DateTime.now();

    switch (option) {
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
        _endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;

      case 'Last Week':
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        _startDate = now.subtract(const Duration(days: 7));
        _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
        break;

      case 'Last Month':
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final lastMonthDate = DateTime(now.year, now.month - 1, now.day);
        _startDate = DateTime(lastMonthDate.year, lastMonthDate.month, lastMonthDate.day, 0, 0, 0);
        break;

      case 'This Month':
      default:
        final monthRange = HomeService.getThisMonthRange();
        _startDate = monthRange.start;
        _endDate = monthRange.end;
        break;
    }

    _dateRangeText = HomeService.formatDateRange(_startDate, _endDate);
    notifyListeners();

    // Fetch new data with updated date range
    await fetchHomeData();
  }

  // Update date range and refresh data (keep for backward compatibility)
  Future<void> updateDateRange(DateTime start, DateTime end) async {
    _startDate = start;
    _endDate = end;
    _dateRangeText = HomeService.formatDateRange(start, end);
    _selectedDateRange = 'Custom'; // Mark as custom if manually set
    notifyListeners();

    await fetchHomeData();
  }
}