import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/lead.dart';
import '../models/custom_field.dart';
import '../models/field_group.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

enum LeadLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class LeadProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  LeadLoadingState _loadingState = LeadLoadingState.initial;
  List<Lead> _leads = [];
  Lead? _currentLead;
  String? _error;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;
  
  // Filters
  LeadStatus? _statusFilter;

  // Getters
  LeadLoadingState get loadingState => _loadingState;
  List<Lead> get leads => _leads;
  Lead? get currentLead => _currentLead;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  LeadStatus? get statusFilter => _statusFilter;

  // Fetch leads with optional filters
  Future<void> fetchLeads({
    LeadStatus? status,
    int page = 1,
    bool loadMore = false,
  }) async {
    if (!loadMore) {
      _loadingState = LeadLoadingState.loading;
      _leads = [];
      _currentPage = 1;
    }
    
    _error = null;
    notifyListeners();

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': AppConfig.defaultPageSize.toString(),
    };

    if (status != null) {
      queryParams['status'] = status.value;
    }

    try {
      // Build query parameters
      final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.leadsEndpoint}')
          .replace(queryParameters: queryParams);
      
      print('=== API REQUEST DEBUG ===');
      print('Request URL: $uri');
      
      // Get headers with auth token from ApiService
      final headers = await _apiService.getHeaders();
      
      // Make HTTP request directly to get full response
      final httpResponse = await http.get(uri, headers: headers)
          .timeout(Duration(seconds: AppConfig.apiTimeout));
      
      print('=== API RESPONSE DEBUG ===');
      print('Status code: ${httpResponse.statusCode}');
      print('Response body: ${httpResponse.body}');
      
      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        final responseBody = jsonDecode(httpResponse.body) as Map<String, dynamic>;
        
        print('Response body keys: ${responseBody.keys}');
        print('Data type: ${responseBody['data'].runtimeType}');
        
        // Parse as PaginatedResponse
        final paginatedResponse = PaginatedResponse<Lead>.fromJson(
          responseBody,
          (json) => Lead.fromJson(json),
        );

        if (loadMore) {
          _leads.addAll(paginatedResponse.data);
        } else {
          _leads = paginatedResponse.data;
        }

        _currentPage = paginatedResponse.pagination.page;
        _totalPages = paginatedResponse.pagination.totalPages;
        _hasMore = paginatedResponse.pagination.hasNext;
        _loadingState = LeadLoadingState.loaded;
      } else {
        final errorBody = jsonDecode(httpResponse.body) as Map<String, dynamic>;
        _error = errorBody['error'] as String? ?? 'Failed to fetch leads';
        _loadingState = LeadLoadingState.error;
      }
    } on SocketException {
      _error = 'No internet connection';
      _loadingState = LeadLoadingState.error;
    } on HttpException {
      _error = 'Server error';
      _loadingState = LeadLoadingState.error;
    } catch (e, stackTrace) {
      print('=== ERROR DEBUG ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      _error = 'An error occurred: ${e.toString()}';
      _loadingState = LeadLoadingState.error;
    }

    notifyListeners();
  }

  // Load more leads (pagination)
  Future<void> loadMoreLeads() async {
    if (_hasMore && _loadingState != LeadLoadingState.loading) {
      await fetchLeads(
        status: _statusFilter,
        page: _currentPage + 1,
        loadMore: true,
      );
    }
  }

  // Set status filter
  void setStatusFilter(LeadStatus? status) {
    _statusFilter = status;
    fetchLeads(status: status);
  }

  // Refresh leads
  Future<void> refreshLeads() async {
    await fetchLeads(status: _statusFilter);
  }

  // Fetch single lead by ID
  Future<void> fetchLeadById(String id) async {
    _loadingState = LeadLoadingState.loading;
    _error = null;
    notifyListeners();

    final response = await _apiService.get<Lead>(
      '${AppConfig.leadsEndpoint}/$id',
      fromJson: (data) => Lead.fromJson(data as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      _currentLead = response.data;
      _loadingState = LeadLoadingState.loaded;
      
      // Update the lead in the list if it exists
      final index = _leads.indexWhere((l) => l.id == id);
      if (index != -1) {
        _leads[index] = response.data!;
      }
    } else {
      _error = response.error ?? 'Failed to fetch lead';
      _loadingState = LeadLoadingState.error;
    }

    notifyListeners();
  }

  // Update lead
  Future<bool> updateLead(String id, Map<String, dynamic> updates) async {
    _error = null;

    final response = await _apiService.put<Lead>(
      '${AppConfig.leadsEndpoint}/$id',
      body: updates,
      fromJson: (data) => Lead.fromJson(data as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      _currentLead = response.data;
      
      // Update the lead in the list
      final index = _leads.indexWhere((l) => l.id == id);
      if (index != -1) {
        _leads[index] = response.data!;
      }
      
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to update lead';
      notifyListeners();
      return false;
    }
  }

  // Create new lead
  Future<bool> createLead(Map<String, dynamic> leadData) async {
    _error = null;

    final response = await _apiService.post<Lead>(
      AppConfig.leadsEndpoint,
      body: leadData,
      fromJson: (data) => Lead.fromJson(data as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      // Add the new lead to the top of the list
      _leads.insert(0, response.data!);
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to create lead';
      notifyListeners();
      return false;
    }
  }

  // Add comment to lead
  Future<bool> addComment(String leadId, String comment) async {
    _error = null;

    final response = await _apiService.post<Lead>(
      '${AppConfig.leadsEndpoint}/$leadId/comments',
      body: {'comment': comment},
      fromJson: (data) => Lead.fromJson(data as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      _currentLead = response.data;
      
      // Update the lead in the list
      final index = _leads.indexWhere((l) => l.id == leadId);
      if (index != -1) {
        _leads[index] = response.data!;
      }
      
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to add comment';
      notifyListeners();
      return false;
    }
  }

  // Custom Fields
  List<CustomField> _customFields = [];
  List<CustomField> get customFields => _customFields;

  Future<void> fetchCustomFields() async {
    final response = await _apiService.get<List<CustomField>>(
      '/settings/custom-fields',
      fromJson: (data) => (data as List).map((e) => CustomField.fromJson(e)).toList(),
    );

    if (response.success && response.data != null) {
      _customFields = response.data!;
      notifyListeners();
    }
  }

  // Field Groups
  List<FieldGroup> _fieldGroups = [];
  List<FieldGroup> get fieldGroups => _fieldGroups;

  Future<void> fetchFieldGroups() async {
    final response = await _apiService.get<List<FieldGroup>>(
      '/settings/field-groups',
      fromJson: (data) => (data as List).map((e) => FieldGroup.fromJson(e)).toList(),
    );

    if (response.success && response.data != null) {
      _fieldGroups = response.data!;
      // Sort by order
      _fieldGroups.sort((a, b) => a.order.compareTo(b.order));
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear current lead
  void clearCurrentLead() {
    _currentLead = null;
    notifyListeners();
  }
}
