# Veritas

Veritas es una app iOS (Flutter) que analiza microgestos faciales en tiempo real con la cámara frontal y estima la coherencia de una conversación. Todo el procesamiento ocurre en el dispositivo: no hay cuentas, ni nube, ni envío de video.

> **Aviso importante**: Veritas es una herramienta de observación conductual con fines de entretenimiento y autoexploración. No es un polígrafo, no mide mentiras y no debe usarse para tomar decisiones sobre personas.

## Características

- Análisis en vivo de 6 señales faciales: mirada, labios, cabeza, parpadeo, asimetría y expresión.
- Calibración inicial de 6 segundos para establecer una línea base por persona.
- Preguntas guiadas y coherence score de 0 a 100 con veredicto (coherente / dudoso / inconsistente).
- Historial local, progreso con gráficas y ajustes de sensibilidad.
- Interfaz oscura premium, tipografía Manrope, sin dependencias de red.
- Datos guardados en un JSON local del dispositivo.

## Requisitos

- Flutter 3.41.9 (Dart 3.11.5)
- Xcode 16+ (compilación iOS)
- iOS 15.5 o superior
- Cámara frontal

## Desarrollo local

```bash
flutter pub get
flutter test
flutter run
```

## Generar la IPA sin firma (GitHub Actions)

El workflow `.github/workflows/ios.yml` compila en `macos-15` y publica `Veritas.ipa` como artefacto. Se ejecuta en cada push a `main` o manualmente desde **Actions → Build unsigned iOS IPA → Run workflow**.

```bash
flutter build ios --release --no-codesign
mkdir Payload
cp -R build/ios/iphoneos/Runner.app Payload/
zip -r Veritas.ipa Payload
```

## Instalar en un iPhone con Apple ID gratuito (Sideloadly)

1. Descarga `Veritas.ipa` desde la pestaña **Actions** del repositorio (artefacto `Veritas-ipa`).
2. Instala [Sideloadly](https://sideloadly.io/) en Windows o macOS y conéctalo al iPhone por USB.
3. Arrastra `Veritas.ipa` a Sideloadly, escribe tu Apple ID y pulsa **Start**.
4. En el iPhone ve a **Ajustes → General → VPN y gestión de dispositivos** y confía en tu certificado.
5. Abre Veritas y acepta el permiso de cámara.

Con una cuenta gratuita la app caduca a los 7 días; vuelve a firmarla con Sideloadly para renovarla.

## Estructura

```
lib/
  data/        preguntas guiadas
  models/      FaceFrame, señales, sesiones, ajustes
  services/    motor de coherencia, cámara + ML Kit, almacenamiento
  state/       estado global
  ui/          tema, widgets y pantallas
ios/           configuración nativa y Podfile (iOS 15.5)
```

## Privacidad

Los frames de cámara se procesan en memoria con Google ML Kit y se descartan inmediatamente. Solo se guardan métricas agregadas de cada sesión en el almacenamiento local de la app.
