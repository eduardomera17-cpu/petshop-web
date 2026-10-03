// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'PetShop Web';

  @override
  String get imageFormatUnsupported =>
      'El formato del archivo no es compatible. Solo se admiten imágenes en formato JPEG, PNG, WebP y AVIF.';

  @override
  String get imageFormatHeicRejected =>
      'Los archivos en formato de alta eficiencia (HEIC/HEIF) no están admitidos. Por favor, selecciona una imagen en formato JPEG, PNG, WebP o AVIF.';

  @override
  String get imageSizeExceeded =>
      'El archivo excede el tamaño máximo permitido de 5 MB.';

  @override
  String get loading => 'Cargando...';

  @override
  String get loadingSession => 'Verificando sesión...';

  @override
  String get retry => 'Reintentar';

  @override
  String get close => 'Cerrar';

  @override
  String get accept => 'Aceptar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get offlineBannerMessage =>
      'Sin conexión a Internet. Las acciones están deshabilitadas para proteger la integridad de los datos.';

  @override
  String get connectionRestored => 'Conexión restablecida.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navPets => 'Mis Mascotas';

  @override
  String get navAppointments => 'Citas';

  @override
  String get navCatalog => 'Catálogo';

  @override
  String get navBilling => 'Facturación';

  @override
  String get navChat => 'Mensajería';

  @override
  String get navProfile => 'Mi Perfil';

  @override
  String get navAdmin => 'Panel de Administración';

  @override
  String get navAdminAgenda => 'Agenda General';

  @override
  String get navAdminGovernance => 'Gobierno y Cuentas';

  @override
  String get navLogin => 'Iniciar Sesión';

  @override
  String get navRegister => 'Registrarse';

  @override
  String get navForgotPassword => 'Recuperar Contraseña';

  @override
  String get navSignOut => 'Cerrar Sesión';

  @override
  String get unauthorizedAdminAccess => 'No tienes permisos de administrador.';

  @override
  String get unauthorizedGovernanceAccess =>
      'No tienes permisos para acceder al módulo de gobierno.';

  @override
  String get unauthorizedGeneral =>
      'No tienes autorización para acceder a esta sección.';

  @override
  String get sessionExpired =>
      'Tu sesión ha expirado o requiere reautenticación.';

  @override
  String get errorGeneric =>
      'Ha ocurrido un error inesperado. Por favor, intenta nuevamente.';

  @override
  String get errorNetwork =>
      'Error de conexión. Por favor, revisa tu acceso a internet.';

  @override
  String get errorSlotTaken =>
      'El horario seleccionado ya no se encuentra disponible.';

  @override
  String get errorPetAlreadyBookedThatDay =>
      'La mascota ya cuenta con una cita programada para ese día.';

  @override
  String get errorSlotBlocked =>
      'El horario seleccionado se encuentra bloqueado para reservas.';

  @override
  String get errorAppointmentNotReschedulable =>
      'La cita no se puede reagendar en su estado actual.';

  @override
  String get errorProformaEmpty =>
      'La proforma debe contener al menos un concepto.';

  @override
  String get errorTooManyItems =>
      'Se ha excedido el límite máximo de elementos permitidos.';

  @override
  String get errorTooManyAttachments =>
      'Se ha excedido el límite máximo de adjuntos permitidos.';

  @override
  String get errorDailyLimitAppointments =>
      'Has alcanzado el límite diario de citas permitidas.';

  @override
  String get errorDailyLimitRequests =>
      'Has alcanzado el límite diario de solicitudes permitidas.';

  @override
  String get errorOutOfStock => 'El producto solicitado está agotado.';

  @override
  String get errorAppointmentNotCancellable =>
      'La cita ya no puede ser cancelada.';

  @override
  String get errorAlreadyCancelled => 'La cita ya fue cancelada anteriormente.';

  @override
  String get errorPetNotAvailable =>
      'La mascota seleccionada no está disponible o no se encuentra activa.';

  @override
  String get errorServiceNotAvailable =>
      'El servicio seleccionado no está disponible en este momento.';

  @override
  String get errorConfigUnavailable =>
      'No se pudo cargar la configuración del sistema. Intenta de nuevo.';

  @override
  String get errorPetAlreadyDeactivated =>
      'La mascota ya ha sido dada de baja previamente.';

  @override
  String get errorNoChange =>
      'No se han detectado cambios respecto al estado original.';

  @override
  String get errorInvalidTransition =>
      'La operación solicitada no es válida para el estado actual.';

  @override
  String get errorConceptLockedByDeliveredProforma =>
      'El concepto no puede modificarse porque está incluido en una proforma entregada.';

  @override
  String get errorProformaNotDraft =>
      'La proforma solo puede modificarse mientras esté en borrador.';

  @override
  String get errorProformaNotVoidable =>
      'La proforma no puede ser anulada en su estado actual.';

  @override
  String get errorDeliveryInProgress =>
      'Hay una entrega en progreso para este concepto.';

  @override
  String get errorDeliveryLeaseLost =>
      'Se perdió el bloqueo exclusivo de entrega. Intenta nuevamente.';

  @override
  String get errorConceptNoLongerValid =>
      'El concepto ya no es válido para su procesamiento.';

  @override
  String get errorEntryAnnulledNotEditable =>
      'Una entrada anulada no puede ser modificada.';

  @override
  String get errorAnnulmentNotAnnullable =>
      'Una entrada de anulación no puede ser anulada.';

  @override
  String get errorSuperadminImmutable =>
      'La cuenta de Super Administrador no puede ser modificada por esta vía.';

  @override
  String get errorRoleChangeNotSupported =>
      'No se permite el cambio de rol en la cuenta.';

  @override
  String get errorReauthRequired =>
      'Por seguridad, debes volver a iniciar sesión para realizar esta acción.';

  @override
  String get errorAccountNotActive =>
      'Tu cuenta se encuentra inactiva o deshabilitada. Contacta al soporte.';

  @override
  String get errorProfileAlreadyComplete =>
      'El perfil de usuario ya ha sido completado anteriormente.';

  @override
  String get errorAccountProvisioningFailed =>
      'Error al crear la cuenta. Por favor, intenta de nuevo.';

  @override
  String get errorStaffReactivationRequiresSuperadmin =>
      'La reactivación de cuentas de personal requiere permisos de Super Usuario.';

  @override
  String get errorVerificationRequired =>
      'Es obligatorio completar la verificación de seguridad.';

  @override
  String get errorVerificationFailed =>
      'La verificación de seguridad no fue superada o ha caducado. Intenta de nuevo.';

  @override
  String get errorVerificationActionMismatch =>
      'La verificación de seguridad no coincide con la acción solicitada.';

  @override
  String get errorVerificationHighRisk =>
      'No se pudo validar la solicitud por motivos de seguridad.';

  @override
  String get errorVerificationUnavailable =>
      'El servicio de verificación de seguridad no está disponible momentáneamente.';

  @override
  String get errorInvalidStockAdjustment =>
      'El ajuste solicitado dejaría el inventario en un valor negativo.';

  @override
  String get errorRequestLockedByDeliveredProforma =>
      'La solicitud está vinculada a una proforma entregada.';

  @override
  String get errorEmptyRequest =>
      'Debes seleccionar al menos un producto para enviar la solicitud.';

  @override
  String errorTooManyRequestLines(int max) {
    return 'No puedes solicitar más de $max productos distintos a la vez.';
  }

  @override
  String get errorDuplicateProductLine =>
      'Hay productos duplicados en la solicitud.';

  @override
  String errorInvalidQuantity(int max) {
    return 'La cantidad de cada producto debe estar entre 1 y $max unidades.';
  }

  @override
  String get errorProductNotAvailable =>
      'Uno o más productos ya no están disponibles en el catálogo.';

  @override
  String errorProductNotAvailableNamed(String products) {
    return 'Ya no están disponibles en el catálogo: $products.';
  }

  @override
  String errorOutOfStockNamed(String products) {
    return 'Están agotados: $products.';
  }

  @override
  String get errorInsufficientStock =>
      'No hay existencias suficientes para la cantidad solicitada.';

  @override
  String errorInsufficientStockNamed(String products) {
    return 'No hay existencias suficientes para la cantidad solicitada de: $products.';
  }

  @override
  String get errorInvalidCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get forgotPasswordConfirmation =>
      'Si la cuenta existe, se ha enviado un correo con instrucciones para restablecer tu contraseña.';

  @override
  String get changePasswordSuccess => 'Contraseña actualizada exitosamente.';

  @override
  String get emailLabel => 'Correo Electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get confirmPasswordLabel => 'Confirmar Contraseña';

  @override
  String get fullNameLabel => 'Nombre Completo';

  @override
  String get phoneLabel => 'Teléfono';

  @override
  String get documentTypeLabel => 'Tipo de Documento';

  @override
  String get documentNumberLabel => 'Número de Documento';

  @override
  String get addressLabel => 'Dirección';

  @override
  String get currentPasswordLabel => 'Contraseña Actual';

  @override
  String get newPasswordLabel => 'Nueva Contraseña';

  @override
  String get confirmNewPasswordLabel => 'Confirmar Nueva Contraseña';

  @override
  String get createAccountAction => 'Crear Cuenta';

  @override
  String get loginAction => 'Ingresar';

  @override
  String get sendResetInstructionsAction => 'Enviar Instrucciones';

  @override
  String get changePasswordAction => 'Cambiar Contraseña';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta? Inicia sesión';

  @override
  String get dontHaveAccount => '¿No tienes una cuenta? Regístrate';

  @override
  String get forgotPasswordLink => '¿Olvidaste tu contraseña?';

  @override
  String get verificationCheckboxLabel => 'No soy un robot';

  @override
  String get verificationSuccess => 'Verificación completada';

  @override
  String get verificationFailed => 'Error de verificación';

  @override
  String get verifying => 'Verificando...';

  @override
  String get backToLogin => 'Volver a Iniciar Sesión';

  @override
  String get docTypeCedula => 'Cédula';

  @override
  String get docTypeRuc => 'RUC';

  @override
  String get docTypePassport => 'Pasaporte';

  @override
  String get resetPasswordTitle => 'Restablecer Contraseña';

  @override
  String get validationEmailRequired => 'El correo es obligatorio.';

  @override
  String get validationEmailInvalid => 'Correo electrónico inválido.';

  @override
  String get validationPasswordRequired => 'La contraseña es obligatoria.';

  @override
  String get validationPasswordMinLength =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get validationPasswordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get validationCurrentPasswordRequired =>
      'Debes ingresar tu contraseña actual para continuar.';

  @override
  String get validationFullNameRequired =>
      'El nombre completo es obligatorio y debe tener entre 1 y 100 caracteres.';

  @override
  String get validationPhoneRequired =>
      'El teléfono de contacto es obligatorio.';

  @override
  String get validationPhoneInvalid =>
      'El teléfono de contacto debe tener formato ecuatoriano (+593 seguido de 9 dígitos).';

  @override
  String get validationDocTypeInvalid =>
      'El tipo de documento debe ser CEDULA, PASSPORT o RUC.';

  @override
  String get validationDocNumberRequired =>
      'El número de documento es obligatorio.';

  @override
  String get validationCedulaInvalid =>
      'La cédula debe contener exactamente 10 dígitos numéricos.';

  @override
  String get validationRucInvalid =>
      'El RUC debe contener exactamente 13 dígitos numéricos.';

  @override
  String get validationPassportInvalid =>
      'El pasaporte debe contener entre 5 y 20 caracteres alfanuméricos.';

  @override
  String get validationDocNumberInvalid =>
      'El número de documento no es válido para el tipo seleccionado.';

  @override
  String get validationAddressRequired =>
      'La dirección es obligatoria y debe tener entre 1 y 200 caracteres.';

  @override
  String get validationAddressMaxLength =>
      'La dirección no puede exceder los 200 caracteres.';

  @override
  String get errorEmailAlreadyInUse => 'El correo ya se encuentra registrado.';

  @override
  String get errorInvalidProfileData => 'Los datos del perfil no son válidos.';

  @override
  String get errorCurrentPasswordIncorrect =>
      'La contraseña actual ingresada es incorrecta.';

  @override
  String get errorVerifyCurrentPassword =>
      'Error al verificar la contraseña actual.';

  @override
  String get errorUpdatePassword => 'Error al actualizar la contraseña.';

  @override
  String get errorCompleteProfile => 'Error al completar el perfil.';

  @override
  String get errorNoActiveSession =>
      'No hay una sesión activa o correo disponible para reautenticar.';

  @override
  String get errorSendResetEmail =>
      'No se pudo enviar el correo de recuperación. Intenta nuevamente.';

  @override
  String get editProfileTitle => 'Editar Perfil';

  @override
  String get profileEmailNotice => 'El correo electrónico no es editable.';

  @override
  String get editProfileAction => 'Editar Perfil';

  @override
  String get saveChangesAction => 'Guardar Cambios';

  @override
  String get changePhotoAction => 'Cambiar Foto';

  @override
  String get uploadingPhoto => 'Subiendo imagen...';

  @override
  String get profileUpdateSuccess => 'Perfil actualizado exitosamente.';

  @override
  String get noProfileData => 'No se pudo cargar la información del perfil.';

  @override
  String get savingProfile => 'Guardando...';

  @override
  String get profileDetailsTitle => 'Información Personal';

  @override
  String get profileSectionContact => 'Contacto y Domicilio';

  @override
  String get profileSectionIdentity => 'Identificación';

  @override
  String get petsListTitle => 'Mis Mascotas';

  @override
  String get addPetAction => 'Registrar Mascota';

  @override
  String get emptyPetsMessage => 'No tienes mascotas registradas aún.';

  @override
  String get petNameLabel => 'Nombre de la mascota';

  @override
  String get petSpeciesLabel => 'Especie';

  @override
  String get petBreedLabel => 'Raza';

  @override
  String get petSexLabel => 'Sexo';

  @override
  String get petReproductiveStatusLabel => 'Estado reproductivo';

  @override
  String get petBirthDateLabel => 'Fecha de nacimiento';

  @override
  String get petAgeLabel => 'Edad aproximada';

  @override
  String get petAgeYears => 'Años';

  @override
  String get petAgeMonths => 'Meses';

  @override
  String get petAgeCalculationNotice =>
      'Puedes indicar la fecha exacta o ingresar los años y meses aproximados.';

  @override
  String get petAllergiesLabel => 'Alergias o condiciones médicas';

  @override
  String get petSexMale => 'Macho';

  @override
  String get petSexFemale => 'Hembra';

  @override
  String get petReproductiveIntact => 'Entero / Intacto';

  @override
  String get petReproductiveNeutered => 'Castrado / Esterilizado';

  @override
  String get petReproductiveUnknown => 'Desconocido';

  @override
  String get petSpeciesDog => 'Perro';

  @override
  String get petSpeciesCat => 'Gato';

  @override
  String get petSpeciesBird => 'Ave';

  @override
  String get petSpeciesOther => 'Otro';

  @override
  String get petCreateSuccess => 'Mascota registrada exitosamente.';

  @override
  String get petUpdateSuccess =>
      'Datos de la mascota actualizados exitosamente.';

  @override
  String get petDeactivateAction => 'Dar de baja';

  @override
  String get petDeactivateTitle => 'Dar de baja mascota';

  @override
  String get petDeactivateConfirm =>
      '¿Confirmas la baja definitiva de esta mascota?';

  @override
  String get petDeactivateNotice =>
      'Esta acción cancelará automáticamente cualquier cita futura programada.';

  @override
  String get petDeactivateAffectedAppointments =>
      'Citas activas que serán canceladas:';

  @override
  String get petDeactivateNoAppointments =>
      'No tiene citas pendientes ni confirmadas programadas.';

  @override
  String get petDeactivateSuccess => 'Mascota dada de baja exitosamente.';

  @override
  String get petStatusActive => 'Activa';

  @override
  String get petStatusDeactivated => 'Dada de baja';

  @override
  String get petDetailTitle => 'Ficha de la Mascota';

  @override
  String get petEditAction => 'Editar Datos';

  @override
  String get petPhotoAction => 'Cambiar Foto';

  @override
  String get savingPet => 'Guardando...';

  @override
  String get loadingPets => 'Cargando mascotas...';

  @override
  String get petLoadingPreview => 'Verificando citas programadas...';

  @override
  String get dateFormatHint => 'AAAA-MM-DD';

  @override
  String appointmentItemSummary(String service, String date) {
    return '$service - $date';
  }

  @override
  String get adminServicesTitle => 'Catálogo de Servicios';

  @override
  String get addServiceAction => 'Nuevo Servicio';

  @override
  String get editServiceAction => 'Editar Servicio';

  @override
  String get serviceNameLabel => 'Nombre del servicio';

  @override
  String get serviceDescriptionLabel => 'Descripción';

  @override
  String get serviceBasePriceLabel => 'Precio Base (USD)';

  @override
  String get serviceFinalPriceLabel => 'Precio Final con Impuestos';

  @override
  String get serviceIceLabel => 'ICE (Puntos Básicos)';

  @override
  String get serviceDurationLabel => 'Duración Estimada (minutos)';

  @override
  String get serviceIsClinicalLabel => '¿Es Servicio Clínico?';

  @override
  String get serviceIsActiveLabel => '¿Servicio Activo?';

  @override
  String get serviceActivateAction => 'Activar';

  @override
  String get serviceDeactivateAction => 'Desactivar';

  @override
  String get serviceSaveSuccess => 'Servicio guardado exitosamente.';

  @override
  String get serviceStatusActive => 'Activo';

  @override
  String get serviceStatusInactive => 'Inactivo';

  @override
  String get serviceClinicalBadge => 'Clínico';

  @override
  String get serviceGeneralBadge => 'General';

  @override
  String serviceDurationSummary(int minutes) {
    return '$minutes min';
  }

  @override
  String servicePriceSummary(String base, String finalPrice) {
    return 'Base: \$$base · Final: \$$finalPrice';
  }

  @override
  String get emptyServicesMessage =>
      'No hay servicios registrados en el catálogo.';

  @override
  String get servicesLoadErrorMessage =>
      'No se pudo cargar el catálogo de servicios.';

  @override
  String get loadingServices => 'Cargando servicios...';

  @override
  String get savingService => 'Guardando servicio...';

  @override
  String get serviceConfirmDeactivate =>
      '¿Estás seguro de desactivar este servicio del catálogo?';

  @override
  String get serviceConfirmActivate =>
      '¿Estás seguro de activar este servicio en el catálogo?';

  @override
  String get bookingTitle => 'Agendamiento de Cita';

  @override
  String get bookingStepService => '1. Servicio';

  @override
  String get bookingStepPet => '2. Mascota';

  @override
  String get bookingStepDateTime => '3. Fecha y Horario';

  @override
  String get bookingStepConfirm => '4. Confirmación';

  @override
  String get selectServiceTitle => 'Selecciona un Servicio';

  @override
  String get selectPetTitle => 'Selecciona tu Mascota';

  @override
  String get selectDateTimeTitle => 'Selecciona Fecha y Horario';

  @override
  String get confirmBookingTitle => 'Confirmar Agendamiento';

  @override
  String get clientNotesLabel =>
      'Notas o síntomas (opcional, máx. 250 caracteres)';

  @override
  String get confirmBookingAction => 'Confirmar Cita';

  @override
  String get bookingSuccessMessage => '¡Cita agendada exitosamente!';

  @override
  String get noAvailableSlotsMessage =>
      'No hay franjas horarias disponibles para la fecha seleccionada.';

  @override
  String get noOperatingDayMessage =>
      'Día no laborable según el horario de atención.';

  @override
  String get slotTakenNotice =>
      'La franja seleccionada ya no está disponible. Por favor, selecciona otra.';

  @override
  String get noActivePetsMessage =>
      'No tienes mascotas activas disponibles para agendar.';

  @override
  String get bookingPriceEstimatedNotice =>
      'El precio mostrado es informativo; el valor definitivo será registrado al confirmar la cita.';

  @override
  String bookingBasePriceSummary(String amount) {
    return 'Precio base: \$$amount';
  }

  @override
  String bookingEstimatedTaxesSummary(String amount) {
    return 'Impuestos estimados: \$$amount';
  }

  @override
  String bookingTotalEstimatedSummary(String amount) {
    return 'Total estimado a pagar: \$$amount';
  }

  @override
  String get offlineWarning =>
      'Sin conexión a internet. No se puede realizar el agendamiento.';

  @override
  String notesCharCount(int current) {
    return '$current / 250';
  }

  @override
  String get selectAction => 'Elegir';

  @override
  String get selectedBadge => 'Seleccionado';

  @override
  String get selectDateLabel => 'Seleccionar fecha';

  @override
  String get availableSlotsTitle => 'Horarios Disponibles';

  @override
  String get noSlotsAvailableNotice =>
      'No hay horarios disponibles para este día.';

  @override
  String get serviceSummaryLabel => 'Servicio';

  @override
  String get petSummaryLabel => 'Mascota';

  @override
  String get dateTimeSummaryLabel => 'Fecha y Horario';

  @override
  String get notesSummaryLabel => 'Notas';

  @override
  String get confirmBookingNotice =>
      'Al confirmar, la reserva se registrará de forma definitiva.';

  @override
  String get appointmentCodeLabel => 'Código de cita';

  @override
  String get backToHomeAction => 'Volver al Inicio';

  @override
  String get nextStepAction => 'Siguiente';

  @override
  String get previousStepAction => 'Anterior';

  @override
  String get stepServiceTitle => 'Servicio';

  @override
  String get stepPetTitle => 'Mascota';

  @override
  String get stepDateTimeTitle => 'Fecha y Hora';

  @override
  String get stepConfirmTitle => 'Confirmar';

  @override
  String get appointmentsHistoryTitle => 'Historial de Citas';

  @override
  String get upcomingAppointmentsTab => 'Próximas';

  @override
  String get pastAppointmentsTab => 'Pasadas';

  @override
  String get upcomingAppointmentsTitle => 'Citas Próximas';

  @override
  String get pastAppointmentsTitle => 'Citas Pasadas';

  @override
  String get noUpcomingAppointments => 'No tienes citas próximas programadas.';

  @override
  String get noPastAppointments => 'No tienes citas en tu historial.';

  @override
  String get noAppointmentsFound => 'No tienes citas registradas.';

  @override
  String get appointmentStatusPending => 'Pendiente';

  @override
  String get appointmentStatusConfirmed => 'Confirmada';

  @override
  String get appointmentStatusCompleted => 'Completada';

  @override
  String get appointmentStatusCancelled => 'Cancelada';

  @override
  String get appointmentDateLabel => 'Fecha';

  @override
  String get appointmentTimeLabel => 'Horario';

  @override
  String get appointmentPetLabel => 'Mascota';

  @override
  String get appointmentServiceLabel => 'Servicio';

  @override
  String get appointmentStatusLabel => 'Estado';

  @override
  String appointmentBasePrice(String amount) {
    return 'Precio base: \$$amount';
  }

  @override
  String appointmentFinalPriceWithTaxes(String amount) {
    return 'Precio final con impuestos: \$$amount';
  }

  @override
  String get cancelAppointmentAction => 'Cancelar Cita';

  @override
  String get cancelAppointmentDialogTitle => '¿Deseas cancelar esta cita?';

  @override
  String get cancelAppointmentDialogMessage =>
      'Esta acción liberará el horario reservado y cancelará la cita de forma definitiva. No podrás deshacer esta acción.';

  @override
  String get confirmCancelAction => 'Confirmar Cancelación';

  @override
  String get keepAppointmentAction => 'Mantener Cita';

  @override
  String get appointmentCancelledSuccess =>
      'La cita ha sido cancelada exitosamente.';

  @override
  String get cancellingAppointment => 'Cancelando...';

  @override
  String get loadMoreAppointmentsAction => 'Cargar más citas';

  @override
  String get catalogTitle => 'Catálogo de Productos';

  @override
  String get searchProductHint => 'Buscar producto...';

  @override
  String get categoryAll => 'Todos';

  @override
  String get categoryFood => 'Alimentos';

  @override
  String get categoryMedicine => 'Medicinas';

  @override
  String get categoryAccessories => 'Accesorios';

  @override
  String get categoryHygiene => 'Higiene';

  @override
  String get stockAvailable => 'Disponible';

  @override
  String get stockOutOfStock => 'Agotado';

  @override
  String priceBaseFormatted(String amount) {
    return 'Base: \$$amount';
  }

  @override
  String priceWithTaxesFormatted(String amount) {
    return 'Con impuestos: \$$amount';
  }

  @override
  String taxIceFormatted(String percent, String amount) {
    return 'ICE ($percent%): \$$amount';
  }

  @override
  String taxIvaFormatted(String percent, String amount) {
    return 'IVA ($percent%): \$$amount';
  }

  @override
  String get taxIceOnlyLabel => 'ICE aplicable';

  @override
  String get taxIvaOnlyLabel => 'IVA aplicable';

  @override
  String get taxBreakdownTitle => 'Desglose de Precios';

  @override
  String get productDetailTitle => 'Detalle del Producto';

  @override
  String get requestProductAction => 'Solicitar Producto';

  @override
  String get requestProductSuccess => 'Solicitud enviada exitosamente.';

  @override
  String get requestingProduct => 'Enviando solicitud...';

  @override
  String get myRequestsTitle => 'Mis Solicitudes';

  @override
  String get chatScreenTitle => 'Chat con la Veterinaria';

  @override
  String get chatPurgeAction => 'Vaciar conversación';

  @override
  String get chatPurgeTitle => 'Vaciar conversación';

  @override
  String get chatPurgeBody =>
      '¿Estás seguro de que deseas eliminar todos los mensajes? El historial desaparecerá también para el personal.';

  @override
  String get chatPurgeConfirm => 'Vaciar';

  @override
  String get chatDeleteMessageTitle => 'Eliminar mensaje';

  @override
  String get chatDeleteMessageBody =>
      '¿Deseas eliminar este mensaje? Desaparecerá de la conversación sin dejar registro sustitutorio.';

  @override
  String get chatDeleteMessageConfirm => 'Eliminar';

  @override
  String get chatDeleteOwnMessageSemantics => 'Eliminar mensaje propio';

  @override
  String get chatBlockedNotice =>
      'Un administrador ha bloqueado tu envío de mensajes en esta conversación. Puedes seguir leyendo lo que ya escribiste y lo que el personal te escriba.';

  @override
  String get chatBlockedHint => 'No puedes escribir en esta conversación';

  @override
  String get chatMessagePlaceholder => 'Escribe un mensaje...';

  @override
  String get chatEmptyConversation =>
      'No hay mensajes aún. Escribe para comunicarte con el personal.';

  @override
  String get chatAttachImageAction => 'Adjuntar imagen';

  @override
  String get chatSendMessageAction => 'Enviar mensaje';

  @override
  String get errorChatBlocked =>
      'No puedes enviar mensajes en esta conversación porque un administrador lo ha bloqueado.';

  @override
  String get errorChatMessageEmpty => 'El mensaje no puede estar vacío.';

  @override
  String get errorChatMessageTooLong =>
      'El mensaje no puede exceder los 4000 caracteres.';

  @override
  String get chatImageAttachmentLabel => 'Imagen adjunta';

  @override
  String get chatImageLoadError => 'No se pudo cargar la imagen adjunta.';

  @override
  String get chatImageOpenAction => 'Ver la imagen a tamaño completo';

  @override
  String requestClientLabel(String name) {
    return 'Cliente: $name';
  }

  @override
  String get emptyCatalogMessage => 'No se encontraron productos disponibles.';

  @override
  String get emptyRequestsMessage =>
      'No tienes solicitudes de productos registradas.';

  @override
  String get requestStatusPendingDispatch => 'Pendiente de despacho';

  @override
  String get requestStatusReadyForPickup => 'Listo para retiro';

  @override
  String get requestStatusFinalized => 'Finalizada';

  @override
  String get requestStatusCancelled => 'Cancelada';

  @override
  String get cancelRequestAction => 'Cancelar Solicitud';

  @override
  String get cancelRequestTitle => 'Cancelar Solicitud';

  @override
  String get cancelRequestConfirm =>
      '¿Confirmas la cancelación de esta solicitud de producto?';

  @override
  String get cancelRequestNotice =>
      'El producto volverá a estar disponible en el catálogo.';

  @override
  String get cancelRequestSuccess => 'Solicitud cancelada exitosamente.';

  @override
  String get cancelRequestItemsHeader => 'Productos que se cancelarán:';

  @override
  String get requestItemsHeader => 'Productos solicitados';

  @override
  String get requestTotalLabel => 'Total de la solicitud';

  @override
  String get cancellingRequest => 'Cancelando...';

  @override
  String get tabCatalog => 'Catálogo';

  @override
  String get tabMyRequests => 'Mis Solicitudes';

  @override
  String get viewDetailsAction => 'Ver Detalle';

  @override
  String get productCategoryLabel => 'Categoría';

  @override
  String get productDescriptionLabel => 'Descripción';

  @override
  String quantityLabel(int quantity) {
    return 'Cantidad: $quantity';
  }

  @override
  String get paymentSummaryTitle => 'Resumen a Pagar';

  @override
  String get paymentSummaryNotice =>
      'Los descuentos y recargos finales se aplican y reflejan en la proforma emitida por el establecimiento.';

  @override
  String get paymentSummaryEmpty =>
      'No tienes citas completadas ni solicitudes pendientes de facturación.';

  @override
  String paymentSummarySubtotal(String amount) {
    return 'Subtotal: \$$amount';
  }

  @override
  String paymentSummaryTotalIce(String amount) {
    return 'Total ICE: \$$amount';
  }

  @override
  String paymentSummaryTotalIva(String percent, String amount) {
    return 'Total IVA ($percent%): \$$amount';
  }

  @override
  String paymentSummaryEstimatedTotal(String amount) {
    return 'Total Estimado: \$$amount';
  }

  @override
  String get paymentSummaryOpenAction => 'Resumen a pagar';

  @override
  String paymentSummaryIvaRateLabel(String rate) {
    return 'IVA ($rate%):';
  }

  @override
  String get paymentSummaryEstimatedTotalLabel => 'Total estimado';

  @override
  String get cartTitle => 'Mi Carrito';

  @override
  String get cartEmptyMessage =>
      'No tienes solicitudes activas ni citas pendientes de pago.';

  @override
  String get cartNoticeAdjustments =>
      'Los descuentos y recargos finales se aplican y reflejan en la proforma emitida por el establecimiento.';

  @override
  String get cartPayableTodayLabel => 'A pagar hoy';

  @override
  String cartPayableToday(String amount) {
    return 'A pagar hoy: \$$amount';
  }

  @override
  String get cartAccumulatedTotalLabel => 'Total acumulado';

  @override
  String cartAccumulatedTotal(String amount) {
    return 'Total acumulado: \$$amount';
  }

  @override
  String get cartProductsSection => 'Productos Solicitados';

  @override
  String get cartAppointmentsSection => 'Citas Agendadas';

  @override
  String cartRequestGroupHeader(String id) {
    return 'Solicitud #$id';
  }

  @override
  String cartQuantity(int quantity) {
    return 'Cantidad: $quantity';
  }

  @override
  String cartUnitPrice(String amount) {
    return 'Precio unitario: \$$amount';
  }

  @override
  String cartPriceWithTaxes(String amount) {
    return 'Precio con impuestos: \$$amount';
  }

  @override
  String cartSubtotal(String amount) {
    return 'Subtotal: \$$amount';
  }

  @override
  String cartAppointmentDateTime(String date, String slot) {
    return 'Fecha: $date - Horario: $slot';
  }

  @override
  String cartAppointmentPet(String pet) {
    return 'Mascota: $pet';
  }

  @override
  String cartAppointmentService(String service) {
    return 'Servicio: $service';
  }

  @override
  String cartAppointmentPrice(String amount) {
    return 'Precio con impuestos: \$$amount';
  }

  @override
  String get navCart => 'Carrito';

  @override
  String get myProformasTitle => 'Mis Proformas';

  @override
  String get emptyProformasMessage => 'No tienes proformas emitidas aún.';

  @override
  String proformaNumberLabel(String number) {
    return 'Proforma: $number';
  }

  @override
  String get proformaDateLabel => 'Fecha de emisión';

  @override
  String get proformaStatusDelivered => 'Entregada';

  @override
  String get proformaStatusFinalized => 'Finalizada';

  @override
  String get proformaStatusVoided => 'Anulada';

  @override
  String get proformaStatusDraft => 'Borrador';

  @override
  String proformaVoidReasonLabel(String reason) {
    return 'Motivo de anulación: $reason';
  }

  @override
  String get downloadPdfAction => 'Descargar PDF';

  @override
  String get downloadingPdf => 'Descargando PDF...';

  @override
  String get pdfDownloadSuccess => 'PDF descargado correctamente.';

  @override
  String get pdfDownloadError => 'Error al descargar el archivo PDF.';

  @override
  String get tabPaymentSummary => 'Resumen a Pagar';

  @override
  String get tabMyProformas => 'Mis Proformas';

  @override
  String get proformaDetailTitle => 'Detalle de Proforma';

  @override
  String proformaDetailWithId(String id) {
    return 'Detalle de Proforma: $id';
  }

  @override
  String get proformaItemsTitle => 'Conceptos Facturados';

  @override
  String get proformaAdjustmentsTitle => 'Descuentos y Recargos';

  @override
  String get proformaAdjustmentDiscount => 'Descuento';

  @override
  String get proformaAdjustmentSurcharge => 'Recargo';

  @override
  String moneyAmount(String amount) {
    return '\$$amount';
  }

  @override
  String moneyAmountNegative(String amount) {
    return '-\$$amount';
  }

  @override
  String moneyAmountPositive(String amount) {
    return '+\$$amount';
  }

  @override
  String get proformaSubtotalLabel => 'Subtotal';

  @override
  String get proformaDiscountLabel => 'Descuentos';

  @override
  String get proformaSurchargeLabel => 'Recargos';

  @override
  String get proformaTaxableBaseLabel => 'Base Imponible';

  @override
  String get proformaIceLabel => 'ICE';

  @override
  String get proformaIvaLabel => 'IVA';

  @override
  String get proformaTotalLabel => 'Total';

  @override
  String get accountDeactivationTitle => 'Desactivación de Cuenta';

  @override
  String get accountDeactivationSubtitle =>
      'Solicitud de baja voluntaria de cuenta';

  @override
  String get accountDeactivationNotice =>
      'Antes de continuar, revisa los conceptos que serán cancelados y los que se conservarán en el histórico de la veterinaria.';

  @override
  String get deactivationGroupToCancelTitle => 'Conceptos a Cancelar';

  @override
  String get deactivationGroupToCancelNotice =>
      'Las siguientes citas activas y solicitudes no facturadas serán canceladas de forma definitiva. Estos conceptos no se restaurarán si la cuenta se reactiva en el futuro.';

  @override
  String get deactivationGroupToCancelEmpty =>
      'No tienes citas ni solicitudes activas por cancelar.';

  @override
  String get deactivationGroupToRetainTitle => 'Registros a Conservar';

  @override
  String get deactivationGroupToRetainNotice =>
      'Las siguientes citas completadas y solicitudes facturadas permanecerán archivadas por motivos fiscales y contables.';

  @override
  String get deactivationGroupToRetainEmpty =>
      'No tienes registros históricos facturados.';

  @override
  String get deactivationReasonCompleted => 'Cita completada';

  @override
  String get deactivationReasonBilled => 'Facturado en proforma';

  @override
  String get deactivationUnknownProduct => 'Producto no especificado';

  @override
  String get deactivationPasswordPrompt =>
      'Por motivos de seguridad, ingresa tu contraseña actual para confirmar la baja:';

  @override
  String get confirmDeactivationAction => 'Confirmar Desactivación de Cuenta';

  @override
  String get deactivatingAccount => 'Procesando baja de cuenta...';

  @override
  String get accountDeactivatedSuccess =>
      'Tu cuenta ha sido desactivada exitosamente.';

  @override
  String get adminProductsTitle => 'Gestión de Productos';

  @override
  String get addProductAction => 'Nuevo Producto';

  @override
  String get editProductAction => 'Editar Producto';

  @override
  String get productNameLabel => 'Nombre del producto';

  @override
  String get productCategoryPrompt => 'Selecciona una categoría';

  @override
  String get productInitialStockLabel => 'Stock inicial';

  @override
  String get lowStockAlert => 'Stock Bajo';

  @override
  String get adjustStockAction => 'Ajustar Stock';

  @override
  String get inventoryAdjustmentTitle => 'Ajuste de Inventario';

  @override
  String get currentStockLabel => 'Stock actual';

  @override
  String get stockDeltaLabel => 'Ajuste de unidades (positivo o negativo)';

  @override
  String get stockDeltaHelp =>
      'Ingresa un número entero positivo para añadir existencias o negativo para restar.';

  @override
  String resultingStockLabel(int stock) {
    return 'Stock resultante: $stock';
  }

  @override
  String get stockAdjustSuccess => 'Inventario actualizado exitosamente.';

  @override
  String get adjustingStock => 'Ajustando...';

  @override
  String get adminRequestsTitle => 'Cola de Despacho de Solicitudes';

  @override
  String adminRequestLine(String product, int quantity) {
    return '$product × $quantity';
  }

  @override
  String adminRequestDate(String date) {
    return 'Solicitada el $date';
  }

  @override
  String adminRequestTotalBeforeTaxes(String amount) {
    return 'Total de la solicitud, antes de impuestos: \$$amount';
  }

  @override
  String get adminRequestDetailTitle => 'Detalle de la solicitud';

  @override
  String adminRequestDetailLine(
    int quantity,
    String unitPrice,
    String subtotal,
  ) {
    return 'Cantidad: $quantity · Precio acordado: \$$unitPrice · Subtotal: \$$subtotal';
  }

  @override
  String get adminRequestTaxNote =>
      'Los impuestos se calculan en la proforma, con los porcentajes congelados de cada línea.';

  @override
  String get filterAll => 'Todos los estados';

  @override
  String get advanceToReadyAction => 'Marcar Listo para Retiro';

  @override
  String get advancingRequest => 'Actualizando estado...';

  @override
  String get requestAdvancedSuccess =>
      'Solicitud actualizada a lista para retiro.';

  @override
  String get adminProformasTitle => 'Gestión de Proformas';

  @override
  String get proformaNewAction => 'Nueva Proforma';

  @override
  String get proformaSelectClientTitle => 'Selecciona un cliente';

  @override
  String get proformaPendingConceptsTitle => 'Conceptos pendientes';

  @override
  String proformaPendingConceptsSubtitle(String name) {
    return 'Citas completadas y solicitudes listas para retirar de $name';
  }

  @override
  String get proformaNoPendingConcepts =>
      'Este cliente no tiene conceptos pendientes de facturar.';

  @override
  String get proformaConceptAppointment => 'Cita';

  @override
  String get proformaConceptProduct => 'Producto';

  @override
  String get proformaSelectedTotalLabel => 'Total seleccionado';

  @override
  String proformaCreateWithSelection(int count) {
    return 'Crear proforma con $count concepto(s)';
  }

  @override
  String proformaAddSelectionAction(int count) {
    return 'Añadir $count concepto(s) al borrador';
  }

  @override
  String get proformaAddConceptsAction => 'Añadir conceptos';

  @override
  String get newProformaAction => 'Nueva Proforma';

  @override
  String get composeProformaTitle => 'Composición de Proforma';

  @override
  String get selectClientPrompt => 'Selecciona un cliente';

  @override
  String get clientDebtSummaryTitle => 'Deuda Pendiente del Cliente';

  @override
  String get addSelectedItemsAction => 'Agregar al Borrador';

  @override
  String get setAdjustmentsAction => 'Configurar Descuentos / Recargos';

  @override
  String get adjustmentConceptLabel => 'Concepto del ajuste';

  @override
  String get adjustmentTypeLabel => 'Tipo de ajuste';

  @override
  String get adjustmentPercentLabel => 'Porcentaje (%)';

  @override
  String get adjustmentAmountLabel => 'Monto fijo (USD)';

  @override
  String get deliverProformaAction => 'Emitir y Entregar';

  @override
  String get deliveringProforma => 'Generando entrega y PDF...';

  @override
  String get proformaDeliveredSuccess => 'Proforma entregada exitosamente.';

  @override
  String get finalizeProformaAction => 'Finalizar Proforma';

  @override
  String get finalizingProforma => 'Finalizando...';

  @override
  String get proformaFinalizedSuccess => 'Proforma finalizada exitosamente.';

  @override
  String get voidProformaAction => 'Anular Proforma';

  @override
  String get voidProformaDialogTitle => 'Anulación de Proforma';

  @override
  String get voidReasonPrompt =>
      'Ingresa el motivo obligatorio de anulación (máximo 300 caracteres):';

  @override
  String get voidReasonLabel => 'Motivo de anulación';

  @override
  String get voidingProforma => 'Anulando...';

  @override
  String get proformaVoidedSuccess => 'Proforma anulada exitosamente.';

  @override
  String get adminBillingParametersTitle => 'Parámetros de Facturación';

  @override
  String get businessNameLabel => 'Razón Social';

  @override
  String get taxIdLabel => 'RUC / Identificación Fiscal';

  @override
  String get proformaSeriesLabel => 'Serie de Proforma';

  @override
  String get ivaBpLabel => 'Porcentaje de IVA (Puntos Básicos)';

  @override
  String ivaBpHelper(String percent) {
    return '$percent % — 1500 puntos básicos equivalen al 15 %';
  }

  @override
  String get iceIncludedInIvaBaseLabel =>
      'Incluir ICE en la base imponible del IVA';

  @override
  String get ivaNoticeFutureOnly =>
      'Los cambios en el porcentaje de IVA se aplicarán exclusivamente a las futuras proformas emitidas.';

  @override
  String get saveBillingParamsSuccess =>
      'Parámetros de facturación guardados exitosamente.';

  @override
  String get productBasePriceLabel => 'Precio Base (USD)';

  @override
  String get productIceBpLabel => 'ICE (Puntos Básicos)';

  @override
  String get productStockLockedNotice =>
      'El stock solo puede definirse al crear el producto. Para modificar existencias utilice Ajuste de Inventario.';

  @override
  String get proformaEmptyError =>
      'No se puede entregar una proforma sin ítems.';

  @override
  String get deliveryInProgressError =>
      'La proforma ya está en proceso de entrega.';

  @override
  String get tooManyItemsError =>
      'La proforma excede el límite máximo de ítems permitidos.';

  @override
  String get voidReasonMinLengthError =>
      'El motivo de anulación debe tener al menos 5 caracteres.';

  @override
  String get voidReasonMaxLengthError =>
      'El motivo no puede exceder los 300 caracteres.';

  @override
  String get adminInventoryTitle => 'Control de Inventario';

  @override
  String get stockAdjustmentReasonPrompt => 'Motivo del ajuste (obligatorio)';

  @override
  String get productToggleActiveSuccess => 'Estado del producto actualizado.';

  @override
  String get noProductsFoundAdmin =>
      'No se encontraron productos en el catálogo.';

  @override
  String get noRequestsFoundAdmin =>
      'No hay solicitudes de productos en esta cola.';

  @override
  String get noProformasFoundAdmin => 'No hay proformas registradas.';

  @override
  String get navAdminProducts => 'Productos';

  @override
  String get navAdminInventory => 'Inventario';

  @override
  String get navAdminRequests => 'Solicitudes';

  @override
  String get navAdminProformas => 'Proformas';

  @override
  String get createProformaDraftAction => 'Nuevo Borrador';

  @override
  String get saveAction => 'Guardar';

  @override
  String get savingAction => 'Guardando...';

  @override
  String get searchPlaceholder => 'Buscar...';

  @override
  String get productSavedSuccess => 'Producto guardado exitosamente.';

  @override
  String get productActiveStatusLabel => 'Producto Activo';

  @override
  String get adminGovernanceUnderConstruction =>
      'Módulo en construcción. La gestión de gobierno y cuentas estará disponible próximamente.';

  @override
  String get adminClientsManagementTitle => 'Gestión de Clientes';

  @override
  String get adminClientsActiveTab => 'Clientes Activos';

  @override
  String get adminClientsDeactivatedTab => 'Cuentas Desactivadas';

  @override
  String get adminClientsSearchLabel => 'Buscar por nombre o cédula';

  @override
  String get adminClientsSearchHint => 'Escribe el nombre del cliente...';

  @override
  String get adminClientsEmptyActive =>
      'No se encontraron clientes registrados.';

  @override
  String get adminClientsEmptyDeactivated =>
      'No hay cuentas desactivadas actualmente.';

  @override
  String get adminClientsStatusDeactivated => 'Estado: DESACTIVADA';

  @override
  String get adminClientsReactivateTitle => 'Reactivar Cuenta';

  @override
  String adminClientsReactivateContent(String fullName) {
    return '¿Deseas reactivar la cuenta de $fullName?';
  }

  @override
  String get adminClientsReactivateConfirm => 'Reactivar';

  @override
  String get adminClientsTooltipView => 'Ver Ficha';

  @override
  String get adminClientsSemanticsView => 'Ver ficha de cliente';

  @override
  String get adminClientsSemanticsReactivate => 'Reactivar cuenta de usuario';

  @override
  String adminClientDetailTitle(String fullName) {
    return 'Ficha de Cliente: $fullName';
  }

  @override
  String get adminClientIdentityTitle => 'Datos de Identidad (Sólo Lectura)';

  @override
  String get adminClientFieldFullName => 'Nombre Completo';

  @override
  String get adminClientFieldDocument => 'Documento de Identidad';

  @override
  String get adminClientFieldEmail => 'Correo Electrónico';

  @override
  String get adminClientFieldPhone => 'Teléfono de Contacto';

  @override
  String get adminClientFieldAddress => 'Dirección Domiciliaria';

  @override
  String get adminClientFieldRole => 'Rol en el Sistema';

  @override
  String get adminClientAddressNotRegistered => 'No registrada';

  @override
  String adminClientPetsRegisteredTitle(int count) {
    return 'Mascotas Registradas ($count)';
  }

  @override
  String get adminClientNoPets => 'El cliente no tiene mascotas registradas.';

  @override
  String get adminClientTooltipBack => 'Volver al listado';

  @override
  String get adminClientSemanticsBack => 'Volver al listado de clientes';

  @override
  String adminPetCorrectionTitle(String name) {
    return 'Corregir Ficha de $name';
  }

  @override
  String get adminPetCorrectionNote =>
      'Nota: El personal sólo está autorizado a rectificar el sexo y estado reproductivo de la mascota.';

  @override
  String get adminPetCorrectionSexLabel => 'Sexo';

  @override
  String get adminPetCorrectionReproductiveLabel => 'Estado Reproductivo';

  @override
  String get adminPetCorrectionSexMale => 'Macho (MALE)';

  @override
  String get adminPetCorrectionSexFemale => 'Hembra (FEMALE)';

  @override
  String get adminPetCorrectionReproductiveIntact => 'Fértil / Entero (INTACT)';

  @override
  String get adminPetCorrectionReproductiveNeutered =>
      'Esterilizado / Castrado (NEUTERED)';

  @override
  String get adminPetCorrectionReproductiveUnknown => 'Desconocido (UNKNOWN)';

  @override
  String get adminPetCorrectionSave => 'Guardar Corrección';

  @override
  String get adminPetCorrectionAction => 'Corregir';

  @override
  String get adminPetCorrectionTooltip => 'Corregir Sexo/Estado';

  @override
  String get adminPetCorrectionSemantics =>
      'Corregir sexo y estado reproductivo de la mascota';

  @override
  String adminPetSpeciesLabel(String species, String breed) {
    return 'Especie: $species | Raza: $breed';
  }

  @override
  String adminPetSexReproductiveLabel(String sex, String reproductiveStatus) {
    return 'Sexo: $sex | Reproductivo: $reproductiveStatus';
  }

  @override
  String get adminPetBreedNotSpecified => 'No especificada';

  @override
  String get adminBlockAvailabilityTitle => 'Bloquear Disponibilidad';

  @override
  String get adminBlockAction => 'Bloquear';

  @override
  String get adminRescheduleAppointmentTitle => 'Reagendar Cita';

  @override
  String get adminRescheduleAction => 'Reagendar';

  @override
  String get adminAgendaTitle => 'Agenda Administrativa';

  @override
  String get adminStatusFilterLabel => 'Estado';

  @override
  String get adminConfirmAction => 'Confirmar';

  @override
  String get adminCompleteAction => 'Completar';

  @override
  String get adminViewModeWeek => 'Semanal';

  @override
  String get adminViewModeMonth => 'Mensual';

  @override
  String get adminStatusFilterAll => 'Todos los estados';

  @override
  String get adminStatusFilterPending => 'Pendientes';

  @override
  String get adminStatusFilterConfirmed => 'Confirmadas';

  @override
  String get adminStatusFilterCompleted => 'Completadas';

  @override
  String get adminStatusFilterCancelled => 'Canceladas';

  @override
  String get clinicalEntryAnnulmentTitle => 'Anulación de Entrada Clínica';

  @override
  String get clinicalEntryAnnulAction => 'Anular Registro';

  @override
  String get clinicalViewVersionsAction => 'Ver Versiones';

  @override
  String get clinicalCorrectAction => 'Corregir';

  @override
  String get clinicalConsultationAnnulmentTitle =>
      'Anulación de Registro Clínico';

  @override
  String get clinicalConfirmAnnulmentAction => 'Confirmar Anulación';

  @override
  String get clinicalPrescribeTreatmentTitle => 'Prescribir Tratamiento';

  @override
  String get clinicalAddPrescriptionLineAction => 'Añadir Línea';

  @override
  String get clinicalPrescribeMedicationAction => 'Prescribir Medicamento';

  @override
  String get clinicalUploadAttachmentAction => 'Subir Archivo Adjunto';

  @override
  String get clinicalUpdatePetPhotoAction => 'Actualizar Foto Mascota';

  @override
  String get agendaBlockDateLabel => 'Fecha (YYYY-MM-DD)';

  @override
  String get agendaBlockDateHint => '2026-09-02';

  @override
  String get agendaBlockSlotLabel => 'Franja horaria (opcional, ej. 09:00)';

  @override
  String get agendaBlockSlotHint =>
      'Dejar en blanco para bloquear día completo';

  @override
  String get agendaBlockReasonLabel => 'Motivo del bloqueo';

  @override
  String get agendaBlockReasonHint =>
      'Mantenimiento, feriado o ausencia médica';

  @override
  String get agendaRescheduleDateLabel => 'Nueva Fecha (YYYY-MM-DD)';

  @override
  String get agendaRescheduleSlotLabel => 'Nueva Franja (HH:mm)';

  @override
  String get agendaCancelAppointmentTooltip => 'Cancelar Cita';

  @override
  String get agendaCancelConflictSemantic => 'Cancelar cita en conflicto';

  @override
  String get agendaRescheduleAppointmentTooltip => 'Reagendar Cita';

  @override
  String get agendaRescheduleConflictSemantic => 'Reagendar cita en conflicto';

  @override
  String get agendaPreviousDayTooltip => 'Día anterior';

  @override
  String get agendaPreviousDaySemantic => 'Día anterior';

  @override
  String get agendaNextDayTooltip => 'Día siguiente';

  @override
  String get agendaNextDaySemantic => 'Día siguiente';

  @override
  String get clinicalAnnulReasonLabel => 'Motivo obligatorio de anulación *';

  @override
  String get clinicalMedicationLabel => 'Medicamento *';

  @override
  String get clinicalDoseLabel => 'Dosis * (ej: 10 mg/kg)';

  @override
  String get clinicalRouteLabel => 'Vía de administración *';

  @override
  String get clinicalDurationLabel => 'Duración * (ej: 7 días)';

  @override
  String get clinicalModalityLabel => 'Modalidad *';

  @override
  String get clinicalAnnulRecordTooltip => 'Anular registro clínico';

  @override
  String get clinicalAnnulRecordSemantic => 'Anular registro clínico';

  @override
  String get clinicalDeferTooltip => 'Aplazar o cerrar el registro';

  @override
  String get clinicalDeferSemantic => 'Aplazar formulario';

  @override
  String get clinicalDeferAction => 'Aplazar';

  @override
  String get clinicalReasonLabel => 'Motivo de consulta *';

  @override
  String get clinicalCurrentIllnessLabel => 'Enfermedad actual (opcional)';

  @override
  String get clinicalBackgroundLabel => 'Antecedentes médicos (opcional)';

  @override
  String get clinicalDiagnosisLabel => 'Diagnóstico';

  @override
  String get clinicalDiagnosisTypeLabel => 'Tipo de Diagnóstico';

  @override
  String get clinicalDiagnosisPresumptive => 'Presuntivo';

  @override
  String get clinicalDiagnosisDefinitive => 'Definitivo';

  @override
  String get clinicalOwnerInstructionsLabel =>
      'Indicaciones para el propietario (opcional)';

  @override
  String get clinicalTemperatureLabel => 'T° (°C)';

  @override
  String get clinicalTemperatureHint => 'ej: 38.5';

  @override
  String get clinicalHeartRateLabel => 'FC (lpm)';

  @override
  String get clinicalHeartRateHint => '10..400';

  @override
  String get clinicalRespRateLabel => 'FR (rpm)';

  @override
  String get clinicalRespRateHint => '5..200';

  @override
  String get clinicalWeightLabel => 'Peso (kg)';

  @override
  String get clinicalWeightHint => 'ej: 12.5';

  @override
  String get clinicalBodyConditionLabel => 'CC (1 a 9)';

  @override
  String get clinicalSystemNotExamined => 'No examinado';

  @override
  String get clinicalSystemNormal => 'Normal';

  @override
  String get clinicalSystemAbnormal => 'Alterado';

  @override
  String get clinicalNoPreviousVersions =>
      'No existen versiones anteriores registradas.';

  @override
  String get clinicalAnnulReasonHistoryLabel =>
      'Motivo obligatorio de anulación *';

  @override
  String get clinicalNoRecords =>
      'La mascota no tiene registros clínicos registrados.';

  @override
  String get dashboardShortcutsTooltip => 'Ver atajos de teclado (?)';

  @override
  String get dashboardShortcutsSemantic => 'Ver atajos de teclado';

  @override
  String get dashboardRefreshTooltip => 'Actualizar métricas';

  @override
  String get dashboardRefreshSemantic => 'Actualizar métricas';

  @override
  String clinicalFindingsLabel(String system) {
    return 'Hallazgos descriptivos obligatorios para $system *';
  }

  @override
  String clinicalVersionEntry(String number, String date) {
    return 'Versión $number - $date';
  }

  @override
  String clinicalHistoryTitle(String pet) {
    return 'Historial Clínico: $pet';
  }

  @override
  String clinicalHistoryLoadError(String error) {
    return 'Error al cargar historial: $error';
  }

  @override
  String clinicalDiagnosisSummary(String diagnosis) {
    return 'Diagnóstico: $diagnosis';
  }

  @override
  String dashboardMetricDetailTooltip(String metric) {
    return 'Ver detalle de $metric';
  }

  @override
  String get clinicalFindingsHelper =>
      'Requerido al marcar el sistema como alterado.';

  @override
  String get clinicalReasonHelper => 'Obligatorio. Máximo 500 caracteres.';

  @override
  String clinicalPrescriptionLine(String medication, String dose) {
    return '$medication ($dose)';
  }

  @override
  String clinicalAttachmentLine(String path, String bytes) {
    return '$path ($bytes B)';
  }

  @override
  String clinicalVersionBadge(String number) {
    return 'v$number';
  }

  @override
  String dashboardMetricSemantic(String metric, String value) {
    return '$metric: $value';
  }

  @override
  String get navAdminDashboard => 'Panel';

  @override
  String get navAdminClients => 'Clientes';

  @override
  String get navAdminServices => 'Servicios';

  @override
  String get navAdminClinical => 'Clínica';

  @override
  String get govTitle => 'Gobierno y Cuentas';

  @override
  String get govTabAccounts => 'Cuentas de Usuario';

  @override
  String get govTabOperatingParameters => 'Configuración Operativa';

  @override
  String get govTabAuditLog => 'Registro de Auditoría';

  @override
  String get govSearchPlaceholder => 'Buscar por nombre, correo o cédula...';

  @override
  String get govCreateAccountButton => 'Crear Cuenta';

  @override
  String get govRoleFilterAll => 'Todos los roles';

  @override
  String get govRoleSuperAdmin => 'Super Usuario';

  @override
  String get govRoleAdmin => 'Administrador';

  @override
  String get govRoleClient => 'Cliente';

  @override
  String get govStatusActive => 'Activo';

  @override
  String get govStatusDeactivated => 'Desactivado';

  @override
  String get govStatusDeleted => 'Eliminado';

  @override
  String get govColumnName => 'Nombre';

  @override
  String get govColumnEmail => 'Correo';

  @override
  String get govColumnRole => 'Rol';

  @override
  String get govColumnStatus => 'Estado';

  @override
  String get govColumnActions => 'Acciones';

  @override
  String get govSuperAdminImmutableBadge => 'Inmutable';

  @override
  String get govActionEditIdentity => 'Editar Identidad';

  @override
  String get govActionResetPassword => 'Restablecer Contraseña';

  @override
  String get govActionDeactivate => 'Desactivar Cuenta';

  @override
  String get govActionReactivate => 'Reactivar Cuenta';

  @override
  String get govActionDeleteStaff => 'Eliminar Personal';

  @override
  String get govNoAccountsFound => 'No se encontraron cuentas de usuario.';

  @override
  String get govCreateAccountDialogTitle => 'Crear Nueva Cuenta';

  @override
  String get govFieldEmail => 'Correo Electrónico';

  @override
  String get govFieldFullName => 'Nombre Completo';

  @override
  String get govFieldRole => 'Rol de la Cuenta';

  @override
  String get govFieldPhone => 'Teléfono (+593...)';

  @override
  String get govFieldDocumentType => 'Tipo de Documento';

  @override
  String get govFieldDocumentNumber => 'Número de Documento';

  @override
  String get govFieldAddress => 'Dirección';

  @override
  String get govButtonCancel => 'Cancelar';

  @override
  String get govButtonCreate => 'Crear y Generar Enlace';

  @override
  String get govValidationRequired => 'Este campo es obligatorio';

  @override
  String get govValidationInvalidEmail => 'Correo electrónico no válido';

  @override
  String get govValidationInvalidPhone =>
      'Teléfono no válido (+593 seguido de 9 dígitos)';

  @override
  String get govEditIdentityDialogTitle => 'Editar Identidad de Cuenta';

  @override
  String get govEmailReadOnlyNotice =>
      'El correo electrónico es de sólo lectura y no puede modificarse.';

  @override
  String get govButtonSave => 'Guardar Cambios';

  @override
  String get govLinkDialogTitleCreated => 'Cuenta Aprovisionada con Éxito';

  @override
  String get govLinkDialogTitleReset => 'Enlace de Restablecimiento Generado';

  @override
  String get govLinkDialogNotice =>
      'Entregue el siguiente enlace al usuario de forma presencial o por canal seguro. El sistema NO despacha correos automáticos:';

  @override
  String get govButtonCopyLink => 'Copiar Enlace';

  @override
  String get govLinkCopiedSnackbar => 'Enlace copiado al portapapeles.';

  @override
  String get govButtonClose => 'Cerrar';

  @override
  String get govConfirmDeactivateTitle => 'Confirmar Desactivación';

  @override
  String govConfirmDeactivateMessage(String name) {
    return '¿Está seguro de que desea desactivar la cuenta de $name? Se revocarán sus sesiones y se cancelarán citas activas.';
  }

  @override
  String get govButtonConfirmDeactivate => 'Desactivar';

  @override
  String get govConfirmReactivateTitle => 'Confirmar Reactivación';

  @override
  String govConfirmReactivateMessage(String name) {
    return '¿Está seguro de que desea reactivar la cuenta de $name? Volverá a tener acceso al sistema.';
  }

  @override
  String get govButtonConfirmReactivate => 'Reactivar';

  @override
  String get govConfirmDeleteStaffTitle => 'Confirmar Baja Lógica de Personal';

  @override
  String govConfirmDeleteStaffMessage(String name) {
    return '¿Está seguro de dar de baja lógica a $name? Su cuenta quedará deshabilitada pero su historial clínico y contable se preservará íntegro.';
  }

  @override
  String get govButtonConfirmDelete => 'Eliminar Personal';

  @override
  String get govOperatingParamsTitle => 'Parámetros Operativos del Negocio';

  @override
  String get govOperatingParamsDescription =>
      'Configuración general de horarios, turnos y umbrales de inventario. La zona horaria institucional es inmutable (America/Guayaquil).';

  @override
  String get govFieldOpeningTime => 'Hora de Apertura (HH:mm)';

  @override
  String get govFieldClosingTime => 'Hora de Cierre (HH:mm)';

  @override
  String get govFieldSlotDuration => 'Duración de Turno (minutos)';

  @override
  String get govFieldWorkingDays => 'Días Laborables';

  @override
  String get govFieldLowStockThreshold => 'Umbral de Stock Bajo';

  @override
  String get govDayMonday => 'Lunes';

  @override
  String get govDayTuesday => 'Martes';

  @override
  String get govDayWednesday => 'Miércoles';

  @override
  String get govDayThursday => 'Jueves';

  @override
  String get govDayFriday => 'Viernes';

  @override
  String get govDaySaturday => 'Sábado';

  @override
  String get govDaySunday => 'Domingo';

  @override
  String get govButtonSaveParams => 'Guardar Parámetros';

  @override
  String get govParamsSavedSuccess =>
      'Parámetros operativos actualizados correctamente.';

  @override
  String get govInvalidTimeOrder =>
      'La hora de apertura debe ser anterior a la de cierre.';

  @override
  String get govAuditLogTitle => 'Registro de Auditoría';

  @override
  String get govAuditLogEmpty => 'No hay registros de auditoría disponibles.';

  @override
  String get govAuditColumnDate => 'Fecha y Hora';

  @override
  String get govAuditColumnActor => 'Actor';

  @override
  String get govAuditColumnAction => 'Acción';

  @override
  String get govAuditColumnTarget => 'Objetivo';

  @override
  String get govAuditColumnMetadata => 'Metadatos';

  @override
  String get govButtonRefresh => 'Actualizar';

  @override
  String get govAuditFilterAction => 'Filtrar por acción';

  @override
  String get govAuditAllActions => 'Todas las acciones';

  @override
  String get adminNavClients => 'Clientes';

  @override
  String get adminNavClinical => 'Registro Clínico';

  @override
  String get adminNavChat => 'Bandeja de Mensajería';

  @override
  String get catalogSelectionTitle => 'Productos seleccionados';

  @override
  String get catalogClearSelection => 'Limpiar selección';

  @override
  String catalogSubmitRequestWithCount(int count) {
    return 'Solicitar $count producto(s)';
  }

  @override
  String get catalogAddToSelection => 'Agregar a la solicitud';

  @override
  String get catalogRemoveFromSelection => 'Eliminar de la selección';

  @override
  String get catalogRequestSuccess => 'Solicitud enviada exitosamente';

  @override
  String get catalogSelectionEmpty => 'No has seleccionado ningún producto';

  @override
  String catalogSelectionLinePrices(String unit, String total) {
    return 'Unitario: \$$unit · Total: \$$total';
  }

  @override
  String catalogInSelectionBadge(int quantity) {
    return 'En la solicitud: $quantity';
  }

  @override
  String catalogSelectionSummary(int units, int lines) {
    String _temp0 = intl.Intl.pluralLogic(
      units,
      locale: localeName,
      other: '$units unidades',
      one: '1 unidad',
    );
    String _temp1 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: '$lines productos',
      one: '1 producto',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String productDetailTotal(String amount) {
    return 'Total: \$$amount';
  }

  @override
  String get cartOpenAction => 'Mi carrito';

  @override
  String cartBreakdownSubtotal(String amount) {
    return 'Subtotal: \$$amount';
  }

  @override
  String cartBreakdownIce(String amount) {
    return 'ICE: \$$amount';
  }

  @override
  String cartBreakdownIva(String amount) {
    return 'IVA: \$$amount';
  }

  @override
  String get productQuantityLabel => 'Cantidad';

  @override
  String get catalogClearSearch => 'Borrar la búsqueda';

  @override
  String get catalogDecreaseQuantity => 'Quitar una unidad';

  @override
  String get catalogIncreaseQuantity => 'Añadir una unidad';

  @override
  String get routeNotFoundTitle => 'Esta página no existe';

  @override
  String get routeNotFoundMessage =>
      'La dirección que abriste no corresponde a ninguna pantalla. Puede que el enlace venga de una versión anterior.';

  @override
  String get routeNotFoundAction => 'Volver al inicio';

  @override
  String get adminPetClinicalRecordAction => 'Registro clínico';

  @override
  String adminPetClinicalRecordSemantics(String petName) {
    return 'Abrir el registro clínico de $petName';
  }

  @override
  String get clinicalAnnulmentWarning =>
      'La anulación es inmutable. El registro quedará marcado como ANNULLED y no se podrá volver a editar.';

  @override
  String get clinicalCorrectConsultationTitle => 'Corregir Consulta Clínica';

  @override
  String get clinicalSectionReasonTitle => '2. Motivo y Anamnesis';

  @override
  String get clinicalSectionVitalsTitle => '3. Signos Vitales';

  @override
  String get clinicalSectionExamTitle =>
      '4. Examen Físico por Sistemas (10 Sistemas)';

  @override
  String get clinicalSectionExamHelp =>
      'Todos los sistemas inician por omisión en \"NOT_EXAMINED\". Si marca \"ABNORMAL\", es obligatorio ingresar el hallazgo descriptivo.';

  @override
  String get clinicalSectionPlanTitle => '5. Diagnóstico y Tratamiento';

  @override
  String get clinicalTreatmentLinesLabel => 'Líneas de Tratamiento:';

  @override
  String get clinicalNoPrescriptions =>
      'No se han prescrito medicamentos para esta consulta.';

  @override
  String get clinicalNotEditableNotice =>
      'Este registro clínico no puede ser editado porque está anulado o usted no es el autor original ni Super Usuario.';

  @override
  String get clinicalSaveCorrectionAction =>
      'Guardar Corrección con Versionado';

  @override
  String get clinicalSaveConsultationAction => 'Guardar Consulta Clínica';

  @override
  String get clinicalSectionPatientTitle =>
      '1. Bloque de Datos del Paciente (Congelado de Solo Lectura)';

  @override
  String get clinicalSystemMucous => 'Mucosas';

  @override
  String get clinicalSystemSkin => 'Piel y Anexos';

  @override
  String get clinicalSystemEars => 'Oídos';

  @override
  String get clinicalSystemCardiovascular => 'Cardiovascular';

  @override
  String get clinicalSystemRespiratory => 'Respiratorio';

  @override
  String get clinicalSystemGastrointestinal => 'Gastrointestinal';

  @override
  String get clinicalSystemNervous => 'Nervioso';

  @override
  String get clinicalSystemMusculoskeletal => 'Músculo-esquelético';

  @override
  String get clinicalSystemGenitourinary => 'Génito-urinario';

  @override
  String get clinicalVersionsSheetTitle => 'Historial de Versiones';

  @override
  String get clinicalVersionDateUnknown => 'Fecha anterior';

  @override
  String get clinicalVersionReasonUnknown => 'Sin motivo';

  @override
  String get clinicalAnnulEntryWarning =>
      'Esta acción es definitiva e inmutable. Se guardará el motivo de la anulación.';

  @override
  String get clinicalAnnulAction => 'Anular';

  @override
  String get sessionInvalid => 'Sesión no válida';

  @override
  String get adminBlockAvailabilitySemantics =>
      'Crear bloqueo de disponibilidad';

  @override
  String get adminBlockConflictsHelp =>
      'Existen citas agendadas en la franja o fecha bloqueada. Resuelva cada conflicto cancelando o reagendando la cita individualmente:';

  @override
  String get adminAgendaEmpty =>
      'No hay citas agendadas para el período o filtros seleccionados.';

  @override
  String get adminAppointmentBlockConflict => 'En conflicto con bloqueo';

  @override
  String get adminAppointmentClinicalPending => 'Ficha clínica pendiente';

  @override
  String get agendaConfirmAppointmentSemantics => 'Confirmar cita';

  @override
  String get agendaConfirmAppointmentTooltip => 'Confirmar Cita';

  @override
  String get agendaCompleteAppointmentTooltip => 'Completar Cita';

  @override
  String get agendaCompleteAppointmentSemantics => 'Completar cita';

  @override
  String get agendaRescheduleAppointmentSemantics => 'Reagendar cita';

  @override
  String get agendaCancelAppointmentSemantics => 'Cancelar cita';

  @override
  String clinicalAttachmentDefaultDesc(int count) {
    return 'Informe clínico complementario #$count';
  }

  @override
  String clinicalTreatmentLineDetails(
    String route,
    String duration,
    String modality,
  ) {
    return 'Vía: $route | Duración: $duration | Mod.: $modality';
  }

  @override
  String clinicalSectionAttachmentsTitle(int count, int max) {
    return '6. Adjuntos Clínicos ($count/$max)';
  }

  @override
  String clinicalPatientDataPet(
    String name,
    String species,
    String breed,
    String sex,
    String age,
  ) {
    return 'Mascota: $name ($species - $breed) | Sexo: $sex | Edad: $age';
  }

  @override
  String clinicalPatientDataReproductive(String status, String birthDate) {
    return 'Estado Reproductivo: $status | Nacimiento: $birthDate';
  }

  @override
  String clinicalPatientDataOwner(
    String name,
    String docType,
    String docNumber,
  ) {
    return 'Propietario: $name | $docType: $docNumber';
  }

  @override
  String clinicalPatientDataContact(
    String phone,
    String email,
    String address,
  ) {
    return 'Contacto: $phone | Correo: $email | Dirección: $address';
  }

  @override
  String clinicalVersionEditedByReason(String editor, String reason) {
    return 'Editado por: $editor\nMotivo: $reason';
  }

  @override
  String clinicalRecordCorrectedBadge(int version) {
    return 'CORREGIDO (v$version)';
  }

  @override
  String clinicalRecordAttendedBy(String authorName) {
    return 'Atendido por: $authorName';
  }

  @override
  String clinicalRecordReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String clinicalRecordAnnulmentReason(String reason) {
    return 'Motivo de anulación: $reason';
  }

  @override
  String adminBlockConflictsDetected(int count) {
    return 'Conflictos de Bloqueo Detectados ($count)';
  }

  @override
  String adminConflictServiceDateTime(
    String service,
    String date,
    String timeSlot,
  ) {
    return '$service | $date a las $timeSlot';
  }

  @override
  String adminAppointmentClientPet(String clientName, String petName) {
    return '$clientName (Mascota: $petName)';
  }

  @override
  String adminAppointmentClientNotes(String notes) {
    return 'Nota del cliente: $notes';
  }

  @override
  String adminProformaClient(String clientName) {
    return 'Cliente: $clientName';
  }

  @override
  String adminProformaCardSummary(int count, String totalLabel, String amount) {
    return 'Ítems: $count · $totalLabel: \$$amount';
  }

  @override
  String paymentSummaryItemQuantity(int quantity) {
    return 'Cant: $quantity';
  }

  @override
  String paymentSummaryItemBase(String amount) {
    return 'Base: \$$amount';
  }

  @override
  String paymentSummaryItemIce(String rate, String amount) {
    return 'ICE ($rate%): \$$amount';
  }

  @override
  String paymentSummaryItemIva(String rate, String amount) {
    return 'IVA ($rate%): \$$amount';
  }

  @override
  String proformaItemQuantityAndIce(int quantity, String amount, int iceBp) {
    return 'Cant: $quantity × \$$amount | ICE: $iceBp bp';
  }

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get loginWelcomeTitle => 'Bienvenido a PetShop';

  @override
  String get loginSubtitle =>
      'Ingresa tus credenciales para acceder a tu panel';

  @override
  String get forgotPasswordInstructionsSentTitle => 'Instrucciones enviadas';

  @override
  String get staffInboxModerationControlsTitle =>
      'Controles de Moderación (Exclusivo Super Usuario)';

  @override
  String get staffInboxSelectConversationPrompt =>
      'Seleccione una conversación para ver los mensajes.';

  @override
  String get staffInboxClientConversationsHeader =>
      'CONVERSACIONES CON CLIENTES';

  @override
  String get staffInboxConversationBlockedNotice =>
      'Esta conversación se encuentra bloqueada administrativamente.';

  @override
  String get staffInboxConversationArchivedNotice =>
      'Esta conversación se encuentra archivada.';

  @override
  String get staffInboxModerateButtonLabel => 'Moderar';

  @override
  String get clinicalRecordAnnulledBadge => 'ANULADO';

  @override
  String adminProformaCardId(String id) {
    return 'Proforma: $id';
  }

  @override
  String get proformaNoItemsAdded =>
      'Esta proforma no contiene ítems agregados.';

  @override
  String adminClientDocAndPhone(
    String docType,
    String docNumber,
    String phone,
  ) {
    return '$docType: $docNumber | Tel: $phone';
  }

  @override
  String adminClientEmailAndPhone(String email, String phone) {
    return 'Correo: $email | Tel: $phone';
  }

  @override
  String pdfDownloadSuccessWithSize(String message, String sizeKb) {
    return '$message ($sizeKb KB)';
  }

  @override
  String get staffProfileTitle => 'Perfil del Personal';

  @override
  String get staffInboxInternalChannelTitle => 'Canal Interno (STAFF_INTERNAL)';

  @override
  String staffInboxClientLabel(String name) {
    return 'Cliente: $name';
  }

  @override
  String clientHomeGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get clientHomeSubtitle => 'Resumen de tu cuenta en PetShop';

  @override
  String get clientHomeNextAppointmentTitle => 'Próxima cita';

  @override
  String get clientHomeNoAppointments => 'Sin citas programadas';

  @override
  String get clientHomeActivePetsTitle => 'Mascotas activas';

  @override
  String get clientHomeActiveRequestsTitle => 'Solicitudes en curso';

  @override
  String get clientHomeNoRequests => 'Sin solicitudes activas';

  @override
  String get clientHomeQuickActionsTitle => 'Accesos rápidos';

  @override
  String get clientHomeRecentMessagesTitle => 'Mensajes recientes';

  @override
  String get clientHomeNoRecentMessages => 'Sin mensajes nuevos del negocio';

  @override
  String get clientHomeBookAppointmentAction => 'Agendar cita';

  @override
  String get clientHomeViewCatalogAction => 'Ver catálogo';

  @override
  String get clientHomeRegisterPetAction => 'Registrar mascota';

  @override
  String get adminDashboardSubtitle => 'Resumen operativo del día';

  @override
  String get adminDashboardAppointmentsToday => 'Citas hoy';

  @override
  String get adminDashboardPendingRequests => 'Solicitudes pendientes';

  @override
  String get adminDashboardLowStock => 'Productos con stock bajo';

  @override
  String get adminDashboardTodayIncome => 'Ingresos del día';

  @override
  String get adminDashboardUpcomingAppointments => 'Próximas citas';

  @override
  String get adminDashboardRecentActivity => 'Actividad reciente';

  @override
  String get adminDashboardNoActivity => 'Sin actividad reciente';

  @override
  String get tableHeaderPet => 'MASCOTA';

  @override
  String get tableHeaderService => 'SERVICIO';

  @override
  String get tableHeaderDateTime => 'FECHA Y HORA';

  @override
  String get tableHeaderState => 'ESTADO';

  @override
  String get tableHeaderAction => 'ACCIÓN';

  @override
  String get tableHeaderProduct => 'PRODUCTO';

  @override
  String get tableHeaderCategory => 'CATEGORÍA';

  @override
  String get tableHeaderStock => 'STOCK';

  @override
  String get tableHeaderPrice => 'PRECIO';

  @override
  String get tableHeaderClient => 'CLIENTE';

  @override
  String get tableHeaderHour => 'HORA';

  @override
  String get tableHeaderBasePrice => 'PRECIO BASE';

  @override
  String get tableHeaderDuration => 'DURACIÓN';

  @override
  String get tableHeaderType => 'TIPO';

  @override
  String get tableHeaderRole => 'ROL';

  @override
  String get tableHeaderEmail => 'CORREO';

  @override
  String get tableHeaderPhone => 'TELÉFONO';

  @override
  String get tableHeaderName => 'NOMBRE';

  @override
  String get tableHeaderNumber => 'N.°';

  @override
  String get tableHeaderTotal => 'TOTAL';

  @override
  String get clinicalUploadsContainedNotice =>
      'Por ahora no se pueden adjuntar archivos ni actualizar la foto de la mascota desde la consulta.';
}

/// The translations for Spanish Castilian, as used in Latin America and the Caribbean (`es_419`).
class AppLocalizationsEs419 extends AppLocalizationsEs {
  AppLocalizationsEs419() : super('es_419');

  @override
  String get adminGovernanceUnderConstruction =>
      'Módulo en construcción. La gestión de gobierno y cuentas estará disponible próximamente.';

  @override
  String get adminClientsManagementTitle => 'Gestión de Clientes';

  @override
  String get adminClientsActiveTab => 'Clientes Activos';

  @override
  String get adminClientsDeactivatedTab => 'Cuentas Desactivadas';

  @override
  String get adminClientsSearchLabel => 'Buscar por nombre o cédula';

  @override
  String get adminClientsSearchHint => 'Escribe el nombre del cliente...';

  @override
  String get adminClientsEmptyActive =>
      'No se encontraron clientes registrados.';

  @override
  String get adminClientsEmptyDeactivated =>
      'No hay cuentas desactivadas actualmente.';

  @override
  String get adminClientsStatusDeactivated => 'Estado: DESACTIVADA';

  @override
  String get adminClientsReactivateTitle => 'Reactivar Cuenta';

  @override
  String adminClientsReactivateContent(String fullName) {
    return '¿Deseas reactivar la cuenta de $fullName?';
  }

  @override
  String get adminClientsReactivateConfirm => 'Reactivar';

  @override
  String get adminClientsTooltipView => 'Ver Ficha';

  @override
  String get adminClientsSemanticsView => 'Ver ficha de cliente';

  @override
  String get adminClientsSemanticsReactivate => 'Reactivar cuenta de usuario';

  @override
  String adminClientDetailTitle(String fullName) {
    return 'Ficha de Cliente: $fullName';
  }

  @override
  String get adminClientIdentityTitle => 'Datos de Identidad (Sólo Lectura)';

  @override
  String get adminClientFieldFullName => 'Nombre Completo';

  @override
  String get adminClientFieldDocument => 'Documento de Identidad';

  @override
  String get adminClientFieldEmail => 'Correo Electrónico';

  @override
  String get adminClientFieldPhone => 'Teléfono de Contacto';

  @override
  String get adminClientFieldAddress => 'Dirección Domiciliaria';

  @override
  String get adminClientFieldRole => 'Rol en el Sistema';

  @override
  String get adminClientAddressNotRegistered => 'No registrada';

  @override
  String adminClientPetsRegisteredTitle(int count) {
    return 'Mascotas Registradas ($count)';
  }

  @override
  String get adminClientNoPets => 'El cliente no tiene mascotas registradas.';

  @override
  String get adminClientTooltipBack => 'Volver al listado';

  @override
  String get adminClientSemanticsBack => 'Volver al listado de clientes';

  @override
  String adminPetCorrectionTitle(String name) {
    return 'Corregir Ficha de $name';
  }

  @override
  String get adminPetCorrectionNote =>
      'Nota: El personal sólo está autorizado a rectificar el sexo y estado reproductivo de la mascota.';

  @override
  String get adminPetCorrectionSexLabel => 'Sexo';

  @override
  String get adminPetCorrectionReproductiveLabel => 'Estado Reproductivo';

  @override
  String get adminPetCorrectionSexMale => 'Macho (MALE)';

  @override
  String get adminPetCorrectionSexFemale => 'Hembra (FEMALE)';

  @override
  String get adminPetCorrectionReproductiveIntact => 'Fértil / Entero (INTACT)';

  @override
  String get adminPetCorrectionReproductiveNeutered =>
      'Esterilizado / Castrado (NEUTERED)';

  @override
  String get adminPetCorrectionReproductiveUnknown => 'Desconocido (UNKNOWN)';

  @override
  String get adminPetCorrectionSave => 'Guardar Corrección';

  @override
  String get adminPetCorrectionAction => 'Corregir';

  @override
  String get adminPetCorrectionTooltip => 'Corregir Sexo/Estado';

  @override
  String get adminPetCorrectionSemantics =>
      'Corregir sexo y estado reproductivo de la mascota';

  @override
  String adminPetSpeciesLabel(String species, String breed) {
    return 'Especie: $species | Raza: $breed';
  }

  @override
  String adminPetSexReproductiveLabel(String sex, String reproductiveStatus) {
    return 'Sexo: $sex | Reproductivo: $reproductiveStatus';
  }

  @override
  String get adminPetBreedNotSpecified => 'No especificada';

  @override
  String get adminBlockAvailabilityTitle => 'Bloquear Disponibilidad';

  @override
  String get adminBlockAction => 'Bloquear';

  @override
  String get adminRescheduleAppointmentTitle => 'Reagendar Cita';

  @override
  String get adminRescheduleAction => 'Reagendar';

  @override
  String get adminAgendaTitle => 'Agenda Administrativa';

  @override
  String get adminStatusFilterLabel => 'Estado';

  @override
  String get adminConfirmAction => 'Confirmar';

  @override
  String get adminCompleteAction => 'Completar';

  @override
  String get adminViewModeWeek => 'Semanal';

  @override
  String get adminViewModeMonth => 'Mensual';

  @override
  String get adminStatusFilterAll => 'Todos los estados';

  @override
  String get adminStatusFilterPending => 'Pendientes';

  @override
  String get adminStatusFilterConfirmed => 'Confirmadas';

  @override
  String get adminStatusFilterCompleted => 'Completadas';

  @override
  String get adminStatusFilterCancelled => 'Canceladas';

  @override
  String get clinicalEntryAnnulmentTitle => 'Anulación de Entrada Clínica';

  @override
  String get clinicalEntryAnnulAction => 'Anular Registro';

  @override
  String get clinicalViewVersionsAction => 'Ver Versiones';

  @override
  String get clinicalCorrectAction => 'Corregir';

  @override
  String get clinicalConsultationAnnulmentTitle =>
      'Anulación de Registro Clínico';

  @override
  String get clinicalConfirmAnnulmentAction => 'Confirmar Anulación';

  @override
  String get clinicalPrescribeTreatmentTitle => 'Prescribir Tratamiento';

  @override
  String get clinicalAddPrescriptionLineAction => 'Añadir Línea';

  @override
  String get clinicalPrescribeMedicationAction => 'Prescribir Medicamento';

  @override
  String get clinicalUploadAttachmentAction => 'Subir Archivo Adjunto';

  @override
  String get clinicalUpdatePetPhotoAction => 'Actualizar Foto Mascota';

  @override
  String get agendaBlockDateLabel => 'Fecha (YYYY-MM-DD)';

  @override
  String get agendaBlockDateHint => '2026-09-02';

  @override
  String get agendaBlockSlotLabel => 'Franja horaria (opcional, ej. 09:00)';

  @override
  String get agendaBlockSlotHint =>
      'Dejar en blanco para bloquear día completo';

  @override
  String get agendaBlockReasonLabel => 'Motivo del bloqueo';

  @override
  String get agendaBlockReasonHint =>
      'Mantenimiento, feriado o ausencia médica';

  @override
  String get agendaRescheduleDateLabel => 'Nueva Fecha (YYYY-MM-DD)';

  @override
  String get agendaRescheduleSlotLabel => 'Nueva Franja (HH:mm)';

  @override
  String get agendaCancelAppointmentTooltip => 'Cancelar Cita';

  @override
  String get agendaCancelConflictSemantic => 'Cancelar cita en conflicto';

  @override
  String get agendaRescheduleAppointmentTooltip => 'Reagendar Cita';

  @override
  String get agendaRescheduleConflictSemantic => 'Reagendar cita en conflicto';

  @override
  String get agendaPreviousDayTooltip => 'Día anterior';

  @override
  String get agendaPreviousDaySemantic => 'Día anterior';

  @override
  String get agendaNextDayTooltip => 'Día siguiente';

  @override
  String get agendaNextDaySemantic => 'Día siguiente';

  @override
  String get clinicalAnnulReasonLabel => 'Motivo obligatorio de anulación *';

  @override
  String get clinicalMedicationLabel => 'Medicamento *';

  @override
  String get clinicalDoseLabel => 'Dosis * (ej: 10 mg/kg)';

  @override
  String get clinicalRouteLabel => 'Vía de administración *';

  @override
  String get clinicalDurationLabel => 'Duración * (ej: 7 días)';

  @override
  String get clinicalModalityLabel => 'Modalidad *';

  @override
  String get clinicalAnnulRecordTooltip => 'Anular registro clínico';

  @override
  String get clinicalAnnulRecordSemantic => 'Anular registro clínico';

  @override
  String get clinicalDeferTooltip => 'Aplazar o cerrar el registro';

  @override
  String get clinicalDeferSemantic => 'Aplazar formulario';

  @override
  String get clinicalDeferAction => 'Aplazar';

  @override
  String get clinicalReasonLabel => 'Motivo de consulta *';

  @override
  String get clinicalCurrentIllnessLabel => 'Enfermedad actual (opcional)';

  @override
  String get clinicalBackgroundLabel => 'Antecedentes médicos (opcional)';

  @override
  String get clinicalDiagnosisLabel => 'Diagnóstico';

  @override
  String get clinicalDiagnosisTypeLabel => 'Tipo de Diagnóstico';

  @override
  String get clinicalDiagnosisPresumptive => 'Presuntivo';

  @override
  String get clinicalDiagnosisDefinitive => 'Definitivo';

  @override
  String get clinicalOwnerInstructionsLabel =>
      'Indicaciones para el propietario (opcional)';

  @override
  String get clinicalTemperatureLabel => 'T° (°C)';

  @override
  String get clinicalTemperatureHint => 'ej: 38.5';

  @override
  String get clinicalHeartRateLabel => 'FC (lpm)';

  @override
  String get clinicalHeartRateHint => '10..400';

  @override
  String get clinicalRespRateLabel => 'FR (rpm)';

  @override
  String get clinicalRespRateHint => '5..200';

  @override
  String get clinicalWeightLabel => 'Peso (kg)';

  @override
  String get clinicalWeightHint => 'ej: 12.5';

  @override
  String get clinicalBodyConditionLabel => 'CC (1 a 9)';

  @override
  String get clinicalSystemNotExamined => 'No examinado';

  @override
  String get clinicalSystemNormal => 'Normal';

  @override
  String get clinicalSystemAbnormal => 'Alterado';

  @override
  String get clinicalNoPreviousVersions =>
      'No existen versiones anteriores registradas.';

  @override
  String get clinicalAnnulReasonHistoryLabel =>
      'Motivo obligatorio de anulación *';

  @override
  String get clinicalNoRecords =>
      'La mascota no tiene registros clínicos registrados.';

  @override
  String get dashboardShortcutsTooltip => 'Ver atajos de teclado (?)';

  @override
  String get dashboardShortcutsSemantic => 'Ver atajos de teclado';

  @override
  String get dashboardRefreshTooltip => 'Actualizar métricas';

  @override
  String get dashboardRefreshSemantic => 'Actualizar métricas';

  @override
  String clinicalFindingsLabel(String system) {
    return 'Hallazgos descriptivos obligatorios para $system *';
  }

  @override
  String clinicalVersionEntry(String number, String date) {
    return 'Versión $number - $date';
  }

  @override
  String clinicalHistoryTitle(String pet) {
    return 'Historial Clínico: $pet';
  }

  @override
  String clinicalHistoryLoadError(String error) {
    return 'Error al cargar historial: $error';
  }

  @override
  String clinicalDiagnosisSummary(String diagnosis) {
    return 'Diagnóstico: $diagnosis';
  }

  @override
  String dashboardMetricDetailTooltip(String metric) {
    return 'Ver detalle de $metric';
  }

  @override
  String get clinicalFindingsHelper =>
      'Requerido al marcar el sistema como alterado.';

  @override
  String get clinicalReasonHelper => 'Obligatorio. Máximo 500 caracteres.';

  @override
  String clinicalPrescriptionLine(String medication, String dose) {
    return '$medication ($dose)';
  }

  @override
  String clinicalAttachmentLine(String path, String bytes) {
    return '$path ($bytes B)';
  }

  @override
  String clinicalVersionBadge(String number) {
    return 'v$number';
  }

  @override
  String dashboardMetricSemantic(String metric, String value) {
    return '$metric: $value';
  }

  @override
  String get navAdminDashboard => 'Panel';

  @override
  String get navAdminClients => 'Clientes';

  @override
  String get navAdminServices => 'Servicios';

  @override
  String get navAdminClinical => 'Clínica';

  @override
  String get govTitle => 'Gobierno y Cuentas';

  @override
  String get govTabAccounts => 'Cuentas de Usuario';

  @override
  String get govTabOperatingParameters => 'Configuración Operativa';

  @override
  String get govTabAuditLog => 'Registro de Auditoría';

  @override
  String get govSearchPlaceholder => 'Buscar por nombre, correo o cédula...';

  @override
  String get govCreateAccountButton => 'Crear Cuenta';

  @override
  String get govRoleFilterAll => 'Todos los roles';

  @override
  String get govRoleSuperAdmin => 'Super Usuario';

  @override
  String get govRoleAdmin => 'Administrador';

  @override
  String get govRoleClient => 'Cliente';

  @override
  String get govStatusActive => 'Activo';

  @override
  String get govStatusDeactivated => 'Desactivado';

  @override
  String get govStatusDeleted => 'Eliminado';

  @override
  String get govColumnName => 'Nombre';

  @override
  String get govColumnEmail => 'Correo';

  @override
  String get govColumnRole => 'Rol';

  @override
  String get govColumnStatus => 'Estado';

  @override
  String get govColumnActions => 'Acciones';

  @override
  String get govSuperAdminImmutableBadge => 'Inmutable';

  @override
  String get govActionEditIdentity => 'Editar Identidad';

  @override
  String get govActionResetPassword => 'Restablecer Contraseña';

  @override
  String get govActionDeactivate => 'Desactivar Cuenta';

  @override
  String get govActionDeleteStaff => 'Eliminar Personal';

  @override
  String get govNoAccountsFound => 'No se encontraron cuentas de usuario.';

  @override
  String get govCreateAccountDialogTitle => 'Crear Nueva Cuenta';

  @override
  String get govFieldEmail => 'Correo Electrónico';

  @override
  String get govFieldFullName => 'Nombre Completo';

  @override
  String get govFieldRole => 'Rol de la Cuenta';

  @override
  String get govFieldPhone => 'Teléfono (+593...)';

  @override
  String get govFieldDocumentType => 'Tipo de Documento';

  @override
  String get govFieldDocumentNumber => 'Número de Documento';

  @override
  String get govFieldAddress => 'Dirección';

  @override
  String get govButtonCancel => 'Cancelar';

  @override
  String get govButtonCreate => 'Crear y Generar Enlace';

  @override
  String get govValidationRequired => 'Este campo es obligatorio';

  @override
  String get govValidationInvalidEmail => 'Correo electrónico no válido';

  @override
  String get govValidationInvalidPhone =>
      'Teléfono no válido (+593 seguido de 9 dígitos)';

  @override
  String get govEditIdentityDialogTitle => 'Editar Identidad de Cuenta';

  @override
  String get govEmailReadOnlyNotice =>
      'El correo electrónico es de sólo lectura y no puede modificarse.';

  @override
  String get govButtonSave => 'Guardar Cambios';

  @override
  String get govLinkDialogTitleCreated => 'Cuenta Aprovisionada con Éxito';

  @override
  String get govLinkDialogTitleReset => 'Enlace de Restablecimiento Generado';

  @override
  String get govLinkDialogNotice =>
      'Entregue el siguiente enlace al usuario de forma presencial o por canal seguro. El sistema NO despacha correos automáticos:';

  @override
  String get govButtonCopyLink => 'Copiar Enlace';

  @override
  String get govLinkCopiedSnackbar => 'Enlace copiado al portapapeles.';

  @override
  String get govButtonClose => 'Cerrar';

  @override
  String get govConfirmDeactivateTitle => 'Confirmar Desactivación';

  @override
  String govConfirmDeactivateMessage(String name) {
    return '¿Está seguro de que desea desactivar la cuenta de $name? Se revocarán sus sesiones y se cancelarán citas activas.';
  }

  @override
  String get govButtonConfirmDeactivate => 'Desactivar';

  @override
  String get govConfirmDeleteStaffTitle => 'Confirmar Baja Lógica de Personal';

  @override
  String govConfirmDeleteStaffMessage(String name) {
    return '¿Está seguro de dar de baja lógica a $name? Su cuenta quedará deshabilitada pero su historial clínico y contable se preservará íntegro.';
  }

  @override
  String get govButtonConfirmDelete => 'Eliminar Personal';

  @override
  String get govOperatingParamsTitle => 'Parámetros Operativos del Negocio';

  @override
  String get govOperatingParamsDescription =>
      'Configuración general de horarios, turnos y umbrales de inventario. La zona horaria institucional es inmutable (America/Guayaquil).';

  @override
  String get govFieldOpeningTime => 'Hora de Apertura (HH:mm)';

  @override
  String get govFieldClosingTime => 'Hora de Cierre (HH:mm)';

  @override
  String get govFieldSlotDuration => 'Duración de Turno (minutos)';

  @override
  String get govFieldWorkingDays => 'Días Laborables';

  @override
  String get govFieldLowStockThreshold => 'Umbral de Stock Bajo';

  @override
  String get govDayMonday => 'Lunes';

  @override
  String get govDayTuesday => 'Martes';

  @override
  String get govDayWednesday => 'Miércoles';

  @override
  String get govDayThursday => 'Jueves';

  @override
  String get govDayFriday => 'Viernes';

  @override
  String get govDaySaturday => 'Sábado';

  @override
  String get govDaySunday => 'Domingo';

  @override
  String get govButtonSaveParams => 'Guardar Parámetros';

  @override
  String get govParamsSavedSuccess =>
      'Parámetros operativos actualizados correctamente.';

  @override
  String get govInvalidTimeOrder =>
      'La hora de apertura debe ser anterior a la de cierre.';

  @override
  String get govAuditLogTitle => 'Registro de Auditoría';

  @override
  String get govAuditLogEmpty => 'No hay registros de auditoría disponibles.';

  @override
  String get govAuditColumnDate => 'Fecha y Hora';

  @override
  String get govAuditColumnActor => 'Actor';

  @override
  String get govAuditColumnAction => 'Acción';

  @override
  String get govAuditColumnTarget => 'Objetivo';

  @override
  String get govAuditColumnMetadata => 'Metadatos';

  @override
  String get govButtonRefresh => 'Actualizar';

  @override
  String get govAuditFilterAction => 'Filtrar por acción';

  @override
  String get govAuditAllActions => 'Todas las acciones';

  @override
  String get adminNavClients => 'Clientes';

  @override
  String get adminNavClinical => 'Registro Clínico';

  @override
  String get adminNavChat => 'Bandeja de Mensajería';
}
