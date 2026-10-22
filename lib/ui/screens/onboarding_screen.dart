import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/veritas_mark.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.state});

  final AppState state;

  Future<void> _start(BuildContext context) async {
    if (state.settings.haptics) HapticFeedback.mediumImpact();
    await state.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const VeritasMark(size: 46),
                    const SizedBox(width: 12),
                    const Wordmark(fontSize: 14),
                    const Spacer(),
                    TagPill(label: 'iOS', color: c.muted, compact: true),
                  ],
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: c.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ANÁLISIS FACIAL EN VIVO',
                            style: context.texts.labelSmall?.copyWith(
                              fontSize: 8,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'La verdad\ndeja huellas.',
                  style: context.texts.displayMedium?.copyWith(
                    fontSize: 52,
                    height: 0.98,
                    letterSpacing: -2.4,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Veritas analiza microexpresiones y microgestos con la cámara '
                  'del iPhone para estimar la coherencia de una conversación. '
                  'Seis señales, una línea base y cero datos en la nube.',
                  style: context.texts.bodyLarge?.copyWith(
                    color: c.muted,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 34),
                const _FeatureRow(
                  icon: Icons.center_focus_strong_rounded,
                  title: 'Lectura en tiempo real',
                  description:
                      'Rostro, mirada, parpadeo, labios y microgestos procesados '
                      'en el dispositivo.',
                ),
                const _FeatureRow(
                  icon: Icons.tune_rounded,
                  title: 'Tu línea base personal',
                  description:
                      'Calibramos tu rostro en reposo para detectar solo cambios '
                      'reales, no gestos genéricos.',
                ),
                const _FeatureRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privado por diseño',
                  description:
                      'Sin cuentas, sin servidores y sin telemetría. Tus sesiones '
                      'viven en tu iPhone.',
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surfaceAlt,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: c.line.withValues(alpha: 0.7)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: c.amber,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Herramienta de observación conductual. No es un '
                          'polígrafo ni prueba una mentira con certeza científica.',
                          style: context.texts.bodySmall?.copyWith(
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                PrimaryPill(
                  label: 'Comenzar',
                  icon: Icons.arrow_forward_rounded,
                  onTap: () => _start(context),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Al continuar aceptas usar Veritas de forma responsable.',
                    textAlign: TextAlign.center,
                    style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: c.orange.withValues(alpha: 0.10),
              border: Border.all(color: c.orange.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, size: 19, color: c.orange),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.texts.titleMedium),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: context.texts.bodySmall?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
