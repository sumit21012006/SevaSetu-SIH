import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../state/app_scope.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                0,
              ),
              child: Row(
                children: [
                  const BrandMarkTile(),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onFinished,
                    child: Text(AppScope.of(context).tr('action.skip')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Artwork(slide: slide),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: AppColors.ink,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: AppColors.inkSoft,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final f in slide.features)
                              _FeatureChip(
                                icon: f.icon,
                                label: f.label,
                                color: f.color,
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          margin: const EdgeInsets.symmetric(horizontal: 3.5),
                          width: i == _page ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? AppColors.primary
                                : AppColors.hairline,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (last) {
                          widget.onFinished();
                        } else {
                          _controller.nextPage(
                            duration: AppDurations.normal,
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      child: Text(
                        last
                            ? AppScope.of(context).tr('action.getStarted')
                            : AppScope.of(context).tr('action.continue'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.description,
    required this.features,
  });

  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String description;
  final List<_Feature> features;
}

class _Feature {
  const _Feature(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}

const _slides = [
  _SlideData(
    icon: Icons.travel_explore_rounded,
    gradient: [Color(0xFF17439B), Color(0xFF3E6EC4)],
    title: 'Find the right government service',
    description:
        'Tell SevaSetu what you need in your own words — scholarships, '
        'housing, farming help or a job — and discover the exact scheme '
        'meant for you.',
    features: [
      _Feature(Icons.search_rounded, 'Natural search', AppColors.primary),
      _Feature(Icons.rule_rounded, 'Eligibility check', AppColors.info),
    ],
  ),
  _SlideData(
    icon: Icons.folder_copy_rounded,
    gradient: [Color(0xFF0E9488), Color(0xFF34B8A9)],
    title: 'Know exactly which documents you need',
    description:
        'SevaSetu compares the service requirements with your document '
        'vault, tells you what is missing or expired, and scores how ready '
        'you are — so nothing surprises you at the last minute.',
    features: [
      _Feature(
        Icons.verified_rounded,
        'Personalized document list',
        AppColors.success,
      ),
      _Feature(
        Icons.archive_rounded,
        'ZIP of ready documents',
        AppColors.secondaryDark,
      ),
    ],
  ),
  _SlideData(
    icon: Icons.map_rounded,
    gradient: [Color(0xFF6D4FC4), Color(0xFF9B84E4)],
    title: 'Get ready to apply — step by step',
    description:
        'Follow a guided journey from discovery to application tracking, '
        'upload or renew documents, and apply with confidence. Available in '
        'English, हिंदी and मराठी.',
    features: [
      _Feature(Icons.route_rounded, 'Guided journey', AppColors.aiPurple),
      _Feature(
        Icons.track_changes_rounded,
        'Application tracking',
        AppColors.info,
      ),
      _Feature(Icons.translate_rounded, 'Multilingual', AppColors.aiPurple),
    ],
  ),
];

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.slide});
  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.gradient,
        ),
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: slide.gradient.first.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            slide.icon,
            size: 78,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ],
      ),
    );
  }
}

/// Wordmark row used on onboarding.
class BrandMarkTile extends StatelessWidget {
  const BrandMarkTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.hub_rounded, size: 19, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Text(
          AppBrand.name,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
