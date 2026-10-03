// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/governance/views/operating_parameters_view.dart
// Propósito: Vista de configuración global de parámetros de operación comercial, jornadas laborales y umbrales de alerta de inventario.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/features/admin/governance/view_models/governance_view_model.dart';

/// Pestaña de parametrización de variables globales del establecimiento.
///
/// Modela y persiste los ajustes operacionales del petshop:
/// - Horario comercial: horas oficiales de apertura y cierre diario (`HH:mm`).
/// - Duración canónica de las franjas de atención en minutos (15, 30, 45, 60).
/// - Días laborales de atención al público (lunes a domingo) mediante chips interactivos de selección múltiple.
/// - Umbral mínimo de existencias físicas para la activación automática de alertas de stock crítico.
class OperatingParametersView extends StatefulWidget {
  /// Modelo de vista reactivo gestor de la carga y persistencia de parámetros.
  final GovernanceViewModel viewModel;

  /// Constructor de la vista de parámetros operativos.
  const OperatingParametersView({
    super.key,
    required this.viewModel,
  });

  @override
  State<OperatingParametersView> createState() => _OperatingParametersViewState();
}


class _OperatingParametersViewState extends State<OperatingParametersView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _openingCtrl;
  late TextEditingController _closingCtrl;
  late TextEditingController _slotCtrl;
  late TextEditingController _thresholdCtrl;
  late Set<int> _selectedDays;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final params = widget.viewModel.operatingParameters;
    _openingCtrl = TextEditingController(text: params.openingTime);
    _closingCtrl = TextEditingController(text: params.closingTime);
    _slotCtrl = TextEditingController(text: params.slotDurationMinutes.toString());
    _thresholdCtrl = TextEditingController(text: params.lowStockThreshold.toString());
    _selectedDays = Set<int>.from(params.workingWeekdays);
    _initialized = true;
  }

  @override
  void didUpdateWidget(covariant OperatingParametersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel.operatingParameters != widget.viewModel.operatingParameters) {
      final params = widget.viewModel.operatingParameters;
      _openingCtrl.text = params.openingTime;
      _closingCtrl.text = params.closingTime;
      _slotCtrl.text = params.slotDurationMinutes.toString();
      _thresholdCtrl.text = params.lowStockThreshold.toString();
      _selectedDays = Set<int>.from(params.workingWeekdays);
    }
  }

  @override
  void dispose() {
    _openingCtrl.dispose();
    _closingCtrl.dispose();
    _slotCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (!_initialized && !widget.viewModel.isLoadingParams) {
          _initControllers();
        }

        if (widget.viewModel.isLoadingParams) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return ResponsiveLayout(
          builder: (context, breakpoint) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(breakpoint.isCompact ? 16.0 : 24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800.0),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(breakpoint.isCompact ? 16.0 : 28.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.settings, size: 28.0),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Text(
                                    l10n?.govOperatingParamsTitle ?? '',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              l10n?.govOperatingParamsDescription ?? '',
                              style: TextStyle(color: Theme.of(context).colorScheme.outline),
                            ),
                            const Divider(height: 32.0),

                            // INVARIANTE IN-03: Prohibido exponer cualquier input de zona horaria.

                            // Fila de Horarios: Apertura y Cierre
                            if (breakpoint.isCompact) ...[
                              _buildOpeningTimeField(l10n),
                              const SizedBox(height: 16.0),
                              _buildClosingTimeField(l10n),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(child: _buildOpeningTimeField(l10n)),
                                  const SizedBox(width: 16.0),
                                  Expanded(child: _buildClosingTimeField(l10n)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16.0),

                            // Fila de Duración de Franja y Umbral de Stock
                            if (breakpoint.isCompact) ...[
                              _buildSlotDurationField(l10n),
                              const SizedBox(height: 16.0),
                              _buildLowStockThresholdField(l10n),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(child: _buildSlotDurationField(l10n)),
                                  const SizedBox(width: 16.0),
                                  Expanded(child: _buildLowStockThresholdField(l10n)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 24.0),

                            // Días Laborables
                            Text(
                              l10n?.govFieldWorkingDays ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                            ),
                            const SizedBox(height: 10.0),
                            _buildWorkingDaysChips(l10n),
                            const SizedBox(height: 32.0),

                            // Botón de Guardado con área táctil >= 48x48
                            SizedBox(
                              height: 48.0,
                              child: ElevatedButton.icon(
                                key: const Key('save_operating_parameters_button'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  minimumSize: const Size.fromHeight(48.0),
                                ),
                                onPressed: widget.viewModel.isActionLoading ? null : _saveParameters,
                                icon: widget.viewModel.isActionLoading
                                    ? const SizedBox(
                                        width: 20.0,
                                        height: 20.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                  l10n?.govButtonSaveParams ?? '',
                                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOpeningTimeField(AppLocalizations? l10n) {
    return TextFormField(
      key: const Key('operating_opening_time'),
      controller: _openingCtrl,
      decoration: InputDecoration(
        labelText: l10n?.govFieldOpeningTime ?? '',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.access_time),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return l10n?.govValidationRequired ?? '';
        }
        if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(val.trim())) {
          return 'Formato requerido: HH:mm (ej. 08:00)';
        }
        return null;
      },
    );
  }

  Widget _buildClosingTimeField(AppLocalizations? l10n) {
    return TextFormField(
      key: const Key('operating_closing_time'),
      controller: _closingCtrl,
      decoration: InputDecoration(
        labelText: l10n?.govFieldClosingTime ?? '',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.access_time_filled),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return l10n?.govValidationRequired ?? '';
        }
        if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(val.trim())) {
          return 'Formato requerido: HH:mm (ej. 18:00)';
        }
        if (_openingCtrl.text.trim().isNotEmpty && val.trim().compareTo(_openingCtrl.text.trim()) <= 0) {
          return l10n?.govInvalidTimeOrder ?? '';
        }
        return null;
      },
    );
  }

  Widget _buildSlotDurationField(AppLocalizations? l10n) {
    return TextFormField(
      key: const Key('operating_slot_duration'),
      controller: _slotCtrl,
      decoration: InputDecoration(
        labelText: l10n?.govFieldSlotDuration ?? '',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.timer_outlined),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return l10n?.govValidationRequired ?? '';
        }
        final numVal = int.tryParse(val.trim());
        if (numVal == null || numVal <= 0) {
          return 'Debe ser un entero mayor a 0';
        }
        return null;
      },
    );
  }

  Widget _buildLowStockThresholdField(AppLocalizations? l10n) {
    return TextFormField(
      key: const Key('operating_low_stock_threshold'),
      controller: _thresholdCtrl,
      decoration: InputDecoration(
        labelText: l10n?.govFieldLowStockThreshold ?? '',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.warning_amber_outlined),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return l10n?.govValidationRequired ?? '';
        }
        final numVal = int.tryParse(val.trim());
        if (numVal == null || numVal < 0) {
          return 'Debe ser un entero mayor o igual a 0';
        }
        return null;
      },
    );
  }

  Widget _buildWorkingDaysChips(AppLocalizations? l10n) {
    final days = [
      {'val': 1, 'name': l10n?.govDayMonday ?? ''},
      {'val': 2, 'name': l10n?.govDayTuesday ?? ''},
      {'val': 3, 'name': l10n?.govDayWednesday ?? ''},
      {'val': 4, 'name': l10n?.govDayThursday ?? ''},
      {'val': 5, 'name': l10n?.govDayFriday ?? ''},
      {'val': 6, 'name': l10n?.govDaySaturday ?? ''},
      {'val': 7, 'name': l10n?.govDaySunday ?? ''},
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: days.map((d) {
        final dayVal = d['val'] as int;
        final dayName = d['name'] as String;
        final isSelected = _selectedDays.contains(dayVal);

        return FilterChip(
          key: Key('operating_day_chip_$dayVal'),
          label: Text(dayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(dayVal);
              } else {
                if (_selectedDays.length > 1) {
                  _selectedDays.remove(dayVal);
                }
              }
            });
          },
        );
      }).toList(),
    );
  }

  Future<void> _saveParameters() async {
    if (_formKey.currentState?.validate() != true) return;

    final sortedDays = _selectedDays.toList()..sort();
    final slot = int.parse(_slotCtrl.text.trim());
    final threshold = int.parse(_thresholdCtrl.text.trim());

    await widget.viewModel.updateOperatingParameters(
      openingTime: _openingCtrl.text.trim(),
      closingTime: _closingCtrl.text.trim(),
      slotDurationMinutes: slot,
      workingWeekdays: sortedDays,
      lowStockThreshold: threshold,
    );
  }
}
