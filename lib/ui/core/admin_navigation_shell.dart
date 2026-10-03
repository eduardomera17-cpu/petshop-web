// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/core/admin_navigation_shell.dart
// Propósito: Armazón de navegación adaptativo y persistente del panel administrativo (Drawer expandido, NavigationRail medio y Drawer modal compacto).
// =========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';

/// {@template admin_destination}
/// Definición estructurada de un destino de navegación dentro del panel de administración.
/// {@endtemplate}
class AdminDestination {
  /// Ruta relativa o absoluta registrada en el GoRouter.
  final String route;

  /// Icono en estado inactivo o por defecto.
  final IconData icon;

  /// Icono destacado en estado activo/seleccionado.
  final IconData selectedIcon;

  /// Función generadora de la etiqueta localizada.
  final String Function(AppLocalizations? l10n) label;

  /// Indica si el destino está reservado exclusivamente para cuentas con rol SUPERADMIN.
  final bool superAdminOnly;

  /// Constructor inmutable de un destino de navegación administrativo.
  const AdminDestination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.superAdminOnly = false,
  });
}

String _lPanel(AppLocalizations? l) => l?.navAdminDashboard ?? '';
String _lAgenda(AppLocalizations? l) => l?.navAdminAgenda ?? '';
String _lClients(AppLocalizations? l) => l?.navAdminClients ?? '';
String _lChat(AppLocalizations? l) => l?.navChat ?? '';
String _lServices(AppLocalizations? l) => l?.navAdminServices ?? '';
String _lProducts(AppLocalizations? l) => l?.navAdminProducts ?? '';
String _lInventory(AppLocalizations? l) => l?.navAdminInventory ?? '';
String _lRequests(AppLocalizations? l) => l?.navAdminRequests ?? '';
String _lProformas(AppLocalizations? l) => l?.navAdminProformas ?? '';
String _lGovernance(AppLocalizations? l) => l?.navAdminGovernance ?? '';
String _lProfile(AppLocalizations? l) => l?.navProfile ?? '';

/// Colección inmutable de todos los destinos de navegación del panel administrativo en orden jerárquico.
const List<AdminDestination> kAdminDestinations = <AdminDestination>[
  AdminDestination(route: '/admin', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: _lPanel),
  AdminDestination(route: '/admin/agenda', icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: _lAgenda),
  AdminDestination(route: '/admin/clients', icon: Icons.people_outline, selectedIcon: Icons.people, label: _lClients),
  AdminDestination(route: '/admin/chat', icon: Icons.forum_outlined, selectedIcon: Icons.forum, label: _lChat),
  AdminDestination(route: '/admin/services', icon: Icons.design_services_outlined, selectedIcon: Icons.design_services, label: _lServices),
  AdminDestination(route: '/admin/products', icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: _lProducts),
  AdminDestination(route: '/admin/inventory', icon: Icons.warehouse_outlined, selectedIcon: Icons.warehouse, label: _lInventory),
  AdminDestination(route: '/admin/requests', icon: Icons.assignment_outlined, selectedIcon: Icons.assignment, label: _lRequests),
  AdminDestination(route: '/admin/proformas', icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: _lProformas),
  AdminDestination(route: '/admin/governance', icon: Icons.admin_panel_settings_outlined, selectedIcon: Icons.admin_panel_settings, label: _lGovernance, superAdminOnly: true),
  AdminDestination(route: '/admin/profile', icon: Icons.account_circle_outlined, selectedIcon: Icons.account_circle, label: _lProfile),
];

/// {@template admin_navigation_shell}
/// Envoltorio de navegación persistente y adaptativo para las rutas de administración.
///
/// Implementa un patrón de navegación responsivo basado en [ResponsiveLayout] (TRD §1.3.4):
/// - En pantallas anchas/expandidas (>= 840 dp): NavigationDrawer lateral persistente con ancho acotado.
/// - En pantallas intermedias (600 - 839 dp): NavigationRail deslizable para evitar desbordes en doce destinos.
/// - En pantallas compactas (< 600 dp): Drawer modal accesible mediante icono de menú superior.
/// Integra control de visibilidad por rol (SUPERADMIN) y botón transversal de cierre de sesión.
/// {@endtemplate}
class AdminNavigationShell extends StatelessWidget {
  /// Widget secundario o pantalla hija renderizada dentro del área de contenido.
  final Widget child;

  /// Ubicación o ruta activa actual en el enrutador.
  final String location;

  /// Rol del usuario autenticado (ADMIN o SUPERADMIN) para control de accesos.
  final String? role;

  /// Callback asíncrono para ejecutar el cierre de sesión institucional.
  final Future<void> Function() onSignOut;

  const AdminNavigationShell({
    super.key,
    required this.child,
    required this.location,
    required this.role,
    required this.onSignOut,
  });

  bool get _isStaff => role == 'ADMIN' || role == 'SUPERADMIN';

  List<AdminDestination> get _visible => kAdminDestinations
      .where((d) => !d.superAdminOnly || role == 'SUPERADMIN')
      .toList();

  int get _selectedIndex {
    final visibles = _visible;
    // La ruta raíz del panel sólo coincide de forma exacta; el resto admite subrutas.
    for (var i = visibles.length - 1; i >= 0; i--) {
      final route = visibles[i].route;
      if (route == '/admin') continue;
      if (location == route || location.startsWith('$route/')) return i;
    }
    return 0;
  }

  void _go(BuildContext context, int index) {
    final destino = _visible[index].route;
    if (destino != location) context.go(destino);
  }

  Widget _signOutButton(AppLocalizations? l10n) {
    final texto = l10n?.navSignOut ?? '';
    return TappableArea(
      key: const Key('admin_sign_out_button'),
      tooltip: texto,
      semanticLabel: texto,
      onTap: onSignOut,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: Icon(Icons.logout),
      ),
    );
  }

  Widget _drawer(BuildContext context, AppLocalizations? l10n) {
    final visibles = _visible;
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: const Color(0xFF0F3A4A),
      ),
      child: NavigationDrawer(
        key: const Key('admin_navigation_drawer'),
        backgroundColor: const Color(0xFF0F3A4A),
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF1E5162),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => _go(context, i),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E5162),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: const Icon(Icons.pets, color: Colors.white, size: 20.0),
                ),
                const SizedBox(width: 12.0),
                const Text(
                  'PetShop Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E5162), height: 1.0),
          const SizedBox(height: 12.0),
          for (var i = 0; i < visibles.length; i++)
            NavigationDrawerDestination(
              icon: Icon(
                visibles[i].icon,
                color: i == _selectedIndex ? Colors.white : const Color(0xFF94A3B8),
              ),
              selectedIcon: Icon(visibles[i].selectedIcon, color: Colors.white),
              label: Text(
                visibles[i].label(l10n),
                style: TextStyle(
                  color: i == _selectedIndex ? Colors.white : const Color(0xFF94A3B8),
                  fontWeight: i == _selectedIndex ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          const Divider(color: Color(0xFF1E5162), indent: 16.0, endIndent: 16.0),
          ListTile(
            key: const Key('admin_drawer_sign_out'),
            leading: const Icon(Icons.logout, color: Color(0xFF94A3B8)),
            title: Text(
              l10n?.navSignOut ?? '',
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }

  /// Cajon de ancho compacto.
  ///
  /// Se construye con lista en lugar de `NavigationDrawer` porque este ultimo
  /// reclama su ancho intrinseco de Material y desborda cuando la pantalla no se
  /// lo concede. La lista se adapta al ancho disponible y ademas puede
  /// desplazarse con doce destinos.
  Widget _compactDrawer(BuildContext context, AppLocalizations? l10n) {
    final visibles = _visible;
    final seleccionado = _selectedIndex;
    return Drawer(
      key: const Key('admin_navigation_drawer_modal'),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
            for (var i = 0; i < visibles.length; i++)
              ListTile(
                leading: Icon(i == seleccionado ? visibles[i].selectedIcon : visibles[i].icon),
                title: Text(visibles[i].label(l10n), overflow: TextOverflow.ellipsis),
                selected: i == seleccionado,
                onTap: () {
                  Navigator.of(context).pop();
                  _go(context, i);
                },
              ),
            const Divider(),
            ListTile(
              key: const Key('admin_drawer_sign_out'),
              leading: const Icon(Icons.logout),
              title: Text(l10n?.navSignOut ?? '', overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.of(context).pop();
                onSignOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // El armazón es exclusivo del personal; un cliente que alcance una ruta de
    // administración es desviado por el guardián antes de llegar aquí.
    if (!_isStaff) return child;

    return ResponsiveLayout(
      builder: (context, breakpoint) {
        if (breakpoint.isExpanded) {
          return Scaffold(
            body: Row(
              children: [
                // Ancho acotado: sin el, el cajon reclama su medida natural y
                // desborda el Row en anchos justos.
                SizedBox(
                  width: 360.0,
                  child: _drawer(context, l10n),
                ),
                const VerticalDivider(width: 1.0, thickness: 1.0),
                Expanded(child: child),
              ],
            ),
          );
        }

        if (breakpoint.isMedium) {
          return Scaffold(
            body: Row(
              children: [
                // NavigationRail no desplaza por si mismo: con doce destinos
                // desborda en verticales cortas. Se envuelve en un area
                // desplazable que conserva la altura minima del contenedor.
                LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          key: const Key('admin_navigation_rail'),
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (i) => _go(context, i),
                          labelType: NavigationRailLabelType.all,
                          destinations: [
                            for (final d in _visible)
                              NavigationRailDestination(
                                icon: Icon(d.icon),
                                selectedIcon: Icon(d.selectedIcon),
                                label: Text(d.label(l10n)),
                              ),
                          ],
                          trailing: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: _signOutButton(l10n),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1.0, thickness: 1.0),
                Expanded(child: child),
              ],
            ),
          );
        }

        // Compacto: cajón modal. Doce destinos no caben en una barra inferior.
        return Scaffold(
          key: const Key('admin_compact_scaffold'),
          drawer: _compactDrawer(context, l10n),
          appBar: AppBar(
            title: Text(l10n?.navAdmin ?? ''),
            actions: [_signOutButton(l10n)],
          ),
          body: child,
        );
      },
    );
  }
}
