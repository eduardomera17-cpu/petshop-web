// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/app/app.dart
// Propósito: Widget raíz de la aplicación web PetShop, configuración de MaterialApp.router,
//            inyección de dependencias global, soporte l10n regional es-419 y banner perimetral.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mipetshop/app/bootstrap.dart';
import 'package:mipetshop/app/di.dart';
import 'package:mipetshop/app/router.dart';
import 'package:mipetshop/core/widgets/connectivity_banner.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/l10n/app_localizations.dart';

/// Widget raíz de la aplicación web PetShop (TRD §1.3.1, §1.3.6).
///
/// Configura MaterialApp.router con GoRouter, hidratación asíncrona,
/// resolución de locale regional es-419 con fallback técnico es,
/// tema visual con contraste AA y ConnectivityBanner perimetral global.
class PetShopApp extends StatefulWidget {
  /// Resultado de la inicialización perimetral de Firebase y servicios backend.
  final BootstrapResult bootstrapResult;

  /// Repositorio de autenticación inyectable opcional (facilita pruebas unitarias).
  final AuthRepository? authRepository;

  /// Construye el widget raíz de la aplicación.
  const PetShopApp({
    super.key,
    required this.bootstrapResult,
    this.authRepository,
  });

  @override
  State<PetShopApp> createState() => _PetShopAppState();
}

class _PetShopAppState extends State<PetShopApp> {
  late final AuthRepository _authRepository;
  late final GoRouter _router;
  late final bool _ownsRepo;

  @override
  void initState() {
    super.initState();
    if (widget.authRepository != null) {
      _authRepository = widget.authRepository!;
      _ownsRepo = false;
    } else {
      _authRepository = AuthRepository(
        firestore: widget.bootstrapResult.firestore,
      );
      _ownsRepo = true;
    }
    _router = createAppRouter(_authRepository);
  }

  @override
  void dispose() {
    if (_ownsRepo) {
      _authRepository.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      bootstrapResult: widget.bootstrapResult,
      authRepository: _authRepository,
      child: MaterialApp.router(
        title: 'PetShop',
        routerConfig: _router,
        locale: const Locale('es', '419'),
        supportedLocales: const [
          Locale('es', '419'),
          Locale('es'),
        ],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0284C7),
            primary: const Color(0xFF0284C7),
            surface: Colors.white,
            brightness: Brightness.light,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
            ),
            margin: EdgeInsets.zero,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.0),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.0),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
            ),
            labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14.0),
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14.0),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF0F172A),
            elevation: 0,
            scrolledUnderElevation: 0,
            titleTextStyle: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
            ),
            iconTheme: IconThemeData(color: Color(0xFF334155)),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFF1F5F9),
            thickness: 1.0,
            space: 1.0,
          ),
        ),
        builder: (context, child) => ConnectivityBanner(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
