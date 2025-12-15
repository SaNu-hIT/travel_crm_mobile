import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/constants.dart';

class ShimmerContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerLeadCard extends StatelessWidget {
  const ShimmerLeadCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Avatar
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
            ),
            const SizedBox(width: 12),

            // Lead Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerContainer(
                    width: double.infinity,
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  ShimmerContainer(
                    width: 120,
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 4),
                  ShimmerContainer(
                    width: 100,
                    height: 14,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Status Badge
            ShimmerContainer(
              width: 80,
              height: 28,
              borderRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerMetricCard extends StatelessWidget {
  const ShimmerMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: Container(
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
                ShimmerContainer(
                  width: 40,
                  height: 40,
                  borderRadius: 8,
                ),
                ShimmerContainer(
                  width: 50,
                  height: 20,
                  borderRadius: 12,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerContainer(
                  width: 50,
                  height: 24,
                  borderRadius: 4,
                ),
                const SizedBox(height: 4),
                ShimmerContainer(
                  width: 70,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerStatusCard extends StatelessWidget {
  const ShimmerStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            ShimmerContainer(
              width: 32,
              height: 32,
              borderRadius: 8,
            ),
            const SizedBox(height: 4),
            ShimmerContainer(
              width: 40,
              height: 20,
              borderRadius: 4,
            ),
            const SizedBox(height: 2),
            ShimmerContainer(
              width: 60,
              height: 10,
              borderRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerLeadDetailHeader extends StatelessWidget {
  const ShimmerLeadDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerContainer(
                        width: double.infinity,
                        height: 24,
                        borderRadius: 4,
                      ),
                      const SizedBox(height: 8),
                      ShimmerContainer(
                        width: 150,
                        height: 16,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ShimmerContainer(
                    height: 40,
                    borderRadius: 8,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ShimmerContainer(
                    height: 40,
                    borderRadius: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ShimmerContainer(
              width: 120,
              height: 32,
              borderRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerPermissionCard extends StatelessWidget {
  const ShimmerPermissionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            ShimmerContainer(
              width: 40,
              height: 40,
              borderRadius: 10,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerContainer(
                    width: double.infinity,
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 4),
                  ShimmerContainer(
                    width: 200,
                    height: 12,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            ShimmerContainer(
              width: 60,
              height: 30,
              borderRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerDashboardLoading extends StatelessWidget {
  const ShimmerDashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
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
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[200]!,
                  highlightColor: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerContainer(
                                  width: 120,
                                  height: 18,
                                  borderRadius: 4,
                                ),
                                const SizedBox(height: 4),
                                ShimmerContainer(
                                  width: 160,
                                  height: 12,
                                  borderRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ShimmerContainer(
                        width: 200,
                        height: 28,
                        borderRadius: 4,
                      ),
                      const SizedBox(height: 8),
                      ShimmerContainer(
                        width: 180,
                        height: 28,
                        borderRadius: 4,
                      ),
                      const SizedBox(height: 16),
                      ShimmerContainer(
                        width: double.infinity,
                        height: 48,
                        borderRadius: 12,
                      ),
                    ],
                  ),
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
                children: const [
                  ShimmerMetricCard(),
                  ShimmerMetricCard(),
                  ShimmerMetricCard(),
                  ShimmerMetricCard(),
                ],
              ),

              const SizedBox(height: 24),

              // Status Section Header
              Shimmer.fromColors(
                baseColor: Colors.grey[200]!,
                highlightColor: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerContainer(
                      width: 100,
                      height: 20,
                      borderRadius: 4,
                    ),
                    ShimmerContainer(
                      width: 60,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Status Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: 4,
                itemBuilder: (context, index) => const ShimmerStatusCard(),
              ),

              const SizedBox(height: 24),

              // Recent Leads Header
              Shimmer.fromColors(
                baseColor: Colors.grey[200]!,
                highlightColor: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerContainer(
                      width: 120,
                      height: 20,
                      borderRadius: 4,
                    ),
                    ShimmerContainer(
                      width: 60,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Recent Leads List
              ...List.generate(5, (index) => const ShimmerLeadCard()),
            ]),
          ),
        ),
      ],
    );
  }
}

class ShimmerLeadsList extends StatelessWidget {
  const ShimmerLeadsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => const ShimmerLeadCard(),
    );
  }
}

class ShimmerLeadDetail extends StatelessWidget {
  const ShimmerLeadDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              height: 250,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerContainer(
                              width: double.infinity,
                              height: 24,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 8),
                            ShimmerContainer(
                              width: 150,
                              height: 16,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ShimmerContainer(
                          height: 40,
                          borderRadius: 8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ShimmerContainer(
                          height: 40,
                          borderRadius: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ShimmerContainer(width: 80, height: 16, borderRadius: 4),
                  ShimmerContainer(width: 80, height: 16, borderRadius: 4),
                  ShimmerContainer(width: 80, height: 16, borderRadius: 4),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: List.generate(
                  6,
                  (index) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerContainer(
                          width: 100,
                          height: 14,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 8),
                        ShimmerContainer(
                          width: double.infinity,
                          height: 40,
                          borderRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerPermissionScreen extends StatelessWidget {
  const ShimmerPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerContainer(
                  width: 200,
                  height: 24,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                ShimmerContainer(
                  width: double.infinity,
                  height: 40,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Permission Cards
          const ShimmerPermissionCard(),
          const SizedBox(height: 16),
          const ShimmerPermissionCard(),
          const SizedBox(height: 16),
          const ShimmerPermissionCard(),
          const SizedBox(height: 32),

          // Recording Location
          Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerContainer(
                  width: 180,
                  height: 20,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                ShimmerContainer(
                  width: 240,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const ShimmerContainer(
                            width: 24,
                            height: 24,
                            borderRadius: 4,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ShimmerContainer(
                              height: 16,
                              borderRadius: 4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ShimmerContainer(
                              height: 40,
                              borderRadius: 8,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ShimmerContainer(
                              height: 40,
                              borderRadius: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
