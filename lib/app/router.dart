// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/app/router.dart
// Propósito: Configuración declarativa de rutas con GoRouter, hidratación asíncrona,
//            guards de seguridad basados en roles, carga diferida (deferred) y pantallas shell.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/core/admin_navigation_shell.dart' deferred as admin_shell;
import 'package:mipetshop/ui/core/client_navigation_shell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mipetshop/data/repositories/appointments_repository.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/repositories/pets_repository.dart';
import 'package:mipetshop/data/repositories/product_requests_repository.dart';
import 'package:mipetshop/data/repositories/products_repository.dart';
import 'package:mipetshop/data/repositories/proformas_repository.dart';
import 'package:mipetshop/data/repositories/profile_repository.dart';
import 'package:mipetshop/data/services/storage_service.dart';
import 'package:mipetshop/ui/features/admin/dashboard/views/admin_dashboard_screen.dart' deferred as admin_dashboard;
import 'package:mipetshop/ui/features/admin/agenda/views/admin_agenda_screen.dart' deferred as admin_agenda;
import 'package:mipetshop/ui/features/admin/governance/views/admin_governance_screen.dart' deferred as admin_governance;
import 'package:mipetshop/ui/features/admin/services/views/admin_services_screen.dart' deferred as admin_services;
import 'package:mipetshop/ui/features/admin/products/views/admin_products_screen.dart' deferred as admin_products;
import 'package:mipetshop/ui/features/admin/inventory/views/admin_inventory_screen.dart' deferred as admin_inventory;
import 'package:mipetshop/ui/features/admin/requests/views/admin_requests_screen.dart' deferred as admin_requests;
import 'package:mipetshop/ui/features/admin/proformas/views/admin_proformas_screen.dart' deferred as admin_proformas;
import 'package:mipetshop/ui/features/admin/clients/views/admin_clients_screen.dart' deferred as admin_clients;
import 'package:mipetshop/ui/features/profile/views/staff_profile_screen.dart' deferred as staff_profile;
import 'package:mipetshop/ui/features/chat/views/admin_staff_inbox_screen.dart' deferred as staff_inbox;
import 'package:mipetshop/ui/features/appointments/view_models/booking_view_model.dart';
import 'package:mipetshop/ui/features/appointments/view_models/history_view_model.dart';
import 'package:mipetshop/ui/features/appointments/views/appointments_history_view.dart';
import 'package:mipetshop/ui/features/appointments/views/booking_flow_view.dart';
import 'package:mipetshop/ui/features/auth/views/change_password_view.dart';
import 'package:mipetshop/ui/features/auth/views/forgot_password_view.dart';
import 'package:mipetshop/ui/features/auth/views/login_view.dart';
import 'package:mipetshop/ui/features/auth/views/register_view.dart';
import 'package:mipetshop/ui/features/billing/view_models/my_proformas_view_model.dart';
import 'package:mipetshop/ui/features/billing/views/my_proformas_view.dart';
import 'package:mipetshop/ui/features/billing/view_models/cart_view_model.dart';
import 'package:mipetshop/ui/features/billing/views/cart_view.dart';
import 'package:mipetshop/ui/features/billing/view_models/payment_summary_view_model.dart';
import 'package:mipetshop/ui/features/billing/views/payment_summary_view.dart';
import 'package:mipetshop/ui/features/catalog/view_models/catalog_view_model.dart';
import 'package:mipetshop/ui/features/catalog/view_models/my_requests_view_model.dart';
import 'package:mipetshop/ui/features/catalog/views/catalog_view.dart';
import 'package:mipetshop/ui/features/catalog/views/my_requests_view.dart';
import 'package:mipetshop/ui/features/pets/view_models/pets_list_view_model.dart';
import 'package:mipetshop/ui/features/pets/views/pets_list_view.dart';
import 'package:mipetshop/ui/features/profile/view_models/profile_view_model.dart';
import 'package:mipetshop/ui/features/profile/views/profile_view.dart';
import 'package:mipetshop/data/repositories/chat_repository.dart';
import 'package:mipetshop/ui/features/chat/view_models/chat_view_model.dart';
import 'package:mipetshop/ui/features/chat/views/chat_screen.dart';

/// Ruta canónica del carrito de compras del cliente (TRD §1.3.3, §1.3.7).
const String kCartRoute = '/billing/cart';

/// Ruta canónica del resumen consolidado a pagar del cliente (FA-01, TRD §1.3.3, §1.3.7).
const String kPaymentSummaryRoute = '/billing/summary';

/// Configuración canónica de rutas declarativas con GoRouter (TRD §1.3.3).
///
/// Implementa:
/// 1. Hidratación asíncrona (CA-06): Mientras [AuthRepository.isHydrated] sea false,
///    permanece en `/loading` y retiene la ruta solicitada en `?from=`.
/// 2. Protección de rutas internas para visitantes (CA-01, A-07).
/// 3. Aislamiento de rutas de cliente frente a personal administrativo (CA-08).
/// 4. Denegación de acceso a rutas administrativas para clientes (CA-23).
/// 5. Exclusividad de gobierno del sistema para SUPERADMIN (CA-34).
GoRouter createAppRouter(AuthRepository authRepository) {
  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: authRepository,
    // Ruta desconocida (AUD-343, N-15). Sin esta rama go_router cae a su propia
    // pantalla de error, que compone el texto de la excepción —«no routes for
    // location: /lo-que-sea»— y se lo enseña a un usuario final. Aquí se le dice
    // lo que pasa con las palabras del producto y se le devuelve a su inicio.
    errorBuilder: (context, state) => const _RouteNotFoundScreen(),
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const _LoadingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordView(),
      ),
      // Armazon de navegacion del cliente (TRD 1.3.3, 1.3.4). Sin el, estas
      // rutas quedan implementadas pero inalcanzables desde la interfaz.
      ShellRoute(
        builder: (context, state, child) => ClientNavigationShell(
          location: state.uri.path,
          role: authRepository.role,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const _HomeScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const _ProfileScreen(),
          ),
          GoRoute(
            path: '/pets',
            builder: (context, state) => const _PetsScreen(),
          ),
          GoRoute(
            path: '/appointments',
            builder: (context, state) => const _AppointmentsScreen(),
          ),
          GoRoute(
            path: '/catalog',
            builder: (context, state) => const _CatalogScreen(),
          ),
          GoRoute(
            path: '/billing',
            builder: (context, state) => const _BillingScreen(),
          ),
          GoRoute(
            path: kCartRoute,
            builder: (context, state) => const _CartScreen(),
          ),
          GoRoute(
            path: kPaymentSummaryRoute,
            builder: (context, state) => const _PaymentSummaryScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const _ChatScreen(),
          ),
        ],
      ),
      // Armazon de navegacion del panel (TRD 1.3.3, 1.3.4, 1.3.6).
      // Carga diferida (deferred loading) del shell y modulos administrativos.
      ShellRoute(
        builder: (context, state, child) => DeferredWidget(
          loader: () => admin_shell.loadLibrary(),
          builder: () => admin_shell.AdminNavigationShell(
            location: state.uri.path,
            role: authRepository.role,
            onSignOut: () async {
              try {
                await authRepository.signOut();
              } catch (_) {}
            },
            child: child,
          ),
        ),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => DeferredWidget(
              loader: () => admin_dashboard.loadLibrary(),
              builder: () => admin_dashboard.AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/agenda',
            builder: (context, state) => DeferredWidget(
              loader: () => admin_agenda.loadLibrary(),
              builder: () => admin_agenda.AdminAgendaScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/governance',
            builder: (context, state) => DeferredWidget(
              loader: () => admin_governance.loadLibrary(),
              builder: () => admin_governance.AdminGovernanceScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/services',
            builder: (context, state) => DeferredWidget(
              loader: () => admin_services.loadLibrary(),
              builder: () => admin_services.AdminServicesScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/products',
            builder: (context, state) => DeferredWidget(
              loader: () => admin_products.loadLibrary(),
              builder: () => admin_products.AdminProductsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/inventory',
            builder: (context, state) => DeferredWidget(
              loader: () => admin_inventory.loadLibrary(),
              builder: () => admin_inventory.AdminInventoryScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/requests',
            builder: (context, state) => DeferredWidget(
              loader: () => admin_requests.loadLibrary(),
              builder: () => admin_requests.AdminRequestsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/proformas',
            builder: (context, state) => DeferredWidget(
              loader: () => admin_proformas.loadLibrary(),
              builder: () => admin_proformas.AdminProformasScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/clients',
            builder: (context, state) => DeferredWidget(
              loader: () => admin_clients.loadLibrary(),
              builder: () => admin_clients.AdminClientsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/profile',
            builder: (context, state) => DeferredWidget(
              loader: () => staff_profile.loadLibrary(),
              builder: () => staff_profile.StaffProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/chat',
            builder: (context, state) => DeferredWidget(
              loader: () => staff_inbox.loadLibrary(),
              builder: () => staff_inbox.AdminStaffInboxScreen(),
            ),
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isHydrated = authRepository.isHydrated;
      final currentPath = state.uri.path;

      // 1. Hidratación asíncrona (TRD §1.3.3, CA-06):
      // Mientras la sesión no esté hidratada, jamás desviar a login.
      if (!isHydrated) {
        if (currentPath == '/loading') return null;
        final target = state.uri.toString();
        final encoded = Uri.encodeComponent(target);
        return '/loading?from=$encoded';
      }

      final isAuthenticated = authRepository.isAuthenticated;
      final role = authRepository.role;

      final isPublicAuthRoute = currentPath == '/login' ||
          currentPath == '/register' ||
          currentPath == '/forgot-password';

      // 2. Visitante sin sesión intentando acceder a ruta interna (A-07, CA-01)
      if (!isAuthenticated) {
        if (isPublicAuthRoute) return null;
        final target = state.uri.toString();
        final encoded = Uri.encodeComponent(target);
        return '/login?from=$encoded';
      }

      // 3. Usuario autenticado en ruta de autenticación o pantalla de carga transitoria
      if (isPublicAuthRoute || currentPath == '/loading') {
        final fromParam = state.uri.queryParameters['from'];
        if (fromParam != null && fromParam.isNotEmpty) {
          final decoded = Uri.decodeComponent(fromParam);
          if (decoded.startsWith('/') && decoded != '/loading' && decoded != '/login') {
            // Verificar si el rol tiene permiso sobre la ruta de restauración
            if (_isRoutePermittedForRole(decoded, role)) {
              return decoded;
            }
          }
        }

        // Destino canónico predeterminado según rol
        if (role == 'ADMIN' || role == 'SUPERADMIN') {
          return '/admin';
        }
        return '/';
      }

      // 4. Cliente intentando acceder a rutas de administración (AD-01, CA-23)
      if (role == 'CLIENT' && currentPath.startsWith('/admin')) {
        return '/';
      }

      // 5. Personal intentando acceder a rutas de cliente distintas de /profile y /change-password (CA-08, B-6)
      final isStaff = role == 'ADMIN' || role == 'SUPERADMIN';
      final isAllowedPersonalRoute = currentPath == '/profile' || currentPath == '/change-password';
      final isAdminRoute = currentPath.startsWith('/admin');
      if (isStaff && !isAdminRoute && !isAllowedPersonalRoute) {
        return '/admin';
      }

      // 6. Exclusividad de gobierno para Super Administrador (CF-11, CA-34)
      if (currentPath.startsWith('/admin/governance') && role != 'SUPERADMIN') {
        return '/admin';
      }

      return null;
    },
  );
}

bool _isRoutePermittedForRole(String path, String? role) {
  if (role == 'CLIENT') {
    return !path.startsWith('/admin');
  }
  if (role == 'ADMIN') {
    if (path.startsWith('/admin/governance')) return false;
    if (path == '/profile' || path == '/change-password') return true;
    return path.startsWith('/admin');
  }
  if (role == 'SUPERADMIN') {
    if (path == '/profile' || path == '/change-password') return true;
    return path.startsWith('/admin');
  }
  return false;
}

// ────────────────────────────────────────────────────────────────────────────
// CARGA DIFERIDA DE MÓDULOS WEB (TRD §1.3.6, §8.2 S-6)
// ────────────────────────────────────────────────────────────────────────────

/// Componente de infraestructura para carga diferida de rutas y vistas Web (TRD §1.3.6).
///
/// Encapsula la llamada asíncrona a [loader] (Dart `loadLibrary()`) mostrando un
/// indicador visual mientras se descarga el fragmento JS/Wasm correspondiente.
class DeferredWidget extends StatefulWidget {
  final Future<void> Function() loader;
  final Widget Function() builder;
  final Widget? placeholder;

  const DeferredWidget({
    super.key,
    required this.loader,
    required this.builder,
    this.placeholder,
  });

  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
          return widget.builder();
        }
        if (snapshot.hasError) {
          final loadError = 'Error al cargar el módulo: ${snapshot.error}';
          return Scaffold(
            body: Center(
              child: Text(loadError),
            ),
          );
        }
        return widget.placeholder ??
            const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PANTALLAS BASE DEL SHELL (TRD §1.3.3)
// ────────────────────────────────────────────────────────────────────────────

class _ShellScreenBase extends StatelessWidget {
  final String title;

  const _ShellScreenBase({required this.title});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final signOutText = l10n?.navSignOut ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TappableArea(
            semanticLabel: signOutText,
            tooltip: signOutText,
            onTap: () async {
              try {
                final repo = context.read<AuthRepository>();
                await repo.signOut();
              } catch (_) {}
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Icon(Icons.pets, size: 64.0),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n?.loadingSession ?? '';

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(text),
          ],
        ),
      ),
    );
  }
}


/// Pantalla de dirección desconocida (`AUD-343`, `N-15`, `CA-34`).
///
/// `go_router` trae la suya, `MaterialErrorScreen`, y muestra el texto de la
/// excepción: quien abre un marcador de una ruta que ya no existe lee una traza
/// en inglés con el nombre interno de la ruta. `N-15` prohíbe exactamente eso,
/// y lo prohíbe también en las pantallas técnicas o de diagnóstico (`CA-34`).
///
/// El control lleva a `/` y no a un destino calculado por rol: la regla 5 del
/// `redirect` ya desvía al personal a `/admin`, de modo que un solo destino vale
/// para los dos y no aparece una segunda copia de esa decisión que mantener.
class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final action = l10n?.routeNotFoundAction ?? '';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore_off_outlined, size: 48.0),
                const SizedBox(height: 16.0),
                Text(
                  l10n?.routeNotFoundTitle ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  l10n?.routeNotFoundMessage ?? '',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                TappableArea(
                  key: const Key('route_not_found_home'),
                  semanticLabel: action,
                  tooltip: action,
                  onTap: () => context.go('/'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Text(action),
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


class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final signOutText = l10n?.navSignOut ?? '';

    String displayName = '';
    try {
      final user = context.read<AuthRepository>().currentUser;
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        displayName = user.displayName!.split(' ').first;
      } else if (user?.email != null && user!.email!.isNotEmpty) {
        displayName = user.email!.split('@').first;
      }
    } catch (_) {}

    final shortcuts = kClientDestinations.where((d) => d.route != '/').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.navHome ?? ''),
        actions: [
          TappableArea(
            semanticLabel: signOutText,
            tooltip: signOutText,
            onTap: () async {
              try {
                final repo = context.read<AuthRepository>();
                await repo.signOut();
              } catch (_) {}
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.clientHomeGreeting(displayName) ?? '',
                    style: const TextStyle(
                      fontSize: 26.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    l10n?.clientHomeSubtitle ?? '',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // 3 Tarjetas de resumen métrico (Figura 4)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 680;
                      final card1 = Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.clientHomeNextAppointmentTitle ?? '',
                                style: const TextStyle(fontSize: 13.0, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                l10n?.clientHomeNoAppointments ?? '',
                                style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      );

                      final card2 = Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.clientHomeActivePetsTitle ?? '',
                                style: const TextStyle(fontSize: 13.0, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12.0),
                              const Text(
                                '0',
                                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      );

                      final card3 = Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.clientHomeActiveRequestsTitle ?? '',
                                style: const TextStyle(fontSize: 13.0, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                l10n?.clientHomeNoRequests ?? '',
                                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(child: card1),
                            const SizedBox(width: 16.0),
                            Expanded(child: card2),
                            const SizedBox(width: 16.0),
                            Expanded(child: card3),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          card1,
                          const SizedBox(height: 12.0),
                          card2,
                          const SizedBox(height: 12.0),
                          card3,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24.0),

                  // Bloque de Accesos rápidos y Mensajes recientes (Figura 4)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 720;
                      final quickActionsCard = Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.clientHomeQuickActionsTitle ?? '',
                                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 16.0),
                              Wrap(
                                spacing: 12.0,
                                runSpacing: 12.0,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => context.go('/appointments'),
                                    child: Text(l10n?.clientHomeBookAppointmentAction ?? ''),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => context.go('/catalog'),
                                    child: Text(l10n?.clientHomeViewCatalogAction ?? ''),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => context.go('/pets'),
                                    child: Text(l10n?.clientHomeRegisterPetAction ?? ''),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );

                      final recentMessagesCard = Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.clientHomeRecentMessagesTitle ?? '',
                                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                l10n?.clientHomeNoRecentMessages ?? '',
                                style: const TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: quickActionsCard),
                            const SizedBox(width: 16.0),
                            Expanded(flex: 2, child: recentMessagesCard),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          quickActionsCard,
                          const SizedBox(height: 16.0),
                          recentMessagesCard,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28.0),

                  // Accesos a todos los módulos del cliente (Key client_home_shortcuts)
                  ResponsiveLayout(
                    builder: (context, breakpoint) {
                      final columns = breakpoint.isCompact ? 2 : (breakpoint.isMedium ? 3 : 6);
                      return GridView.count(
                        key: const Key('client_home_shortcuts'),
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12.0,
                        crossAxisSpacing: 12.0,
                        childAspectRatio: 1.15,
                        children: [
                          for (final d in shortcuts)
                            Card(
                              child: TappableArea(
                                semanticLabel: d.label(l10n),
                                tooltip: d.label(l10n),
                                onTap: () => context.go(d.route),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(d.selectedIcon, size: 30.0, color: const Color(0xFF0284C7)),
                                    const SizedBox(height: 8.0),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Text(
                                        d.label(l10n),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileScreen extends StatefulWidget {
  const _ProfileScreen();

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  ProfileViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final repo = Provider.of<ProfileRepository?>(context, listen: false);
      final firestore = Provider.of<FirebaseFirestore?>(context, listen: false);
      final authRepo = Provider.of<AuthRepository?>(context, listen: false);

      if (repo != null) {
        _viewModel = ProfileViewModel(repository: repo);
      } else if (firestore != null) {
        _viewModel = ProfileViewModel(
          repository: ProfileRepository(firestore: firestore),
        );
      }

      final uid = authRepo?.currentUser?.uid;
      if (uid != null && _viewModel != null) {
        _viewModel!.loadProfile(uid);
      }
    }
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel == null) {
      final l10n = AppLocalizations.of(context);
      return _ShellScreenBase(title: l10n?.navProfile ?? '');
    }
    return ProfileView(viewModel: _viewModel!);
  }
}

class _PetsScreen extends StatefulWidget {
  const _PetsScreen();

  @override
  State<_PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<_PetsScreen> {
  PetsListViewModel? _viewModel;
  String? _ownerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final repo = Provider.of<PetsRepository?>(context, listen: false);
      final firestore = Provider.of<FirebaseFirestore?>(context, listen: false);
      final authRepo = Provider.of<AuthRepository?>(context, listen: false);

      if (repo != null) {
        _viewModel = PetsListViewModel(repository: repo);
      } else if (firestore != null) {
        _viewModel = PetsListViewModel(
          repository: PetsRepository(firestore: firestore),
        );
      }

      _ownerId = authRepo?.currentUser?.uid;
    }
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel == null || _ownerId == null) {
      final l10n = AppLocalizations.of(context);
      return _ShellScreenBase(title: l10n?.navPets ?? '');
    }
    return PetsListView(
      viewModel: _viewModel!,
      ownerId: _ownerId!,
    );
  }
}

class _AppointmentsScreen extends StatefulWidget {
  const _AppointmentsScreen();

  @override
  State<_AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<_AppointmentsScreen> {
  BookingViewModel? _bookingVm;
  HistoryViewModel? _historyVm;
  bool _showBooking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_historyVm == null) {
      try {
        final apptRepo = Provider.of<AppointmentsRepository?>(context, listen: false);
        final catRepo = Provider.of<CatalogRepository?>(context, listen: false);
        final petsRepo = Provider.of<PetsRepository?>(context, listen: false);
        final authRepo = Provider.of<AuthRepository?>(context, listen: false);
        final uid = authRepo?.currentUser?.uid;

        if (apptRepo != null && catRepo != null && petsRepo != null && uid != null) {
          _historyVm = HistoryViewModel(
            repository: apptRepo,
            clientId: uid,
          );
          _bookingVm = BookingViewModel(
            appointmentsRepository: apptRepo,
            catalogRepository: catRepo,
            petsRepository: petsRepo,
            ownerId: uid,
          );
        }
      } catch (_) {
        // Fallback seguro para tests aislados sin dependencias completas
      }
    }
  }

  @override
  void dispose() {
    _historyVm?.dispose();
    _bookingVm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_historyVm == null) {
      final l10n = AppLocalizations.of(context);
      return _ShellScreenBase(title: l10n?.navAppointments ?? '');
    }

    if (_showBooking && _bookingVm != null) {
      return BookingFlowView(viewModel: _bookingVm!);
    }

    return AppointmentsHistoryView(
      viewModel: _historyVm!,
      onNavigateToBooking: () {
        setState(() {
          _showBooking = true;
        });
      },
    );
  }
}

class _CatalogScreen extends StatefulWidget {
  const _CatalogScreen();

  @override
  State<_CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<_CatalogScreen> {
  CatalogViewModel? _catalogVm;
  MyRequestsViewModel? _requestsVm;
  bool _showRequests = false;
  String? _uid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_catalogVm == null) {
      try {
        final productsRepo = Provider.of<ProductsRepository?>(context, listen: false);
        final catalogRepo = Provider.of<CatalogRepository?>(context, listen: false);
        final requestsRepo = Provider.of<ProductRequestsRepository?>(context, listen: false);
        final authRepo = Provider.of<AuthRepository?>(context, listen: false);
        _uid = authRepo?.currentUser?.uid;

        if (productsRepo != null && catalogRepo != null) {
          _catalogVm = CatalogViewModel(
            productsRepository: productsRepo,
            catalogRepository: catalogRepo,
          );
        }

        if (requestsRepo != null && _uid != null) {
          _requestsVm = MyRequestsViewModel(
            repository: requestsRepo,
            catalogRepository: catalogRepo,
            clientId: _uid!,
          );
        }
      } catch (_) {
        // Fallback seguro
      }
    }
  }

  @override
  void dispose() {
    _catalogVm?.dispose();
    _requestsVm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_catalogVm == null || _uid == null) {
      final l10n = AppLocalizations.of(context);
      return _ShellScreenBase(title: l10n?.navCatalog ?? '');
    }

    if (_showRequests && _requestsVm != null) {
      return Scaffold(
        body: MyRequestsView(viewModel: _requestsVm!),
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('back_to_catalog_fab'),
          onPressed: () {
            setState(() {
              _showRequests = false;
            });
          },
          icon: const Icon(Icons.arrow_back),
          label: Text(AppLocalizations.of(context)?.tabCatalog ?? ''),
        ),
      );
    }

    return CatalogView(
      viewModel: _catalogVm!,
      currentUid: _uid!,
      onNavigateToRequests: _requestsVm != null
          ? () {
              setState(() {
                _showRequests = true;
              });
            }
          : null,
    );
  }
}

class _BillingScreen extends StatefulWidget {
  const _BillingScreen();

  @override
  State<_BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<_BillingScreen> {
  MyProformasViewModel? _proformasVm;
  String? _uid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_proformasVm == null) {
      try {
        final proformasRepo = Provider.of<ProformasRepository?>(context, listen: false);
        final authRepo = Provider.of<AuthRepository?>(context, listen: false);
        _uid = authRepo?.currentUser?.uid;

        if (proformasRepo != null && _uid != null) {
          _proformasVm = MyProformasViewModel(
            repository: proformasRepo,
            clientId: _uid!,
          );
        }
      } catch (_) {
        // Fallback seguro
      }
    }
  }

  @override
  void dispose() {
    _proformasVm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_proformasVm == null || _uid == null) {
      final l10n = AppLocalizations.of(context);
      return _ShellScreenBase(title: l10n?.navBilling ?? '');
    }

    return MyProformasView(
      viewModel: _proformasVm!,
      onOpenCart: () => context.go(kCartRoute),
      onOpenPaymentSummary: () => context.go(kPaymentSummaryRoute),
    );
  }
}

class _CartScreen extends StatefulWidget {
  const _CartScreen();

  @override
  State<_CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<_CartScreen> {
  CartViewModel? _cartVm;
  String? _uid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cartVm == null) {
      try {
        final productRequestsRepo = Provider.of<ProductRequestsRepository?>(context, listen: false);
        final appointmentsRepo = Provider.of<AppointmentsRepository?>(context, listen: false);
        final catalogRepo = Provider.of<CatalogRepository?>(context, listen: false);
        final authRepo = Provider.of<AuthRepository?>(context, listen: false);
        _uid = authRepo?.currentUser?.uid;

        if (productRequestsRepo != null &&
            appointmentsRepo != null &&
            catalogRepo != null &&
            _uid != null) {
          _cartVm = CartViewModel(
            productRequestsRepository: productRequestsRepo,
            appointmentsRepository: appointmentsRepo,
            catalogRepository: catalogRepo,
            clientId: _uid!,
          );
        }
      } catch (_) {
        // Fallback seguro
      }
    }
  }

  @override
  void dispose() {
    _cartVm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cartVm == null || _uid == null) {
      final l10n = AppLocalizations.of(context);
      return _ShellScreenBase(title: l10n?.navCart ?? '');
    }

    return CartView(viewModel: _cartVm!);
  }
}

class _PaymentSummaryScreen extends StatefulWidget {
  const _PaymentSummaryScreen();

  @override
  State<_PaymentSummaryScreen> createState() => _PaymentSummaryScreenState();
}

class _PaymentSummaryScreenState extends State<_PaymentSummaryScreen> {
  PaymentSummaryViewModel? _summaryVm;
  String? _uid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_summaryVm == null) {
      try {
        final productRequestsRepo = Provider.of<ProductRequestsRepository?>(context, listen: false);
        final appointmentsRepo = Provider.of<AppointmentsRepository?>(context, listen: false);
        final catalogRepo = Provider.of<CatalogRepository?>(context, listen: false);
        final authRepo = Provider.of<AuthRepository?>(context, listen: false);
        _uid = authRepo?.currentUser?.uid;

        if (productRequestsRepo != null &&
            appointmentsRepo != null &&
            catalogRepo != null &&
            _uid != null) {
          _summaryVm = PaymentSummaryViewModel(
            productRequestsRepository: productRequestsRepo,
            appointmentsRepository: appointmentsRepo,
            catalogRepository: catalogRepo,
            clientId: _uid!,
          );
        }
      } catch (_) {
        // Fallback seguro
      }
    }
  }

  @override
  void dispose() {
    _summaryVm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_summaryVm == null || _uid == null) {
      final l10n = AppLocalizations.of(context);
      return _ShellScreenBase(title: l10n?.paymentSummaryTitle ?? '');
    }

    return PaymentSummaryView(viewModel: _summaryVm!);
  }
}

class _ChatScreen extends StatefulWidget {
  const _ChatScreen();

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  ChatViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      try {
        final chatRepo = Provider.of<ChatRepository?>(context, listen: false);
        final authRepo = Provider.of<AuthRepository?>(context, listen: false);
        final firestore = Provider.of<FirebaseFirestore?>(context, listen: false);
        final storageService = Provider.of<StorageService?>(context, listen: false);
        final uid = authRepo?.currentUser?.uid;
        if (chatRepo != null && uid != null && firestore != null) {
          _viewModel = ChatViewModel(
            chatRepository: chatRepo,
            chatId: uid,
            currentUid: uid,
            currentUserName: authRepo?.currentUser?.displayName ?? 'Cliente',
            currentUserRole: authRepo?.role ?? 'CLIENT',
            firestore: firestore,
            storageService: storageService ?? StorageService(),
          );
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel == null) {
      final l10n = AppLocalizations.of(context);
      return _ShellScreenBase(title: l10n?.navChat ?? 'Chat');
    }
    return ChatScreen(viewModel: _viewModel!);
  }
}



