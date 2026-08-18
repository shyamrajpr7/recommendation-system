import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/app_dimens.dart';
import '../models/cinema.dart';

class DetailScreen extends StatefulWidget {
  final int movieId;

  const DetailScreen({super.key, required this.movieId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;

  Movie get _movie => Movie(
        id: widget.movieId,
        title: 'Inception',
        genre: 'Sci-Fi',
        year: 2010,
        rating: 8.8,
        synopsis:
            'A thief who steals corporate secrets through dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.',
        director: 'Christopher Nolan',
      );

  @override
  Widget build(BuildContext context) {
    final movie = _movie;
    final colors = _palette(movie.title);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsing app bar with Hero image
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.background,
            leading: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _isFavorite = !_isFavorite);
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(_isFavorite),
                      color: _isFavorite ? AppColors.error : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'movie-${widget.movieId}',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0, 0.5, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      movie.genre,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                                    ),
                                    child: Text(
                                      '${movie.year}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                movie.title,
                                style: const TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Movie details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildRating(movie.rating),
                      const SizedBox(width: 16),
                      Icon(Icons.person_rounded, size: 18, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        movie.director,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 24),
                  Text(
                    'Synopsis',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 8),
                  Text(
                    movie.synopsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.65,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 400.ms),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.push('/showtimes/${widget.movieId}');
                      },
                      icon: const Icon(Icons.confirmation_number_rounded, size: 20),
                      label: const Text('View Showtimes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent1,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 400.ms),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRating(double rating) {
    final stars = rating / 2;
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < stars.floor()) {
            return Icon(Icons.star_rounded, size: 20, color: AppColors.gold);
          } else if (i < stars) {
            return Icon(Icons.star_half_rounded, size: 20, color: AppColors.gold);
          }
          return Icon(Icons.star_border_rounded, size: 20, color: AppColors.muted2);
        }),
        const SizedBox(width: 6),
        Text(
          '${rating.toStringAsFixed(1)}/10',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  List<Color> _palette(String title) {
    final palettes = [
      [const Color(0xFF1E3A5F), const Color(0xFF0D2137)],
      [const Color(0xFF3B1F6E), const Color(0xFF1A0F3A)],
      [const Color(0xFF5F1E3A), const Color(0xFF370D21)],
      [const Color(0xFF1E5F3A), const Color(0xFF0D3721)],
      [const Color(0xFF5F4A1E), const Color(0xFF372A0D)],
      [const Color(0xFF1E4A5F), const Color(0xFF0D2A37)],
    ];
    return palettes[title.hashCode.abs() % palettes.length];
  }
}
