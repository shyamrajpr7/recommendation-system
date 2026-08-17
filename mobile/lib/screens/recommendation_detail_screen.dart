import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

class RecommendationDetailScreen extends StatelessWidget {
  final int index;
  const RecommendationDetailScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    // TODO: pull real data from provider in step 9
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Recommendation #$index'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _palette(index),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Detail view coming in step 9', style: TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _palette(int i) {
    const palettes = [
      [Color(0xFF0EA5E9), Color(0xFF6366F1)],
      [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      [Color(0xFFF59E0B), Color(0xFFEF4444)],
      [Color(0xFF10B981), Color(0xFF0EA5E9)],
      [Color(0xFFF43F5E), Color(0xFF8B5CF6)],
      [Color(0xFF14B8A6), Color(0xFF6366F1)],
    ];
    return palettes[i % palettes.length];
  }
}
