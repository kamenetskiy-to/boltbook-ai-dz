import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:google_fonts/google_fonts.dart';

final class PresentationTheme {
  static const seedColor = Color(0xFF7CFFB2);
  static const panelColor = Color(0xFF10202C);
  static const panelBorder = Color(0xFF294255);
  static const textMuted = Color(0xFFA0B7C6);
  static const warning = Color(0xFFFFB454);
  static const evidence = Color(0xFF7FDBFF);
  static const action = Color(0xFFFF6B6B);

  static final deckConfiguration = FlutterDeckConfiguration(
    background: const FlutterDeckBackgroundConfiguration(
      dark: FlutterDeckBackground.gradient(
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06111B), Color(0xFF102638), Color(0xFF21342C)],
        ),
      ),
      light: FlutterDeckBackground.gradient(
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F3EA), Color(0xFFE4F2ED)],
        ),
      ),
    ),
    footer: const FlutterDeckFooterConfiguration(
      showSlideNumbers: true,
      showSocialHandle: true,
    ),
    header: const FlutterDeckHeaderConfiguration(showHeader: false),
    marker: const FlutterDeckMarkerConfiguration(
      color: Color(0xFFFF6B6B),
      strokeWidth: 8,
    ),
    progressIndicator: const FlutterDeckProgressIndicator.gradient(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF7CFFB2), Color(0xFF7FDBFF), Color(0xFFFF6B6B)],
      ),
      backgroundColor: Color(0xFF1B2440),
    ),
    slideSize: FlutterDeckSlideSize.fromAspectRatio(
      aspectRatio: const FlutterDeckAspectRatio.ratio16x9(),
      resolution: const FlutterDeckResolution.fhd(),
    ),
    transition: const FlutterDeckTransition.fade(),
  );

  static final lightTheme = FlutterDeckThemeData.fromTheme(
    ThemeData.from(
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      useMaterial3: true,
    ).copyWith(
      textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
        bodyMedium: GoogleFonts.ibmPlexSans(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    ),
  );

  static final darkTheme = FlutterDeckThemeData.fromTheme(
    ThemeData.from(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: const Color(0xFF06111B),
      textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.spaceGrotesk(
              fontSize: 66,
              fontWeight: FontWeight.w700,
              letterSpacing: -2.5,
              height: 0.95,
            ),
            displayMedium: GoogleFonts.spaceGrotesk(
              fontSize: 52,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
            headlineMedium: GoogleFonts.spaceGrotesk(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
            titleLarge: GoogleFonts.spaceGrotesk(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
            bodyLarge: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
            bodyMedium: GoogleFonts.ibmPlexSans(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
            labelLarge: GoogleFonts.ibmPlexSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
    ),
  );
}
