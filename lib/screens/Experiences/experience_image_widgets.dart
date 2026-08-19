import 'package:flutter/material.dart';

class ExperienceImageSkeleton extends StatefulWidget {
  const ExperienceImageSkeleton({super.key});

  @override
  State<ExperienceImageSkeleton> createState() =>
      _ExperienceImageSkeletonState();
}

class _ExperienceImageSkeletonState extends State<ExperienceImageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final position = (_controller.value * 3) - 1;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(position - 1, 0),
              end: Alignment(position + 1, 0),
              colors: const [
                Color(0xFFE8EBE9),
                Color(0xFFF5F7F6),
                Color(0xFFE8EBE9),
              ],
              stops: const [0.2, 0.5, 0.8],
            ),
          ),
        );
      },
    );
  }
}

class ExperienceImageFallback extends StatelessWidget {
  const ExperienceImageFallback({super.key, this.iconSize = 34});

  final double iconSize;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF0F2F0),
    child: Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade400,
        size: iconSize,
      ),
    ),
  );
}
