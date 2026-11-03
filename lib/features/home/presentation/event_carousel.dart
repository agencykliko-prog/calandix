import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../core/models/models.dart';
import '../../events/presentation/widgets/event_card.dart';

/// Diaporama des événements : la carte au centre est mise en avant, ses
/// voisines s'inclinent et se retirent légèrement. Défilement automatique,
/// suspendu dès que l'on touche le carrousel.
class EventCarousel extends StatefulWidget {
  const EventCarousel({super.key, required this.events, this.height = 300});

  final List<Event> events;
  final double height;

  @override
  State<EventCarousel> createState() => _EventCarouselState();
}

class _EventCarouselState extends State<EventCarousel> {
  late final PageController _page;
  Timer? _auto;
  double _pos = 0;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.86)
      ..addListener(() => setState(() => _pos = _page.page ?? 0));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _restart();
  }

  void _restart() {
    _auto?.cancel();
    if (_reduced || widget.events.length < 2) return;
    _auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_page.hasClients) return;
      final next = ((_page.page ?? 0).round() + 1) % widget.events.length;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Motion.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    final current = _pos.round().clamp(0, events.length - 1);
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: Listener(
            onPointerDown: (_) => _auto?.cancel(),
            onPointerUp: (_) => _restart(),
            child: PageView.builder(
              controller: _page,
              itemCount: events.length,
              clipBehavior: Clip.none,
              itemBuilder: (context, i) {
                final d = (i - _pos).clamp(-1.0, 1.0);
                final scale = 1 - d.abs() * 0.08;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(-d * 0.22)
                    ..scaleByDouble(scale, scale, 1, 1),
                  child: Opacity(
                    opacity: 1 - d.abs() * 0.25,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: EventCard(
                        event: events[i],
                        onTap: () => context.push(Routes.event(events[i].id)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (events.length > 1) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (i, e) in events.indexed)
                Pressable(
                  scale: 0.8,
                  semanticLabel: 'Afficher {0}'.trf([e.name]),
                  onTap: () => _page.animateToPage(
                    i,
                    duration: Motion.base,
                    curve: Motion.easeOut,
                  ),
                  child: AnimatedContainer(
                    duration: Motion.base,
                    curve: Motion.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == current ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == current
                          ? e.category.hue.base
                          : Confetti.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
