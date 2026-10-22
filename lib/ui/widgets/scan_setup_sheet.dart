import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../theme.dart';
import 'common.dart';
import 'veritas_mark.dart';

Future<String?> showScanSetup(BuildContext context, AppState state) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ScanSetupSheet(state: state),
  );
}

class ScanSetupSheet extends StatefulWidget {
  const ScanSetupSheet({super.key, required this.state});

  final AppState state;

  @override
  State<ScanSetupSheet> createState() => _ScanSetupSheetState();
}

class _ScanSetupSheetState extends State<ScanSetupSheet> {
  late final TextEditingController _name = TextEditingController();
  late double _sensitivity = widget.state.settings.sensitivity;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          border: Border.all(color: c.line.withValues(alpha: 0.7)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: c.muted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const VeritasMark(size: 44, glow: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuevo análisis',
                        style: context.texts.headlineSmall,
                      ),
                      Text(
                        'Calibra unos segundos y comienza a preguntar.',
                        style: context.texts.bodySmall,
                      ),
                    ],
                  ),
                ),
                RoundIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('SUJETO', style: context.texts.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              style: context.texts.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Nombre o alias (opcional)',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Text('SENSIBILIDAD', style: context.texts.labelMedium),
                const Spacer(),
                Text(
                  sensitivityLabel(_sensitivity),
                  style: context.texts.bodySmall?.copyWith(
                    color: c.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Slider(
              value: _sensitivity,
              min: 0.6,
              max: 1.6,
              divisions: 10,
              onChanged: (value) => setState(() => _sensitivity = value),
            ),
            Row(
              children: [
                Text('Conservador', style: context.texts.bodySmall),
                const Spacer(),
                Text('Reactivo', style: context.texts.bodySmall),
              ],
            ),
            const SizedBox(height: 22),
            PrimaryPill(
              label: 'Iniciar análisis',
              icon: Icons.center_focus_strong_rounded,
              onTap: _submit,
            ),
            const SizedBox(height: 12),
            Text(
              'Analiza una persona a la vez. Iluminación frontal y rostro descubierto.',
              textAlign: TextAlign.center,
              style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _name.text.trim();
    widget.state.updateSettings(
      widget.state.settings.copyWith(sensitivity: _sensitivity),
    );
    Navigator.of(context).pop(name.isEmpty ? 'Sujeto anónimo' : name);
  }
}
