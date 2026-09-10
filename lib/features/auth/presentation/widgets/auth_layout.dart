import 'package:aplicacion_mundo_otaku/config/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final Widget child;

  const AuthLayout({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MundoOtakuColors.night,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 960) {
            return Row(
              children: [
                const Expanded(flex: 11, child: _AuthHero()),
                Expanded(
                  flex: 9,
                  child: ColoredBox(
                    color: MundoOtakuColors.cream,
                    child: _FormPane(
                      eyebrow: eyebrow,
                      title: title,
                      description: description,
                      scrollable: true,
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          }

          return ColoredBox(
            color: MundoOtakuColors.cream,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(
                        height: 238, child: _AuthHero(compact: true)),
                    _FormPane(
                      eyebrow: eyebrow,
                      title: title,
                      description: description,
                      scrollable: false,
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormPane extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final bool scrollable;
  final Widget child;

  const _FormPane({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.scrollable,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: MundoOtakuColors.coralDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.7,
                ),
              ),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 30),
              child,
            ],
          ),
        ),
      ),
    );

    return SafeArea(
      top: MediaQuery.sizeOf(context).width >= 960,
      child: Center(
        child: scrollable ? SingleChildScrollView(child: content) : content,
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  final bool compact;

  const _AuthHero({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/brand/yoru_exchange_hero.webp',
          fit: BoxFit.cover,
          alignment: compact ? const Alignment(.38, -.05) : Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                MundoOtakuColors.night.withOpacity(compact ? .12 : .06),
                MundoOtakuColors.night.withOpacity(compact ? .88 : .78),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(compact ? 22 : 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandMark(),
              const Spacer(),
              if (!compact) ...[
                const _CommunityBadge(),
                const SizedBox(height: 18),
                const Text(
                  'Tu colección merece\nuna nueva historia.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    height: 1.04,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Publica, descubre e intercambia manga y coleccionables con otros fans.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.78),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ] else
                const Text(
                  'Intercambia historias.\nConecta colecciones.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: MundoOtakuColors.coral,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text(
            'MO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'MUNDO OTAKU',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CommunityBadge extends StatelessWidget {
  const _CommunityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: MundoOtakuColors.mint.withOpacity(.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: MundoOtakuColors.mint.withOpacity(.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded,
              color: MundoOtakuColors.mint, size: 16),
          SizedBox(width: 8),
          Text(
            'HECHO PARA COLECCIONISTAS',
            style: TextStyle(
              color: MundoOtakuColors.mint,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
