import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/veritas_mark.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _sensitivity = widget.state.settings.sensitivity;

  AppState get state => widget.state;

  Future<void> _update(AppSettings value) async {
    await state.updateSettings(value);
    if (mounted) setState(() => _sensitivity = value.sensitivity);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = state.settings;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ajustes',
                  style: context.texts.headlineLarge?.copyWith(fontSize: 34),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personaliza la calibración y el análisis.',
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 22),
                _ProfileCard(state: state),
                const SizedBox(height: 20),
                _Label(text: 'ANÁLISIS'),
                const SizedBox(height: 10),
                SurfaceCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sensibilidad',
                                  style: context.texts.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cuánto peso dar a cada microdesviación.',
                                  style: context.texts.bodySmall?.copyWith(
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TagPill(
                            label: sensitivityLabel(_sensitivity),
                            color: c.orange,
                            compact: true,
                          ),
                        ],
                      ),
                      Slider(
                        value: _sensitivity,
                        min: 0.6,
                        max: 1.6,
                        divisions: 10,
                        onChanged: (value) =>
                            setState(() => _sensitivity = value),
                        onChangeEnd: (value) =>
                            _update(settings.copyWith(sensitivity: value)),
                      ),
                      Row(
                        children: [
                          Text('Conservador', style: context.texts.bodySmall),
                          const Spacer(),
                          Text('Reactivo', style: context.texts.bodySmall),
                        ],
                      ),
                      Divider(height: 30, color: c.line.withValues(alpha: 0.6)),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calibración',
                                  style: context.texts.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Duración de la línea base inicial.',
                                  style: context.texts.bodySmall?.copyWith(
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${settings.calibrationSeconds}s',
                            style: context.texts.titleMedium?.copyWith(
                              color: c.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final seconds in [6, 8, 10, 12, 15])
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _ChoiceChip(
                                  label: '${seconds}s',
                                  active:
                                      settings.calibrationSeconds == seconds,
                                  onTap: () => _update(
                                    settings.copyWith(
                                      calibrationSeconds: seconds,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Divider(height: 30, color: c.line.withValues(alpha: 0.6)),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Respuesta háptica',
                                  style: context.texts.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Vibración al calibrar y finalizar.',
                                  style: context.texts.bodySmall?.copyWith(
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: settings.haptics,
                            onChanged: (value) =>
                                _update(settings.copyWith(haptics: value)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _Label(text: 'APARIENCIA'),
                const SizedBox(height: 10),
                SurfaceCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      for (final mode in const [
                        ('dark', 'Oscuro', Icons.dark_mode_outlined),
                        ('light', 'Claro', Icons.light_mode_outlined),
                        ('system', 'Sistema', Icons.brightness_auto_outlined),
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _ThemeOption(
                              label: mode.$2,
                              icon: mode.$3,
                              active: settings.themeMode == mode.$1,
                              onTap: () => _update(
                                settings.copyWith(themeMode: mode.$1),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _Label(text: 'DATOS'),
                const SizedBox(height: 10),
                SurfaceCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _SettingRow(
                        icon: Icons.storage_rounded,
                        title: 'Sesiones guardadas',
                        subtitle:
                            '${state.sessions.length} lecturas en este iPhone',
                        trailing: Text(
                          '${state.sessions.length}',
                          style: context.texts.titleMedium,
                        ),
                      ),
                      Divider(height: 24, color: c.line.withValues(alpha: 0.6)),
                      _SettingRow(
                        icon: Icons.delete_sweep_outlined,
                        title: 'Borrar historial',
                        subtitle: 'Elimina todas las lecturas locales',
                        danger: true,
                        onTap: state.sessions.isEmpty ? null : _confirmClear,
                      ),
                      Divider(height: 24, color: c.line.withValues(alpha: 0.6)),
                      _SettingRow(
                        icon: Icons.restart_alt_rounded,
                        title: 'Ver introducción',
                        subtitle: 'Vuelve a mostrar la pantalla de bienvenida',
                        onTap: () =>
                            _update(settings.copyWith(onboarded: false)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _Label(text: 'ACERCA DE'),
                const SizedBox(height: 10),
                SurfaceCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _SettingRow(
                        icon: Icons.science_outlined,
                        title: 'Metodología',
                        subtitle: 'Cómo se calcula la coherencia',
                        onTap: _showMethodology,
                      ),
                      Divider(height: 24, color: c.line.withValues(alpha: 0.6)),
                      _SettingRow(
                        icon: Icons.shield_outlined,
                        title: 'Privacidad',
                        subtitle: 'Todo se procesa en el dispositivo',
                        onTap: _showPrivacy,
                      ),
                      Divider(height: 24, color: c.line.withValues(alpha: 0.6)),
                      _SettingRow(
                        icon: Icons.gavel_rounded,
                        title: 'Aviso importante',
                        subtitle: 'No es un polígrafo ni una prueba forense',
                        onTap: _showDisclaimer,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Center(
                  child: Column(
                    children: [
                      const VeritasMark(size: 40, glow: false),
                      const SizedBox(height: 10),
                      Text(
                        'VERITAS 1.0.0',
                        style: context.texts.labelSmall?.copyWith(fontSize: 9),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hecho para iPhone · Flutter + ML Kit',
                        style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar todas las sesiones?'),
        content: const Text(
          'Esta acción elimina el historial local de forma permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (confirmed == true) await state.clearSessions();
  }

  void _showMethodology() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metodología'),
        content: const Text(
          '1. Calibración: se registran tus valores de reposo (apertura labial, '
          'mirada, micro-movimientos de cabeza, simetría y expresión).\n\n'
          '2. Análisis: cada 4 segundos se compara la ventana actual con la '
          'línea base. Las desviaciones se normalizan y se ponderan: mirada 22%, '
          'labios 20%, cabeza 17%, parpadeo 15%, simetría 14% y expresión 12%.\n\n'
          '3. Puntuación: 100% = comportamiento idéntico a tu reposo. Por debajo '
          'de 72% la lectura es dudosa; por debajo de 45%, inconsistente.\n\n'
          'Ningún gesto aislado demuestra una mentira. Veritas es una herramienta '
          'de observación, no un detector científico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacidad'),
        content: const Text(
          'Veritas no crea cuentas, no usa servidores y no envía telemetría.\n\n'
          'La cámara se procesa en el dispositivo con Google ML Kit. Los '
          'resultados se guardan en un archivo JSON dentro de la app, en tu '
          'iPhone, y se eliminan al borrar el historial o desinstalar la app.\n\n'
          'No se guardan fotos ni vídeos: solo métricas faciales agregadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showDisclaimer() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aviso importante'),
        content: const Text(
          'Veritas es una app de entretenimiento y observación conductual. No '
          'detecta mentiras con certeza científica y no debe usarse como prueba '
          'en relaciones personales, entrevistas, procesos legales o laborales.\n\n'
          'La evaluación de credibilidad requiere contexto, entrevista experta y '
          'consentimiento de la persona analizada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        colors: [c.surfaceAlt, c.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          const VeritasMark(size: 54),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Wordmark(fontSize: 16),
                    const SizedBox(width: 8),
                    TagPill(label: 'LOCAL', color: c.green, compact: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Observación facial · 6 señales',
                  style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${state.sessions.length}',
                style: context.texts.headlineMedium?.copyWith(fontSize: 22),
              ),
              Text(
                'SESIONES',
                style: context.texts.labelSmall?.copyWith(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        text,
        style: context.texts.labelMedium?.copyWith(fontSize: 9.5),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      borderRadius: 14,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? c.orange : c.surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? c.orange : c.line),
        ),
        child: Text(
          label,
          style: context.texts.bodySmall?.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : c.muted,
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      borderRadius: 18,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? c.orange.withValues(alpha: 0.14) : c.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? c.orange.withValues(alpha: 0.5) : c.line,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: active ? c.orange : c.muted),
            const SizedBox(height: 6),
            Text(
              label,
              style: context.texts.bodySmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: active ? c.orange : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = danger ? c.red : c.text;
    return Pressable(
      onTap: onTap,
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (danger ? c.red : c.orange).withValues(alpha: 0.10),
              ),
              child: Icon(icon, size: 16, color: danger ? c.red : c.orange),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.texts.titleMedium?.copyWith(
                      fontSize: 13.5,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: c.muted.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}
