// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/core/client_navigation_shell.dart
// Propósito: Armazón de navegación adaptativo y persistente del portal de clientes (NavigationBar en móvil, NavigationRail en tablet y NavigationDrawer en desktop).
// =========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';

/// {@template client_destination}
/// Definición estructurada de un destino de navegación accesible para usuarios con rol de cliente.
/// {@endtemplate}
class ClientDestination {
  /// Ruta de destino registrada en el enrutador de la aplicación.
  final String route;

  /// Icono en estado inactivo.
  final IconData icon;

  /// Icono en estado activo / seleccionado.
  final IconData selectedIcon;

  /// Función generadora del texto localizado obtenido del catálogo `.arb`.
  final String Function(AppLocalizations? l10n) label;

  /// Constructor inmutable de un destino de cliente.
  const ClientDestination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Lista inmutable de destinos del panel de cliente, en el orden de presentación de la interfaz.
const List<ClientDestination> kClientDestinations = <ClientDestination>[
  ClientDestination(
    route: '/',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: _labelHome,
  ),
  ClientDestination(
    route: '/pets',
    icon: Icons.pets_outlined,
    selectedIcon: Icons.pets,
    label: _labelPets,
  ),
  ClientDestination(
    route: '/appointments',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
    label: _labelAppointments,
  ),
  ClientDestination(
    route: '/catalog',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
    label: _labelCatalog,
  ),
  ClientDestination(
    route: '/billing',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    label: _labelBilling,
  ),
  ClientDestination(
    route: '/chat',
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum,
    label: _labelChat,
  ),
  ClientDestination(
    route: '/profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: _labelProfile,
  ),
];

String _labelHome(AppLocalizations? l10n) => l10n?.navHome ?? '';
String _labelPets(AppLocalizations? l10n) => l10n?.navPets ?? '';
String _labelAppointments(AppLocalizations? l10n) => l10n?.navAppointments ?? '';
String _labelCatalog(AppLocalizations? l10n) => l10n?.navCatalog ?? '';
String _labelBilling(AppLocalizations? l10n) => l10n?.navBilling ?? '';
String _labelChat(AppLocalizations? l10n) => l10n?.navChat ?? '';
String _labelProfile(AppLocalizations? l10n) => l10n?.navProfile ?? '';

/// {@template client_navigation_shell}
/// Envoltorio de navegación persistente y adaptativo para las rutas del cliente.
///
/// Implementa un patrón de navegación responsivo conforme a TRD §1.3.4 mediante [ResponsiveLayout]:
/// - Pantallas compactas (< 600 dp): [NavigationBar] fija en la parte inferior con etiquetas continuas.
/// - Pantallas medianas (600 - 1023 dp): [NavigationRail] lateral izquierdo.
/// - Pantallas expandidas (>= 1024 dp): [NavigationDrawer] permanente con división vertical.
/// Garantiza la accesibilidad permanente a citas, mascotas, catálogo, facturación y mensajería.
/// {@endtemplate}
class ClientNavigationShell extends StatelessWidget {
  /// Contenido o pantalla hija a mostrar dentro del área principal de la interfaz.
  final Widget child;

  /// Ruta actual activa en el enrutador para reflejar la selección en la barra o riel.
  final String location;

  /// Rol del usuario autenticado en sesión, validado para mostrar esta barra solo al rol CLIENT.
  final String? role;

  const ClientNavigationShell({
    super.key,
    required this.child,
    required this.location,
    required this.role,
  });

  int get _selectedIndex {
    // La ruta raíz sólo coincide de forma exacta; las demás admiten subrutas.
    for (var i = kClientDestinations.length - 1; i >= 0; i--) {
      final route = kClientDestinations[i].route;
      if (route == '/') continue;
      if (location == route || location.startsWith('$route/')) return i;
    }
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    final destination = kClientDestinations[index].route;
    if (destination != location) context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // El armazon es exclusivo del cliente. El personal que alcance /profile
    // conserva su propia navegacion y no recibe destinos que no le competen.
    if (role != 'CLIENT') return child;

    return ResponsiveLayout(
      builder: (context, breakpoint) {
        if (breakpoint.isCompact) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              key: const Key('client_navigation_bar'),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => _onDestinationSelected(context, i),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final d in kClientDestinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label(l10n),
                    tooltip: d.label(l10n),
                  ),
              ],
            ),
          );
        }

        if (breakpoint.isMedium) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  key: const Key('client_navigation_rail'),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) => _onDestinationSelected(context, i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in kClientDestinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label(l10n)),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1.0, thickness: 1.0),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationDrawer(
                key: const Key('client_navigation_drawer'),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                indicatorColor: const Color(0xFFE0F2FE),
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) => _onDestinationSelected(context, i),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: const Icon(Icons.pets, color: Colors.white, size: 20.0),
                        ),
                        const SizedBox(width: 12.0),
                        const Text(
                          'PetShop',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 18.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 1.0),
                  const SizedBox(height: 12.0),
                  for (var i = 0; i < kClientDestinations.length; i++)
                    NavigationDrawerDestination(
                      icon: Icon(
                        kClientDestinations[i].icon,
                        color: i == _selectedIndex ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                      ),
                      selectedIcon: Icon(
                        kClientDestinations[i].selectedIcon,
                        color: const Color(0xFF0284C7),
                      ),
                      label: Text(
                        kClientDestinations[i].label(l10n),
                        style: TextStyle(
                          color: i == _selectedIndex ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                          fontWeight: i == _selectedIndex ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const VerticalDivider(width: 1.0, thickness: 1.0, color: Color(0xFFE2E8F0)),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 56.0,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: const Row(
                        children: [
                          Spacer(),
                          CircleAvatar(
                            radius: 16.0,
                            backgroundColor: Color(0xFF0284C7),
                            child: Text(
                              'EM',
                              style: TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
