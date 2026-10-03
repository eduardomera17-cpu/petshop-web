// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/proformas/views/admin_proformas_screen.dart
// Propósito: Pantalla adaptadora e integradora de dependencias para el módulo administrativo de proformas y facturación comercial.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/repositories/agenda_repository.dart';
import 'package:mipetshop/data/repositories/proformas_repository.dart';
import 'package:mipetshop/domain/use_cases/preview_proforma_pricing.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/proformas/view_models/admin_proformas_view_model.dart';
import 'package:mipetshop/ui/features/admin/proformas/view_models/billing_config_view_model.dart';
import 'package:mipetshop/ui/features/admin/proformas/views/admin_proformas_list_view.dart';
import 'package:mipetshop/ui/features/admin/proformas/views/pending_concepts_view.dart';

/// Pantalla adaptadora que resuelve las dependencias de facturación ([ProformasRepository], [AgendaRepository],
/// [AuthRepository]), construye los ViewModels ([AdminProformasViewModel] y [BillingConfigViewModel]) y
/// enlaza el caso de uso [PreviewProformaPricingUseCase] con [AdminProformasListView].
class AdminProformasScreen extends StatefulWidget {
  /// Constructor del adaptador de pantalla de proformas administrativas.
  const AdminProformasScreen({super.key});

  @override
  State<AdminProformasScreen> createState() => _AdminProformasScreenState();
}

/// Estado interactivo de [AdminProformasScreen] a cargo de coordinar el ciclo de vida de los ViewModels de facturación.
class _AdminProformasScreenState extends State<AdminProformasScreen> {
  /// Modelo de vista reactivo gestor del listado y operaciones sobre proformas.
  AdminProformasViewModel? _proformasVm;

  /// Modelo de vista reactivo gestor de los parámetros fiscales y tributarios.
  BillingConfigViewModel? _billingVm;

  /// Repositorio de acceso a datos para proformas comerciales.
  ProformasRepository? _proformasRepo;

  /// Repositorio para la consulta en tiempo real de clientes elegibles.
  AgendaRepository? _agendaRepo;

  /// Identificador único del miembro del personal autenticado.
  String? _uid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_proformasVm == null) {
      try {
        final proformasRepo = Provider.of<ProformasRepository?>(context, listen: false);
        final authRepo = Provider.of<AuthRepository?>(context, listen: false);
        if (proformasRepo != null) {
          _proformasVm = AdminProformasViewModel(proformasRepository: proformasRepo);
          _billingVm = BillingConfigViewModel(proformasRepository: proformasRepo);
          _proformasRepo = proformasRepo;
          _agendaRepo = Provider.of<AgendaRepository?>(context, listen: false);
          _uid = authRepo?.currentUser?.uid;
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _proformasVm?.dispose();
    _billingVm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<AuthRepository?>(context, listen: false);
    final currentUid = _uid ?? authRepo?.currentUser?.uid;

    if (_proformasVm == null ||
        _billingVm == null ||
        _proformasRepo == null ||
        _agendaRepo == null ||
        currentUid == null) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.adminProformasTitle ?? '')),
        body: const Center(child: Icon(Icons.pets, size: 64.0)),
      );
    }
    return AdminProformasListView(
      viewModel: _proformasVm!,
      billingConfigViewModel: _billingVm!,
      currentUid: currentUid,
      previewUseCase: const PreviewProformaPricingUseCase(),
      pricingConfig: const PublicPricingConfig(ivaBp: 1500, iceIncludedInIvaBase: true),
      proformasRepository: _proformasRepo!,
      clientsStream: (query) => _agendaRepo!
          .streamClients(prefixQuery: query.isEmpty ? null : query)
          .map((clientes) => clientes
              .map((c) => ProformaClientOption(
                    uid: c.uid,
                    fullName: c.fullName,
                    email: c.email,
                  ))
              .toList()),
    );
  }
}
