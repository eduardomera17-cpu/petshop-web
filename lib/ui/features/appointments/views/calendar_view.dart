// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/appointments/views/calendar_view.dart
// Propósito: Selector horizontal de fechas del calendario operativo del negocio, con validación de días hábiles y ventana deslizante de disponibilidad.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/appointments/view_models/booking_view_model.dart';

/// Componente de selección de fecha basado en el calendario y horario operativo del establecimiento.
///
/// Proyecta una ventana móvil de los próximos 21 días de negocio a partir de la fecha
/// provista por [BusinessClock.now()]. Evalúa dinámicamente si cada día de la semana
/// se encuentra dentro del conjunto de días laborables configurados ([OperatingConfig.workingWeekdays]),
/// inhabilitando automáticamente fines de semana o jornadas no operativas.
class CalendarView extends StatelessWidget {
  /// Modelo de vista de reserva que provee la configuración operativa y custodia la fecha elegida.
  final BookingViewModel viewModel;

  /// Constructor del selector de fecha en calendario.
  const CalendarView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final currentNow = BusinessClock.now();
    final todayStr = BusinessClock.todayBusinessDate();

    // Proyección de la ventana operativa de los próximos 21 días de negocio para reserva
    final candidateDays = <String>[];
    for (var i = 0; i < 21; i++) {
      final candidateDate = currentNow.add(Duration(days: i));
      final dateStr = BusinessClock.toBusinessDate(candidateDate);
      candidateDays.add(dateStr);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            l10n?.selectDateLabel ?? '',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 84.0,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: candidateDays.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8.0),
            itemBuilder: (context, index) {
              final dateStr = candidateDays[index];
              final parts = dateStr.split('-').map(int.parse).toList();
              final dt = DateTime(parts[0], parts[1], parts[2]);

              final isWorkingDay = viewModel.operatingConfig.workingWeekdays.contains(dt.weekday);
              final isSelected = viewModel.selectedDate == dateStr;
              final isToday = dateStr == todayStr;

              return _DayChip(
                key: Key('day_chip_$dateStr'),
                dateString: dateStr,
                dayNumber: dt.day,
                weekday: dt.weekday,
                isToday: isToday,
                isSelected: isSelected,
                isWorkingDay: isWorkingDay,
                onTap: isWorkingDay ? () => viewModel.selectDate(dateStr) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Chip individual representativo de un día en el calendario de reserva.
///
/// Refleja visualmente estados de selección, día actual (hoy) y disponibilidad operativa.
class _DayChip extends StatelessWidget {
  /// Cadena en formato ISO 'YYYY-MM-DD' de la fecha representada.
  final String dateString;

  /// Número ordinal del día dentro del mes.
  final int dayNumber;

  /// Constante entera del día de la semana (1 = lunes, ..., 7 = domingo).
  final int weekday;

  /// Indica si la fecha coincide con el día de negocio actual del sistema.
  final bool isToday;

  /// Indica si la fecha es la que se encuentra actualmente seleccionada en el ViewModel.
  final bool isSelected;

  /// Indica si el día de la semana corresponde a una jornada laborable del petshop.
  final bool isWorkingDay;

  /// Callback ejecutado al pulsar sobre el chip si el día se encuentra habilitado.
  final VoidCallback? onTap;

  /// Constructor del chip de día en el calendario.
  const _DayChip({
    super.key,
    required this.dateString,
    required this.dayNumber,
    required this.weekday,
    required this.isToday,
    required this.isSelected,
    required this.isWorkingDay,
    this.onTap,
  });

  /// Traduce el código numérico de día de la semana a su abreviatura en español.
  String _getWeekdayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Lun',
      DateTime.tuesday => 'Mar',
      DateTime.wednesday => 'Mié',
      DateTime.thursday => 'Jue',
      DateTime.friday => 'Vie',
      DateTime.saturday => 'Sáb',
      DateTime.sunday => 'Dom',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekdayName = _getWeekdayName(weekday);

    Color bgColor;
    Color textColor;
    Border? border;

    if (!isWorkingDay) {
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade400;
    } else if (isSelected) {
      bgColor = theme.primaryColor;
      textColor = Colors.white;
    } else {
      bgColor = Colors.white;
      textColor = isToday ? theme.primaryColor : Colors.black87;
      border = Border.all(
        color: isToday ? theme.primaryColor : Colors.grey.shade300,
        width: isToday ? 2.0 : 1.0,
      );
    }

    return TappableArea(
      onTap: onTap ?? () {},
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: onTap,
        child: Container(
          width: 56.0,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12.0),
            border: border,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekdayName,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                dayNumber.toString(),
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
