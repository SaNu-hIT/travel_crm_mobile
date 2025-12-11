import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../models/lead.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lead_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/lead_card.dart';

class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({super.key});

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  final RefreshController _refreshController = RefreshController();
  bool _showingGrid = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeadProvider>(context, listen: false).fetchLeads();
    });
    
    // Add search listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);
    await leadProvider.refreshLeads();
    _refreshController.refreshCompleted();
  }

  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _handleStatusCardTap(LeadStatus? status) {
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);
    leadProvider.setStatusFilter(status);
    setState(() {
      _showingGrid = false;
    });
  }

  void _handleBackToGrid() {
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);
    leadProvider.setStatusFilter(null);
    setState(() {
      _showingGrid = true;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _handleViewAllLeads() {
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);
    leadProvider.setStatusFilter(null);
    setState(() {
      _showingGrid = false;
    });
  }

  void _handleViewAllStatus() {
    Navigator.of(context).pushNamed('/all-status');
  }

  Map<LeadStatus, int> _getStatusCounts(LeadProvider leadProvider) {
    final counts = <LeadStatus, int>{};
    for (var status in LeadStatus.values) {
      counts[status] = leadProvider.leads
          .where((lead) => lead.status == status)
          .length;
    }
    return counts;
  }

  List<Lead> _getFilteredLeads(LeadProvider leadProvider) {
    var leads = leadProvider.leads;
    
    // Apply status filter
    if (leadProvider.statusFilter != null) {
      leads = leads.where((lead) => lead.status == leadProvider.statusFilter).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      leads = leads.where((lead) {
        return lead.name.toLowerCase().contains(_searchQuery) ||
               lead.phone.toLowerCase().contains(_searchQuery) ||
               (lead.email?.toLowerCase().contains(_searchQuery) ?? false) ||
               (lead.preferredLocation?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
    
    return leads;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final leadProvider = Provider.of<LeadProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        if (!_showingGrid) {
          _handleBackToGrid();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _showingGrid
            ? _buildDashboard(authProvider, leadProvider)
            : _buildLeadsList(leadProvider),
      ),
    );
  }

  Widget _buildDashboard(AuthProvider authProvider, LeadProvider leadProvider) {
    if (leadProvider.loadingState == LeadLoadingState.loading &&
        leadProvider.leads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final statusCounts = _getStatusCounts(leadProvider);
    final totalLeads = leadProvider.leads.length;
    final newLeads = statusCounts[LeadStatus.NEW] ?? 0;
    final followUpLeads = statusCounts[LeadStatus.FOLLOWUP] ?? 0;
    final bookedLeads = statusCounts[LeadStatus.BOOKED] ?? 0;

    return material.RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.accent2.withOpacity(0.3),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Profile Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              authProvider.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authProvider.user?.name ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  authProvider.user?.email ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded),
                            onPressed: _handleLogout,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      const Text(
                        'Track and Manage\nYour Leads',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Search Bar
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showingGrid = false;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: AbsorbPointer(
                            child: TextField(
                              enabled: false,
                              decoration: InputDecoration(
                                hintText: 'Search leads...',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary.withOpacity(0.5),
                                ),
                                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Metrics Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildMetricCard(
                      'Total Leads',
                      totalLeads.toString(),
                      Icons.people_outline,
                      AppColors.primary,
                      '+0%',
                    ),
                    _buildMetricCard(
                      'New Leads',
                      newLeads.toString(),
                      Icons.fiber_new,
                      Colors.blue,
                      '+12%',
                    ),
                    _buildMetricCard(
                      'Follow Ups',
                      followUpLeads.toString(),
                      Icons.schedule,
                      Colors.orange,
                      '+5%',
                    ),
                    _buildMetricCard(
                      'Booked',
                      bookedLeads.toString(),
                      Icons.check_circle_outline,
                      AppColors.success,
                      '+8%',
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                const SizedBox(height: 24),
                
                // Lead Status Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lead Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: _handleViewAllStatus,
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Status Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12, // Standardized to 12
                    mainAxisSpacing: 12,  // Standardized to 12
                    childAspectRatio: 1.6,
                  ),
                  itemCount: 4, // Show only top 4 statuses
                  itemBuilder: (context, index) {
                    final statuses = [
                      LeadStatus.NEW,
                      LeadStatus.FOLLOWUP,
                      LeadStatus.INTERESTED,
                      LeadStatus.BOOKED,
                    ];
                    final status = statuses[index];
                    final count = statusCounts[status] ?? 0;
                    return _buildStatusCard(status, count);
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Recent Leads
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Leads',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: _handleViewAllLeads,
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Recent Leads List
                if (leadProvider.leads.isEmpty)
                  if (leadProvider.loadingState == LeadLoadingState.loading)
                     const Center(child: Padding(
                       padding: EdgeInsets.all(20.0),
                       child: CircularProgressIndicator(),
                     ))
                  else
                    Container(
                      padding: const EdgeInsets.all(30),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No recent leads',
                            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    )
                else
                  ...leadProvider.leads.take(5).map((lead) => GestureDetector(
                    onTap: () => _handleLeadTap(lead),
                    child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: lead.status.color.withOpacity(0.2),
                        child: Text(
                          lead.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: lead.status.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        lead.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(LeadStatus status, int count) {
    return GestureDetector(
      onTap: () => _handleStatusCardTap(status),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status.color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStatusIcon(status),
                color: status.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: status.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status.displayName,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(LeadStatus status) {
    switch (status) {
      case LeadStatus.NEW:
        return Icons.fiber_new;
      case LeadStatus.FOLLOWUP:
        return Icons.schedule;
      case LeadStatus.INTERESTED:
        return Icons.thumb_up;
      case LeadStatus.PROPOSAL_SENT:
        return Icons.send;
      case LeadStatus.NOT_INTERESTED:
        return Icons.thumb_down;
      case LeadStatus.BOOKED:
        return Icons.check_circle;
      case LeadStatus.PENDING:
        return Icons.pending;
      case LeadStatus.CANCELLED:
        return Icons.cancel;
      case LeadStatus.CLOSED_WON:
        return Icons.emoji_events;
      case LeadStatus.CLOSED_LOST:
        return Icons.close;
    }
  }

  Widget _buildLeadsList(LeadProvider leadProvider) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _handleBackToGrid,
        ),
        title: Text(
          leadProvider.statusFilter?.displayName ?? 'All Leads',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, email...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          
          // Leads List
          Expanded(
            child: leadProvider.loadingState == LeadLoadingState.loading &&
                    leadProvider.leads.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : leadProvider.loadingState == LeadLoadingState.error
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              leadProvider.error ?? 'An error occurred',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => leadProvider.refreshLeads(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildFilteredLeadsList(leadProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredLeadsList(LeadProvider leadProvider) {
    final filteredLeads = _getFilteredLeads(leadProvider);

    if (filteredLeads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No leads found for "$_searchQuery"'
                  : 'No leads found',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: leadProvider.hasMore && _searchQuery.isEmpty,
      onRefresh: _onRefresh,
      onLoading: () async {
        await leadProvider.loadMoreLeads();
        _refreshController.loadComplete();
      },
      child: ListView.builder(
        itemCount: filteredLeads.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final lead = filteredLeads[index];
          return LeadCard(
            lead: lead,
            onTap: () {
              Navigator.of(context).pushNamed(
                '/lead-detail',
                arguments: lead.id,
              );
            },
          );
        },
      ),
    );
  }
}
