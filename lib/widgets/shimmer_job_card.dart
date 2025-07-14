
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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
