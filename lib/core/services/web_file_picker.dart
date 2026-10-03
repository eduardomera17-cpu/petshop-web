// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/services/web_file_picker.dart
// Propósito: Exportación condicional y adaptativa del selector de archivos según la plataforma de ejecución.
// =========================================================================

export 'web_file_picker_stub.dart'
    if (dart.library.html) 'web_file_picker_web.dart';
