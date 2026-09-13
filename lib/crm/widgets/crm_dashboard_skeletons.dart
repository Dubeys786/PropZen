import 'package:flutter/material.dart';

/// Shimmer skeleton container for enterprise CRM dashboard loading states
class CrmSkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const CrmSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<CrmSkeletonBox> createState() => _CrmSkeletonBoxState();
}

class _CrmSkeletonBoxState extends State<CrmSkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for KPI Cards Grid
class CrmKpiGridSkeleton extends StatelessWidget {
  final int crossAxisCount;

  const CrmKpiGridSkeleton({super.key, required this.crossAxisCount});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 138,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CrmSkeletonBox(width: 100, height: 14),
                  CrmSkeletonBox(width: 32, height: 32, borderRadius: 10),
                ],
              ),
              CrmSkeletonBox(width: 70, height: 26),
              CrmSkeletonBox(width: 140, height: 12),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton for Follow-ups and Pipeline Health cards
class CrmCardSkeleton extends StatelessWidget {
  final double height;

  const CrmCardSkeleton({super.key, this.height = 280});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CrmSkeletonBox(width: 180, height: 18),
              CrmSkeletonBox(width: 60, height: 14),
            ],
          ),
          SizedBox(height: 20),
          CrmSkeletonBox(width: double.infinity, height: 48, borderRadius: 10),
          SizedBox(height: 12),
          CrmSkeletonBox(width: double.infinity, height: 48, borderRadius: 10),
          SizedBox(height: 12),
          CrmSkeletonBox(width: double.infinity, height: 48, borderRadius: 10),
        ],
      ),
    );
  }
}
