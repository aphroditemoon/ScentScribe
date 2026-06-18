
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/perfume_model.dart';


class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.charcoal.withOpacity(0.7),
          borderRadius: BorderRadius.circular(borderRadius ?? 20),
          border: Border.all(
            color: borderColor ?? AppColors.charcoalLight.withOpacity(0.5),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}


class GoldButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const GoldButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.obsidian, strokeWidth: 2),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: AppColors.obsidian, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.obsidian,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}


class NotePill extends StatelessWidget {
  final FragranceNote note;
  final bool isCompact;

  const NotePill({super.key, required this.note, this.isCompact = false});

  Color get _color {
    switch (note.category) {
      case NoteCategory.top: return AppColors.topNote;
      case NoteCategory.heart: return AppColors.heartNote;
      case NoteCategory.base: return AppColors.baseNote;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            note.name,
            style: TextStyle(
              color: _color,
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


class ScoreRing extends StatelessWidget {
  final double score;
  final double size;
  final String? label;
  final Color? color;

  const ScoreRing({
    super.key,
    required this.score,
    this.size = 64,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? _scoreColor(score);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => CircularProgressIndicator(
              value: value,
              strokeWidth: size * 0.08,
              backgroundColor: AppColors.charcoalLight,
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.toInt()}',
                style: TextStyle(
                  color: ringColor,
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: size * 0.13,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double s) {
    if (s >= 80) return AppColors.success;
    if (s >= 60) return AppColors.gold;
    if (s >= 40) return AppColors.warning;
    return AppColors.error;
  }
}


class WeatherBadge extends StatelessWidget {
  final WeatherSnapshot weather;
  final bool compact;

  const WeatherBadge({super.key, required this.weather, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 12,
      ),
      borderRadius: compact ? 12 : 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(weather.emoji, style: TextStyle(fontSize: compact ? 18 : 24)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${weather.temperature.toInt()}°C',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: compact ? 14 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!compact) ...[
                Text(
                  '${weather.humidity.toInt()}% humidity',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ],
          ),
          if (!compact && weather.city != null) ...[
            const SizedBox(width: 8),
            Container(width: 0.5, height: 30, color: AppColors.charcoalLight),
            const SizedBox(width: 8),
            Text(
              weather.city!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}


class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool interactive;
  final Function(double)? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1.0;
        final filled = rating >= starValue;
        final half = rating >= starValue - 0.5 && rating < starValue;

        return GestureDetector(
          onTap: interactive ? () => onRatingChanged?.call(starValue) : null,
          child: Icon(
            filled ? Icons.star_rounded
                : half ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            color: filled || half ? AppColors.gold : AppColors.textMuted,
            size: size,
          ),
        );
      }),
    );
  }
}


class FamilyBadge extends StatelessWidget {
  final PerfumeFamily family;
  final bool showLabel;

  const FamilyBadge({super.key, required this.family, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final p = Perfume(
      id: '', name: '', brand: '',
      family: family, notes: [], addedAt: DateTime.now(),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.familyColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.familyColor.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(p.familyEmoji, style: const TextStyle(fontSize: 12)),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              family.toString().split('.').last,
              style: TextStyle(
                color: p.familyColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.charcoalLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: AppColors.charcoal.withOpacity(0.5),
        );
  }
}


class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}


class EmptyState extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    this.emoji,
    this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.textMuted, size: 36),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut)
            else if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 60))
                  .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}


class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const GlowContainer({
    super.key,
    required this.child,
    required this.glowColor,
    this.glowRadius = 30,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.25),
            blurRadius: glowRadius,
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}
