import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('es', '419'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'PetShop Web'**
  String get appTitle;

  /// No description provided for @imageFormatUnsupported.
  ///
  /// In es, this message translates to:
  /// **'El formato del archivo no es compatible. Solo se admiten imágenes en formato JPEG, PNG, WebP y AVIF.'**
  String get imageFormatUnsupported;

  /// No description provided for @imageFormatHeicRejected.
  ///
  /// In es, this message translates to:
  /// **'Los archivos en formato de alta eficiencia (HEIC/HEIF) no están admitidos. Por favor, selecciona una imagen en formato JPEG, PNG, WebP o AVIF.'**
  String get imageFormatHeicRejected;

  /// No description provided for @imageSizeExceeded.
  ///
  /// In es, this message translates to:
  /// **'El archivo excede el tamaño máximo permitido de 5 MB.'**
  String get imageSizeExceeded;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @loadingSession.
  ///
  /// In es, this message translates to:
  /// **'Verificando sesión...'**
  String get loadingSession;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @accept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get accept;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @offlineBannerMessage.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión a Internet. Las acciones están deshabilitadas para proteger la integridad de los datos.'**
  String get offlineBannerMessage;

  /// No description provided for @connectionRestored.
  ///
  /// In es, this message translates to:
  /// **'Conexión restablecida.'**
  String get connectionRestored;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navPets.
  ///
  /// In es, this message translates to:
  /// **'Mis Mascotas'**
  String get navPets;

  /// No description provided for @navAppointments.
  ///
  /// In es, this message translates to:
  /// **'Citas'**
  String get navAppointments;

  /// No description provided for @navCatalog.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get navCatalog;

  /// No description provided for @navBilling.
  ///
  /// In es, this message translates to:
  /// **'Facturación'**
  String get navBilling;

  /// No description provided for @navChat.
  ///
  /// In es, this message translates to:
  /// **'Mensajería'**
  String get navChat;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi Perfil'**
  String get navProfile;

  /// No description provided for @navAdmin.
  ///
  /// In es, this message translates to:
  /// **'Panel de Administración'**
  String get navAdmin;

  /// No description provided for @navAdminAgenda.
  ///
  /// In es, this message translates to:
  /// **'Agenda General'**
  String get navAdminAgenda;

  /// No description provided for @navAdminGovernance.
  ///
  /// In es, this message translates to:
  /// **'Gobierno y Cuentas'**
  String get navAdminGovernance;

  /// No description provided for @navLogin.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get navLogin;

  /// No description provided for @navRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get navRegister;

  /// No description provided for @navForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'Recuperar Contraseña'**
  String get navForgotPassword;

  /// No description provided for @navSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get navSignOut;

  /// No description provided for @unauthorizedAdminAccess.
  ///
  /// In es, this message translates to:
  /// **'No tienes permisos de administrador.'**
  String get unauthorizedAdminAccess;

  /// No description provided for @unauthorizedGovernanceAccess.
  ///
  /// In es, this message translates to:
  /// **'No tienes permisos para acceder al módulo de gobierno.'**
  String get unauthorizedGovernanceAccess;

  /// No description provided for @unauthorizedGeneral.
  ///
  /// In es, this message translates to:
  /// **'No tienes autorización para acceder a esta sección.'**
  String get unauthorizedGeneral;

  /// No description provided for @sessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ha expirado o requiere reautenticación.'**
  String get sessionExpired;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error inesperado. Por favor, intenta nuevamente.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Por favor, revisa tu acceso a internet.'**
  String get errorNetwork;

  /// No description provided for @errorSlotTaken.
  ///
  /// In es, this message translates to:
  /// **'El horario seleccionado ya no se encuentra disponible.'**
  String get errorSlotTaken;

  /// No description provided for @errorPetAlreadyBookedThatDay.
  ///
  /// In es, this message translates to:
  /// **'La mascota ya cuenta con una cita programada para ese día.'**
  String get errorPetAlreadyBookedThatDay;

  /// No description provided for @errorSlotBlocked.
  ///
  /// In es, this message translates to:
  /// **'El horario seleccionado se encuentra bloqueado para reservas.'**
  String get errorSlotBlocked;

  /// No description provided for @errorAppointmentNotReschedulable.
  ///
  /// In es, this message translates to:
  /// **'La cita no se puede reagendar en su estado actual.'**
  String get errorAppointmentNotReschedulable;

  /// No description provided for @errorProformaEmpty.
  ///
  /// In es, this message translates to:
  /// **'La proforma debe contener al menos un concepto.'**
  String get errorProformaEmpty;

  /// No description provided for @errorTooManyItems.
  ///
  /// In es, this message translates to:
  /// **'Se ha excedido el límite máximo de elementos permitidos.'**
  String get errorTooManyItems;

  /// No description provided for @errorTooManyAttachments.
  ///
  /// In es, this message translates to:
  /// **'Se ha excedido el límite máximo de adjuntos permitidos.'**
  String get errorTooManyAttachments;

  /// No description provided for @errorDailyLimitAppointments.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado el límite diario de citas permitidas.'**
  String get errorDailyLimitAppointments;

  /// No description provided for @errorDailyLimitRequests.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado el límite diario de solicitudes permitidas.'**
  String get errorDailyLimitRequests;

  /// No description provided for @errorOutOfStock.
  ///
  /// In es, this message translates to:
  /// **'El producto solicitado está agotado.'**
  String get errorOutOfStock;

  /// No description provided for @errorAppointmentNotCancellable.
  ///
  /// In es, this message translates to:
  /// **'La cita ya no puede ser cancelada.'**
  String get errorAppointmentNotCancellable;

  /// No description provided for @errorAlreadyCancelled.
  ///
  /// In es, this message translates to:
  /// **'La cita ya fue cancelada anteriormente.'**
  String get errorAlreadyCancelled;

  /// No description provided for @errorPetNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'La mascota seleccionada no está disponible o no se encuentra activa.'**
  String get errorPetNotAvailable;

  /// No description provided for @errorServiceNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'El servicio seleccionado no está disponible en este momento.'**
  String get errorServiceNotAvailable;

  /// No description provided for @errorConfigUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la configuración del sistema. Intenta de nuevo.'**
  String get errorConfigUnavailable;

  /// No description provided for @errorPetAlreadyDeactivated.
  ///
  /// In es, this message translates to:
  /// **'La mascota ya ha sido dada de baja previamente.'**
  String get errorPetAlreadyDeactivated;

  /// No description provided for @errorNoChange.
  ///
  /// In es, this message translates to:
  /// **'No se han detectado cambios respecto al estado original.'**
  String get errorNoChange;

  /// No description provided for @errorInvalidTransition.
  ///
  /// In es, this message translates to:
  /// **'La operación solicitada no es válida para el estado actual.'**
  String get errorInvalidTransition;

  /// No description provided for @errorConceptLockedByDeliveredProforma.
  ///
  /// In es, this message translates to:
  /// **'El concepto no puede modificarse porque está incluido en una proforma entregada.'**
  String get errorConceptLockedByDeliveredProforma;

  /// No description provided for @errorProformaNotDraft.
  ///
  /// In es, this message translates to:
  /// **'La proforma solo puede modificarse mientras esté en borrador.'**
  String get errorProformaNotDraft;

  /// No description provided for @errorProformaNotVoidable.
  ///
  /// In es, this message translates to:
  /// **'La proforma no puede ser anulada en su estado actual.'**
  String get errorProformaNotVoidable;

  /// No description provided for @errorDeliveryInProgress.
  ///
  /// In es, this message translates to:
  /// **'Hay una entrega en progreso para este concepto.'**
  String get errorDeliveryInProgress;

  /// No description provided for @errorDeliveryLeaseLost.
  ///
  /// In es, this message translates to:
  /// **'Se perdió el bloqueo exclusivo de entrega. Intenta nuevamente.'**
  String get errorDeliveryLeaseLost;

  /// No description provided for @errorConceptNoLongerValid.
  ///
  /// In es, this message translates to:
  /// **'El concepto ya no es válido para su procesamiento.'**
  String get errorConceptNoLongerValid;

  /// No description provided for @errorEntryAnnulledNotEditable.
  ///
  /// In es, this message translates to:
  /// **'Una entrada anulada no puede ser modificada.'**
  String get errorEntryAnnulledNotEditable;

  /// No description provided for @errorAnnulmentNotAnnullable.
  ///
  /// In es, this message translates to:
  /// **'Una entrada de anulación no puede ser anulada.'**
  String get errorAnnulmentNotAnnullable;

  /// No description provided for @errorSuperadminImmutable.
  ///
  /// In es, this message translates to:
  /// **'La cuenta de Super Administrador no puede ser modificada por esta vía.'**
  String get errorSuperadminImmutable;

  /// No description provided for @errorRoleChangeNotSupported.
  ///
  /// In es, this message translates to:
  /// **'No se permite el cambio de rol en la cuenta.'**
  String get errorRoleChangeNotSupported;

  /// No description provided for @errorReauthRequired.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, debes volver a iniciar sesión para realizar esta acción.'**
  String get errorReauthRequired;

  /// No description provided for @errorAccountNotActive.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta se encuentra inactiva o deshabilitada. Contacta al soporte.'**
  String get errorAccountNotActive;

  /// No description provided for @errorProfileAlreadyComplete.
  ///
  /// In es, this message translates to:
  /// **'El perfil de usuario ya ha sido completado anteriormente.'**
  String get errorProfileAlreadyComplete;

  /// No description provided for @errorAccountProvisioningFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al crear la cuenta. Por favor, intenta de nuevo.'**
  String get errorAccountProvisioningFailed;

  /// No description provided for @errorStaffReactivationRequiresSuperadmin.
  ///
  /// In es, this message translates to:
  /// **'La reactivación de cuentas de personal requiere permisos de Super Usuario.'**
  String get errorStaffReactivationRequiresSuperadmin;

  /// No description provided for @errorVerificationRequired.
  ///
  /// In es, this message translates to:
  /// **'Es obligatorio completar la verificación de seguridad.'**
  String get errorVerificationRequired;

  /// No description provided for @errorVerificationFailed.
  ///
  /// In es, this message translates to:
  /// **'La verificación de seguridad no fue superada o ha caducado. Intenta de nuevo.'**
  String get errorVerificationFailed;

  /// No description provided for @errorVerificationActionMismatch.
  ///
  /// In es, this message translates to:
  /// **'La verificación de seguridad no coincide con la acción solicitada.'**
  String get errorVerificationActionMismatch;

  /// No description provided for @errorVerificationHighRisk.
  ///
  /// In es, this message translates to:
  /// **'No se pudo validar la solicitud por motivos de seguridad.'**
  String get errorVerificationHighRisk;

  /// No description provided for @errorVerificationUnavailable.
  ///
  /// In es, this message translates to:
  /// **'El servicio de verificación de seguridad no está disponible momentáneamente.'**
  String get errorVerificationUnavailable;

  /// No description provided for @errorInvalidStockAdjustment.
  ///
  /// In es, this message translates to:
  /// **'El ajuste solicitado dejaría el inventario en un valor negativo.'**
  String get errorInvalidStockAdjustment;

  /// No description provided for @errorRequestLockedByDeliveredProforma.
  ///
  /// In es, this message translates to:
  /// **'La solicitud está vinculada a una proforma entregada.'**
  String get errorRequestLockedByDeliveredProforma;

  /// No description provided for @errorEmptyRequest.
  ///
  /// In es, this message translates to:
  /// **'Debes seleccionar al menos un producto para enviar la solicitud.'**
  String get errorEmptyRequest;

  /// Error al superar el limite de lineas de solicitud
  ///
  /// In es, this message translates to:
  /// **'No puedes solicitar más de {max} productos distintos a la vez.'**
  String errorTooManyRequestLines(int max);

  /// No description provided for @errorDuplicateProductLine.
  ///
  /// In es, this message translates to:
  /// **'Hay productos duplicados en la solicitud.'**
  String get errorDuplicateProductLine;

  /// Error cuando la cantidad no es valida
  ///
  /// In es, this message translates to:
  /// **'La cantidad de cada producto debe estar entre 1 y {max} unidades.'**
  String errorInvalidQuantity(int max);

  /// No description provided for @errorProductNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'Uno o más productos ya no están disponibles en el catálogo.'**
  String get errorProductNotAvailable;

  /// Error cuando productos especificos ya no estan disponibles
  ///
  /// In es, this message translates to:
  /// **'Ya no están disponibles en el catálogo: {products}.'**
  String errorProductNotAvailableNamed(String products);

  /// Error cuando no hay stock para productos especificos
  ///
  /// In es, this message translates to:
  /// **'Están agotados: {products}.'**
  String errorOutOfStockNamed(String products);

  /// No description provided for @errorInsufficientStock.
  ///
  /// In es, this message translates to:
  /// **'No hay existencias suficientes para la cantidad solicitada.'**
  String get errorInsufficientStock;

  /// Error cuando el stock es insuficiente para productos especificos
  ///
  /// In es, this message translates to:
  /// **'No hay existencias suficientes para la cantidad solicitada de: {products}.'**
  String errorInsufficientStockNamed(String products);

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos.'**
  String get errorInvalidCredentials;

  /// No description provided for @forgotPasswordConfirmation.
  ///
  /// In es, this message translates to:
  /// **'Si la cuenta existe, se ha enviado un correo con instrucciones para restablecer tu contraseña.'**
  String get forgotPasswordConfirmation;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada exitosamente.'**
  String get changePasswordSuccess;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo Electrónico'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Contraseña'**
  String get confirmPasswordLabel;

  /// No description provided for @fullNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre Completo'**
  String get fullNameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get phoneLabel;

  /// No description provided for @documentTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de Documento'**
  String get documentTypeLabel;

  /// No description provided for @documentNumberLabel.
  ///
  /// In es, this message translates to:
  /// **'Número de Documento'**
  String get documentNumberLabel;

  /// No description provided for @addressLabel.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get addressLabel;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña Actual'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Nueva Contraseña'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Nueva Contraseña'**
  String get confirmNewPasswordLabel;

  /// No description provided for @createAccountAction.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get createAccountAction;

  /// No description provided for @loginAction.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get loginAction;

  /// No description provided for @sendResetInstructionsAction.
  ///
  /// In es, this message translates to:
  /// **'Enviar Instrucciones'**
  String get sendResetInstructionsAction;

  /// No description provided for @changePasswordAction.
  ///
  /// In es, this message translates to:
  /// **'Cambiar Contraseña'**
  String get changePasswordAction;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes una cuenta? Inicia sesión'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes una cuenta? Regístrate'**
  String get dontHaveAccount;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPasswordLink;

  /// No description provided for @verificationCheckboxLabel.
  ///
  /// In es, this message translates to:
  /// **'No soy un robot'**
  String get verificationCheckboxLabel;

  /// No description provided for @verificationSuccess.
  ///
  /// In es, this message translates to:
  /// **'Verificación completada'**
  String get verificationSuccess;

  /// No description provided for @verificationFailed.
  ///
  /// In es, this message translates to:
  /// **'Error de verificación'**
  String get verificationFailed;

  /// No description provided for @verifying.
  ///
  /// In es, this message translates to:
  /// **'Verificando...'**
  String get verifying;

  /// No description provided for @backToLogin.
  ///
  /// In es, this message translates to:
  /// **'Volver a Iniciar Sesión'**
  String get backToLogin;

  /// No description provided for @docTypeCedula.
  ///
  /// In es, this message translates to:
  /// **'Cédula'**
  String get docTypeCedula;

  /// No description provided for @docTypeRuc.
  ///
  /// In es, this message translates to:
  /// **'RUC'**
  String get docTypeRuc;

  /// No description provided for @docTypePassport.
  ///
  /// In es, this message translates to:
  /// **'Pasaporte'**
  String get docTypePassport;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Restablecer Contraseña'**
  String get resetPasswordTitle;

  /// No description provided for @validationEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'El correo es obligatorio.'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico inválido.'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es obligatoria.'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordMinLength.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres.'**
  String get validationPasswordMinLength;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @validationCurrentPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Debes ingresar tu contraseña actual para continuar.'**
  String get validationCurrentPasswordRequired;

  /// No description provided for @validationFullNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre completo es obligatorio y debe tener entre 1 y 100 caracteres.'**
  String get validationFullNameRequired;

  /// No description provided for @validationPhoneRequired.
  ///
  /// In es, this message translates to:
  /// **'El teléfono de contacto es obligatorio.'**
  String get validationPhoneRequired;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In es, this message translates to:
  /// **'El teléfono de contacto debe tener formato ecuatoriano (+593 seguido de 9 dígitos).'**
  String get validationPhoneInvalid;

  /// No description provided for @validationDocTypeInvalid.
  ///
  /// In es, this message translates to:
  /// **'El tipo de documento debe ser CEDULA, PASSPORT o RUC.'**
  String get validationDocTypeInvalid;

  /// No description provided for @validationDocNumberRequired.
  ///
  /// In es, this message translates to:
  /// **'El número de documento es obligatorio.'**
  String get validationDocNumberRequired;

  /// No description provided for @validationCedulaInvalid.
  ///
  /// In es, this message translates to:
  /// **'La cédula debe contener exactamente 10 dígitos numéricos.'**
  String get validationCedulaInvalid;

  /// No description provided for @validationRucInvalid.
  ///
  /// In es, this message translates to:
  /// **'El RUC debe contener exactamente 13 dígitos numéricos.'**
  String get validationRucInvalid;

  /// No description provided for @validationPassportInvalid.
  ///
  /// In es, this message translates to:
  /// **'El pasaporte debe contener entre 5 y 20 caracteres alfanuméricos.'**
  String get validationPassportInvalid;

  /// No description provided for @validationDocNumberInvalid.
  ///
  /// In es, this message translates to:
  /// **'El número de documento no es válido para el tipo seleccionado.'**
  String get validationDocNumberInvalid;

  /// No description provided for @validationAddressRequired.
  ///
  /// In es, this message translates to:
  /// **'La dirección es obligatoria y debe tener entre 1 y 200 caracteres.'**
  String get validationAddressRequired;

  /// No description provided for @validationAddressMaxLength.
  ///
  /// In es, this message translates to:
  /// **'La dirección no puede exceder los 200 caracteres.'**
  String get validationAddressMaxLength;

  /// No description provided for @errorEmailAlreadyInUse.
  ///
  /// In es, this message translates to:
  /// **'El correo ya se encuentra registrado.'**
  String get errorEmailAlreadyInUse;

  /// No description provided for @errorInvalidProfileData.
  ///
  /// In es, this message translates to:
  /// **'Los datos del perfil no son válidos.'**
  String get errorInvalidProfileData;

  /// No description provided for @errorCurrentPasswordIncorrect.
  ///
  /// In es, this message translates to:
  /// **'La contraseña actual ingresada es incorrecta.'**
  String get errorCurrentPasswordIncorrect;

  /// No description provided for @errorVerifyCurrentPassword.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar la contraseña actual.'**
  String get errorVerifyCurrentPassword;

  /// No description provided for @errorUpdatePassword.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar la contraseña.'**
  String get errorUpdatePassword;

  /// No description provided for @errorCompleteProfile.
  ///
  /// In es, this message translates to:
  /// **'Error al completar el perfil.'**
  String get errorCompleteProfile;

  /// No description provided for @errorNoActiveSession.
  ///
  /// In es, this message translates to:
  /// **'No hay una sesión activa o correo disponible para reautenticar.'**
  String get errorNoActiveSession;

  /// No description provided for @errorSendResetEmail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el correo de recuperación. Intenta nuevamente.'**
  String get errorSendResetEmail;

  /// No description provided for @editProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Perfil'**
  String get editProfileTitle;

  /// No description provided for @profileEmailNotice.
  ///
  /// In es, this message translates to:
  /// **'El correo electrónico no es editable.'**
  String get profileEmailNotice;

  /// No description provided for @editProfileAction.
  ///
  /// In es, this message translates to:
  /// **'Editar Perfil'**
  String get editProfileAction;

  /// No description provided for @saveChangesAction.
  ///
  /// In es, this message translates to:
  /// **'Guardar Cambios'**
  String get saveChangesAction;

  /// No description provided for @changePhotoAction.
  ///
  /// In es, this message translates to:
  /// **'Cambiar Foto'**
  String get changePhotoAction;

  /// No description provided for @uploadingPhoto.
  ///
  /// In es, this message translates to:
  /// **'Subiendo imagen...'**
  String get uploadingPhoto;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado exitosamente.'**
  String get profileUpdateSuccess;

  /// No description provided for @noProfileData.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la información del perfil.'**
  String get noProfileData;

  /// No description provided for @savingProfile.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get savingProfile;

  /// No description provided for @profileDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Información Personal'**
  String get profileDetailsTitle;

  /// No description provided for @profileSectionContact.
  ///
  /// In es, this message translates to:
  /// **'Contacto y Domicilio'**
  String get profileSectionContact;

  /// No description provided for @profileSectionIdentity.
  ///
  /// In es, this message translates to:
  /// **'Identificación'**
  String get profileSectionIdentity;

  /// No description provided for @petsListTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis Mascotas'**
  String get petsListTitle;

  /// No description provided for @addPetAction.
  ///
  /// In es, this message translates to:
  /// **'Registrar Mascota'**
  String get addPetAction;

  /// No description provided for @emptyPetsMessage.
  ///
  /// In es, this message translates to:
  /// **'No tienes mascotas registradas aún.'**
  String get emptyPetsMessage;

  /// No description provided for @petNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la mascota'**
  String get petNameLabel;

  /// No description provided for @petSpeciesLabel.
  ///
  /// In es, this message translates to:
  /// **'Especie'**
  String get petSpeciesLabel;

  /// No description provided for @petBreedLabel.
  ///
  /// In es, this message translates to:
  /// **'Raza'**
  String get petBreedLabel;

  /// No description provided for @petSexLabel.
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get petSexLabel;

  /// No description provided for @petReproductiveStatusLabel.
  ///
  /// In es, this message translates to:
  /// **'Estado reproductivo'**
  String get petReproductiveStatusLabel;

  /// No description provided for @petBirthDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get petBirthDateLabel;

  /// No description provided for @petAgeLabel.
  ///
  /// In es, this message translates to:
  /// **'Edad aproximada'**
  String get petAgeLabel;

  /// No description provided for @petAgeYears.
  ///
  /// In es, this message translates to:
  /// **'Años'**
  String get petAgeYears;

  /// No description provided for @petAgeMonths.
  ///
  /// In es, this message translates to:
  /// **'Meses'**
  String get petAgeMonths;

  /// No description provided for @petAgeCalculationNotice.
  ///
  /// In es, this message translates to:
  /// **'Puedes indicar la fecha exacta o ingresar los años y meses aproximados.'**
  String get petAgeCalculationNotice;

  /// No description provided for @petAllergiesLabel.
  ///
  /// In es, this message translates to:
  /// **'Alergias o condiciones médicas'**
  String get petAllergiesLabel;

  /// No description provided for @petSexMale.
  ///
  /// In es, this message translates to:
  /// **'Macho'**
  String get petSexMale;

  /// No description provided for @petSexFemale.
  ///
  /// In es, this message translates to:
  /// **'Hembra'**
  String get petSexFemale;

  /// No description provided for @petReproductiveIntact.
  ///
  /// In es, this message translates to:
  /// **'Entero / Intacto'**
  String get petReproductiveIntact;

  /// No description provided for @petReproductiveNeutered.
  ///
  /// In es, this message translates to:
  /// **'Castrado / Esterilizado'**
  String get petReproductiveNeutered;

  /// No description provided for @petReproductiveUnknown.
  ///
  /// In es, this message translates to:
  /// **'Desconocido'**
  String get petReproductiveUnknown;

  /// No description provided for @petSpeciesDog.
  ///
  /// In es, this message translates to:
  /// **'Perro'**
  String get petSpeciesDog;

  /// No description provided for @petSpeciesCat.
  ///
  /// In es, this message translates to:
  /// **'Gato'**
  String get petSpeciesCat;

  /// No description provided for @petSpeciesBird.
  ///
  /// In es, this message translates to:
  /// **'Ave'**
  String get petSpeciesBird;

  /// No description provided for @petSpeciesOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get petSpeciesOther;

  /// No description provided for @petCreateSuccess.
  ///
  /// In es, this message translates to:
  /// **'Mascota registrada exitosamente.'**
  String get petCreateSuccess;

  /// No description provided for @petUpdateSuccess.
  ///
  /// In es, this message translates to:
  /// **'Datos de la mascota actualizados exitosamente.'**
  String get petUpdateSuccess;

  /// No description provided for @petDeactivateAction.
  ///
  /// In es, this message translates to:
  /// **'Dar de baja'**
  String get petDeactivateAction;

  /// No description provided for @petDeactivateTitle.
  ///
  /// In es, this message translates to:
  /// **'Dar de baja mascota'**
  String get petDeactivateTitle;

  /// No description provided for @petDeactivateConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmas la baja definitiva de esta mascota?'**
  String get petDeactivateConfirm;

  /// No description provided for @petDeactivateNotice.
  ///
  /// In es, this message translates to:
  /// **'Esta acción cancelará automáticamente cualquier cita futura programada.'**
  String get petDeactivateNotice;

  /// No description provided for @petDeactivateAffectedAppointments.
  ///
  /// In es, this message translates to:
  /// **'Citas activas que serán canceladas:'**
  String get petDeactivateAffectedAppointments;

  /// No description provided for @petDeactivateNoAppointments.
  ///
  /// In es, this message translates to:
  /// **'No tiene citas pendientes ni confirmadas programadas.'**
  String get petDeactivateNoAppointments;

  /// No description provided for @petDeactivateSuccess.
  ///
  /// In es, this message translates to:
  /// **'Mascota dada de baja exitosamente.'**
  String get petDeactivateSuccess;

  /// No description provided for @petStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get petStatusActive;

  /// No description provided for @petStatusDeactivated.
  ///
  /// In es, this message translates to:
  /// **'Dada de baja'**
  String get petStatusDeactivated;

  /// No description provided for @petDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Ficha de la Mascota'**
  String get petDetailTitle;

  /// No description provided for @petEditAction.
  ///
  /// In es, this message translates to:
  /// **'Editar Datos'**
  String get petEditAction;

  /// No description provided for @petPhotoAction.
  ///
  /// In es, this message translates to:
  /// **'Cambiar Foto'**
  String get petPhotoAction;

  /// No description provided for @savingPet.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get savingPet;

  /// No description provided for @loadingPets.
  ///
  /// In es, this message translates to:
  /// **'Cargando mascotas...'**
  String get loadingPets;

  /// No description provided for @petLoadingPreview.
  ///
  /// In es, this message translates to:
  /// **'Verificando citas programadas...'**
  String get petLoadingPreview;

  /// No description provided for @dateFormatHint.
  ///
  /// In es, this message translates to:
  /// **'AAAA-MM-DD'**
  String get dateFormatHint;

  /// Resumen de servicio y fecha
  ///
  /// In es, this message translates to:
  /// **'{service} - {date}'**
  String appointmentItemSummary(String service, String date);

  /// No description provided for @adminServicesTitle.
  ///
  /// In es, this message translates to:
  /// **'Catálogo de Servicios'**
  String get adminServicesTitle;

  /// No description provided for @addServiceAction.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Servicio'**
  String get addServiceAction;

  /// No description provided for @editServiceAction.
  ///
  /// In es, this message translates to:
  /// **'Editar Servicio'**
  String get editServiceAction;

  /// No description provided for @serviceNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del servicio'**
  String get serviceNameLabel;

  /// No description provided for @serviceDescriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get serviceDescriptionLabel;

  /// No description provided for @serviceBasePriceLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio Base (USD)'**
  String get serviceBasePriceLabel;

  /// No description provided for @serviceFinalPriceLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio Final con Impuestos'**
  String get serviceFinalPriceLabel;

  /// No description provided for @serviceIceLabel.
  ///
  /// In es, this message translates to:
  /// **'ICE (Puntos Básicos)'**
  String get serviceIceLabel;

  /// No description provided for @serviceDurationLabel.
  ///
  /// In es, this message translates to:
  /// **'Duración Estimada (minutos)'**
  String get serviceDurationLabel;

  /// No description provided for @serviceIsClinicalLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Es Servicio Clínico?'**
  String get serviceIsClinicalLabel;

  /// No description provided for @serviceIsActiveLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Servicio Activo?'**
  String get serviceIsActiveLabel;

  /// No description provided for @serviceActivateAction.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get serviceActivateAction;

  /// No description provided for @serviceDeactivateAction.
  ///
  /// In es, this message translates to:
  /// **'Desactivar'**
  String get serviceDeactivateAction;

  /// No description provided for @serviceSaveSuccess.
  ///
  /// In es, this message translates to:
  /// **'Servicio guardado exitosamente.'**
  String get serviceSaveSuccess;

  /// No description provided for @serviceStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get serviceStatusActive;

  /// No description provided for @serviceStatusInactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get serviceStatusInactive;

  /// No description provided for @serviceClinicalBadge.
  ///
  /// In es, this message translates to:
  /// **'Clínico'**
  String get serviceClinicalBadge;

  /// No description provided for @serviceGeneralBadge.
  ///
  /// In es, this message translates to:
  /// **'General'**
  String get serviceGeneralBadge;

  /// Duración en minutos
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String serviceDurationSummary(int minutes);

  /// Resumen de precio base y final
  ///
  /// In es, this message translates to:
  /// **'Base: \${base} · Final: \${finalPrice}'**
  String servicePriceSummary(String base, String finalPrice);

  /// No description provided for @emptyServicesMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay servicios registrados en el catálogo.'**
  String get emptyServicesMessage;

  /// No description provided for @servicesLoadErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el catálogo de servicios.'**
  String get servicesLoadErrorMessage;

  /// No description provided for @loadingServices.
  ///
  /// In es, this message translates to:
  /// **'Cargando servicios...'**
  String get loadingServices;

  /// No description provided for @savingService.
  ///
  /// In es, this message translates to:
  /// **'Guardando servicio...'**
  String get savingService;

  /// No description provided for @serviceConfirmDeactivate.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de desactivar este servicio del catálogo?'**
  String get serviceConfirmDeactivate;

  /// No description provided for @serviceConfirmActivate.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de activar este servicio en el catálogo?'**
  String get serviceConfirmActivate;

  /// No description provided for @bookingTitle.
  ///
  /// In es, this message translates to:
  /// **'Agendamiento de Cita'**
  String get bookingTitle;

  /// No description provided for @bookingStepService.
  ///
  /// In es, this message translates to:
  /// **'1. Servicio'**
  String get bookingStepService;

  /// No description provided for @bookingStepPet.
  ///
  /// In es, this message translates to:
  /// **'2. Mascota'**
  String get bookingStepPet;

  /// No description provided for @bookingStepDateTime.
  ///
  /// In es, this message translates to:
  /// **'3. Fecha y Horario'**
  String get bookingStepDateTime;

  /// No description provided for @bookingStepConfirm.
  ///
  /// In es, this message translates to:
  /// **'4. Confirmación'**
  String get bookingStepConfirm;

  /// No description provided for @selectServiceTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un Servicio'**
  String get selectServiceTitle;

  /// No description provided for @selectPetTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu Mascota'**
  String get selectPetTitle;

  /// No description provided for @selectDateTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona Fecha y Horario'**
  String get selectDateTimeTitle;

  /// No description provided for @confirmBookingTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Agendamiento'**
  String get confirmBookingTitle;

  /// No description provided for @clientNotesLabel.
  ///
  /// In es, this message translates to:
  /// **'Notas o síntomas (opcional, máx. 250 caracteres)'**
  String get clientNotesLabel;

  /// No description provided for @confirmBookingAction.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Cita'**
  String get confirmBookingAction;

  /// No description provided for @bookingSuccessMessage.
  ///
  /// In es, this message translates to:
  /// **'¡Cita agendada exitosamente!'**
  String get bookingSuccessMessage;

  /// No description provided for @noAvailableSlotsMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay franjas horarias disponibles para la fecha seleccionada.'**
  String get noAvailableSlotsMessage;

  /// No description provided for @noOperatingDayMessage.
  ///
  /// In es, this message translates to:
  /// **'Día no laborable según el horario de atención.'**
  String get noOperatingDayMessage;

  /// No description provided for @slotTakenNotice.
  ///
  /// In es, this message translates to:
  /// **'La franja seleccionada ya no está disponible. Por favor, selecciona otra.'**
  String get slotTakenNotice;

  /// No description provided for @noActivePetsMessage.
  ///
  /// In es, this message translates to:
  /// **'No tienes mascotas activas disponibles para agendar.'**
  String get noActivePetsMessage;

  /// No description provided for @bookingPriceEstimatedNotice.
  ///
  /// In es, this message translates to:
  /// **'El precio mostrado es informativo; el valor definitivo será registrado al confirmar la cita.'**
  String get bookingPriceEstimatedNotice;

  /// Precio base en resumen
  ///
  /// In es, this message translates to:
  /// **'Precio base: \${amount}'**
  String bookingBasePriceSummary(String amount);

  /// Impuestos estimados en resumen
  ///
  /// In es, this message translates to:
  /// **'Impuestos estimados: \${amount}'**
  String bookingEstimatedTaxesSummary(String amount);

  /// Total estimado en resumen
  ///
  /// In es, this message translates to:
  /// **'Total estimado a pagar: \${amount}'**
  String bookingTotalEstimatedSummary(String amount);

  /// No description provided for @offlineWarning.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión a internet. No se puede realizar el agendamiento.'**
  String get offlineWarning;

  /// Contador de caracteres de notas
  ///
  /// In es, this message translates to:
  /// **'{current} / 250'**
  String notesCharCount(int current);

  /// No description provided for @selectAction.
  ///
  /// In es, this message translates to:
  /// **'Elegir'**
  String get selectAction;

  /// No description provided for @selectedBadge.
  ///
  /// In es, this message translates to:
  /// **'Seleccionado'**
  String get selectedBadge;

  /// No description provided for @selectDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar fecha'**
  String get selectDateLabel;

  /// No description provided for @availableSlotsTitle.
  ///
  /// In es, this message translates to:
  /// **'Horarios Disponibles'**
  String get availableSlotsTitle;

  /// No description provided for @noSlotsAvailableNotice.
  ///
  /// In es, this message translates to:
  /// **'No hay horarios disponibles para este día.'**
  String get noSlotsAvailableNotice;

  /// No description provided for @serviceSummaryLabel.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get serviceSummaryLabel;

  /// No description provided for @petSummaryLabel.
  ///
  /// In es, this message translates to:
  /// **'Mascota'**
  String get petSummaryLabel;

  /// No description provided for @dateTimeSummaryLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha y Horario'**
  String get dateTimeSummaryLabel;

  /// No description provided for @notesSummaryLabel.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get notesSummaryLabel;

  /// No description provided for @confirmBookingNotice.
  ///
  /// In es, this message translates to:
  /// **'Al confirmar, la reserva se registrará de forma definitiva.'**
  String get confirmBookingNotice;

  /// No description provided for @appointmentCodeLabel.
  ///
  /// In es, this message translates to:
  /// **'Código de cita'**
  String get appointmentCodeLabel;

  /// No description provided for @backToHomeAction.
  ///
  /// In es, this message translates to:
  /// **'Volver al Inicio'**
  String get backToHomeAction;

  /// No description provided for @nextStepAction.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get nextStepAction;

  /// No description provided for @previousStepAction.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get previousStepAction;

  /// No description provided for @stepServiceTitle.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get stepServiceTitle;

  /// No description provided for @stepPetTitle.
  ///
  /// In es, this message translates to:
  /// **'Mascota'**
  String get stepPetTitle;

  /// No description provided for @stepDateTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Fecha y Hora'**
  String get stepDateTimeTitle;

  /// No description provided for @stepConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get stepConfirmTitle;

  /// No description provided for @appointmentsHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial de Citas'**
  String get appointmentsHistoryTitle;

  /// No description provided for @upcomingAppointmentsTab.
  ///
  /// In es, this message translates to:
  /// **'Próximas'**
  String get upcomingAppointmentsTab;

  /// No description provided for @pastAppointmentsTab.
  ///
  /// In es, this message translates to:
  /// **'Pasadas'**
  String get pastAppointmentsTab;

  /// No description provided for @upcomingAppointmentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Citas Próximas'**
  String get upcomingAppointmentsTitle;

  /// No description provided for @pastAppointmentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Citas Pasadas'**
  String get pastAppointmentsTitle;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In es, this message translates to:
  /// **'No tienes citas próximas programadas.'**
  String get noUpcomingAppointments;

  /// No description provided for @noPastAppointments.
  ///
  /// In es, this message translates to:
  /// **'No tienes citas en tu historial.'**
  String get noPastAppointments;

  /// No description provided for @noAppointmentsFound.
  ///
  /// In es, this message translates to:
  /// **'No tienes citas registradas.'**
  String get noAppointmentsFound;

  /// No description provided for @appointmentStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get appointmentStatusPending;

  /// No description provided for @appointmentStatusConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get appointmentStatusConfirmed;

  /// No description provided for @appointmentStatusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get appointmentStatusCompleted;

  /// No description provided for @appointmentStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get appointmentStatusCancelled;

  /// No description provided for @appointmentDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get appointmentDateLabel;

  /// No description provided for @appointmentTimeLabel.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get appointmentTimeLabel;

  /// No description provided for @appointmentPetLabel.
  ///
  /// In es, this message translates to:
  /// **'Mascota'**
  String get appointmentPetLabel;

  /// No description provided for @appointmentServiceLabel.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get appointmentServiceLabel;

  /// No description provided for @appointmentStatusLabel.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get appointmentStatusLabel;

  /// Precio base en historial de citas
  ///
  /// In es, this message translates to:
  /// **'Precio base: \${amount}'**
  String appointmentBasePrice(String amount);

  /// Precio final con impuestos en historial de citas
  ///
  /// In es, this message translates to:
  /// **'Precio final con impuestos: \${amount}'**
  String appointmentFinalPriceWithTaxes(String amount);

  /// No description provided for @cancelAppointmentAction.
  ///
  /// In es, this message translates to:
  /// **'Cancelar Cita'**
  String get cancelAppointmentAction;

  /// No description provided for @cancelAppointmentDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas cancelar esta cita?'**
  String get cancelAppointmentDialogTitle;

  /// No description provided for @cancelAppointmentDialogMessage.
  ///
  /// In es, this message translates to:
  /// **'Esta acción liberará el horario reservado y cancelará la cita de forma definitiva. No podrás deshacer esta acción.'**
  String get cancelAppointmentDialogMessage;

  /// No description provided for @confirmCancelAction.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Cancelación'**
  String get confirmCancelAction;

  /// No description provided for @keepAppointmentAction.
  ///
  /// In es, this message translates to:
  /// **'Mantener Cita'**
  String get keepAppointmentAction;

  /// No description provided for @appointmentCancelledSuccess.
  ///
  /// In es, this message translates to:
  /// **'La cita ha sido cancelada exitosamente.'**
  String get appointmentCancelledSuccess;

  /// No description provided for @cancellingAppointment.
  ///
  /// In es, this message translates to:
  /// **'Cancelando...'**
  String get cancellingAppointment;

  /// No description provided for @loadMoreAppointmentsAction.
  ///
  /// In es, this message translates to:
  /// **'Cargar más citas'**
  String get loadMoreAppointmentsAction;

  /// No description provided for @catalogTitle.
  ///
  /// In es, this message translates to:
  /// **'Catálogo de Productos'**
  String get catalogTitle;

  /// No description provided for @searchProductHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar producto...'**
  String get searchProductHint;

  /// No description provided for @categoryAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get categoryAll;

  /// No description provided for @categoryFood.
  ///
  /// In es, this message translates to:
  /// **'Alimentos'**
  String get categoryFood;

  /// No description provided for @categoryMedicine.
  ///
  /// In es, this message translates to:
  /// **'Medicinas'**
  String get categoryMedicine;

  /// No description provided for @categoryAccessories.
  ///
  /// In es, this message translates to:
  /// **'Accesorios'**
  String get categoryAccessories;

  /// No description provided for @categoryHygiene.
  ///
  /// In es, this message translates to:
  /// **'Higiene'**
  String get categoryHygiene;

  /// No description provided for @stockAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get stockAvailable;

  /// No description provided for @stockOutOfStock.
  ///
  /// In es, this message translates to:
  /// **'Agotado'**
  String get stockOutOfStock;

  /// Precio base formateado
  ///
  /// In es, this message translates to:
  /// **'Base: \${amount}'**
  String priceBaseFormatted(String amount);

  /// Precio con impuestos formateado
  ///
  /// In es, this message translates to:
  /// **'Con impuestos: \${amount}'**
  String priceWithTaxesFormatted(String amount);

  /// Desglose de impuesto ICE
  ///
  /// In es, this message translates to:
  /// **'ICE ({percent}%): \${amount}'**
  String taxIceFormatted(String percent, String amount);

  /// Desglose de impuesto IVA
  ///
  /// In es, this message translates to:
  /// **'IVA ({percent}%): \${amount}'**
  String taxIvaFormatted(String percent, String amount);

  /// No description provided for @taxIceOnlyLabel.
  ///
  /// In es, this message translates to:
  /// **'ICE aplicable'**
  String get taxIceOnlyLabel;

  /// No description provided for @taxIvaOnlyLabel.
  ///
  /// In es, this message translates to:
  /// **'IVA aplicable'**
  String get taxIvaOnlyLabel;

  /// No description provided for @taxBreakdownTitle.
  ///
  /// In es, this message translates to:
  /// **'Desglose de Precios'**
  String get taxBreakdownTitle;

  /// No description provided for @productDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle del Producto'**
  String get productDetailTitle;

  /// No description provided for @requestProductAction.
  ///
  /// In es, this message translates to:
  /// **'Solicitar Producto'**
  String get requestProductAction;

  /// No description provided for @requestProductSuccess.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada exitosamente.'**
  String get requestProductSuccess;

  /// No description provided for @requestingProduct.
  ///
  /// In es, this message translates to:
  /// **'Enviando solicitud...'**
  String get requestingProduct;

  /// No description provided for @myRequestsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis Solicitudes'**
  String get myRequestsTitle;

  /// No description provided for @chatScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'Chat con la Veterinaria'**
  String get chatScreenTitle;

  /// No description provided for @chatPurgeAction.
  ///
  /// In es, this message translates to:
  /// **'Vaciar conversación'**
  String get chatPurgeAction;

  /// No description provided for @chatPurgeTitle.
  ///
  /// In es, this message translates to:
  /// **'Vaciar conversación'**
  String get chatPurgeTitle;

  /// No description provided for @chatPurgeBody.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar todos los mensajes? El historial desaparecerá también para el personal.'**
  String get chatPurgeBody;

  /// No description provided for @chatPurgeConfirm.
  ///
  /// In es, this message translates to:
  /// **'Vaciar'**
  String get chatPurgeConfirm;

  /// No description provided for @chatDeleteMessageTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mensaje'**
  String get chatDeleteMessageTitle;

  /// No description provided for @chatDeleteMessageBody.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas eliminar este mensaje? Desaparecerá de la conversación sin dejar registro sustitutorio.'**
  String get chatDeleteMessageBody;

  /// No description provided for @chatDeleteMessageConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get chatDeleteMessageConfirm;

  /// No description provided for @chatDeleteOwnMessageSemantics.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mensaje propio'**
  String get chatDeleteOwnMessageSemantics;

  /// No description provided for @chatBlockedNotice.
  ///
  /// In es, this message translates to:
  /// **'Un administrador ha bloqueado tu envío de mensajes en esta conversación. Puedes seguir leyendo lo que ya escribiste y lo que el personal te escriba.'**
  String get chatBlockedNotice;

  /// No description provided for @chatBlockedHint.
  ///
  /// In es, this message translates to:
  /// **'No puedes escribir en esta conversación'**
  String get chatBlockedHint;

  /// No description provided for @chatMessagePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get chatMessagePlaceholder;

  /// No description provided for @chatEmptyConversation.
  ///
  /// In es, this message translates to:
  /// **'No hay mensajes aún. Escribe para comunicarte con el personal.'**
  String get chatEmptyConversation;

  /// No description provided for @chatAttachImageAction.
  ///
  /// In es, this message translates to:
  /// **'Adjuntar imagen'**
  String get chatAttachImageAction;

  /// No description provided for @chatSendMessageAction.
  ///
  /// In es, this message translates to:
  /// **'Enviar mensaje'**
  String get chatSendMessageAction;

  /// No description provided for @errorChatBlocked.
  ///
  /// In es, this message translates to:
  /// **'No puedes enviar mensajes en esta conversación porque un administrador lo ha bloqueado.'**
  String get errorChatBlocked;

  /// No description provided for @errorChatMessageEmpty.
  ///
  /// In es, this message translates to:
  /// **'El mensaje no puede estar vacío.'**
  String get errorChatMessageEmpty;

  /// No description provided for @errorChatMessageTooLong.
  ///
  /// In es, this message translates to:
  /// **'El mensaje no puede exceder los 4000 caracteres.'**
  String get errorChatMessageTooLong;

  /// No description provided for @chatImageAttachmentLabel.
  ///
  /// In es, this message translates to:
  /// **'Imagen adjunta'**
  String get chatImageAttachmentLabel;

  /// No description provided for @chatImageLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la imagen adjunta.'**
  String get chatImageLoadError;

  /// No description provided for @chatImageOpenAction.
  ///
  /// In es, this message translates to:
  /// **'Ver la imagen a tamaño completo'**
  String get chatImageOpenAction;

  /// Nombre del cliente que generó la solicitud de producto
  ///
  /// In es, this message translates to:
  /// **'Cliente: {name}'**
  String requestClientLabel(String name);

  /// No description provided for @emptyCatalogMessage.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron productos disponibles.'**
  String get emptyCatalogMessage;

  /// No description provided for @emptyRequestsMessage.
  ///
  /// In es, this message translates to:
  /// **'No tienes solicitudes de productos registradas.'**
  String get emptyRequestsMessage;

  /// No description provided for @requestStatusPendingDispatch.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de despacho'**
  String get requestStatusPendingDispatch;

  /// No description provided for @requestStatusReadyForPickup.
  ///
  /// In es, this message translates to:
  /// **'Listo para retiro'**
  String get requestStatusReadyForPickup;

  /// No description provided for @requestStatusFinalized.
  ///
  /// In es, this message translates to:
  /// **'Finalizada'**
  String get requestStatusFinalized;

  /// No description provided for @requestStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get requestStatusCancelled;

  /// No description provided for @cancelRequestAction.
  ///
  /// In es, this message translates to:
  /// **'Cancelar Solicitud'**
  String get cancelRequestAction;

  /// No description provided for @cancelRequestTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelar Solicitud'**
  String get cancelRequestTitle;

  /// No description provided for @cancelRequestConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmas la cancelación de esta solicitud de producto?'**
  String get cancelRequestConfirm;

  /// No description provided for @cancelRequestNotice.
  ///
  /// In es, this message translates to:
  /// **'El producto volverá a estar disponible en el catálogo.'**
  String get cancelRequestNotice;

  /// No description provided for @cancelRequestSuccess.
  ///
  /// In es, this message translates to:
  /// **'Solicitud cancelada exitosamente.'**
  String get cancelRequestSuccess;

  /// No description provided for @cancelRequestItemsHeader.
  ///
  /// In es, this message translates to:
  /// **'Productos que se cancelarán:'**
  String get cancelRequestItemsHeader;

  /// No description provided for @requestItemsHeader.
  ///
  /// In es, this message translates to:
  /// **'Productos solicitados'**
  String get requestItemsHeader;

  /// No description provided for @requestTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Total de la solicitud'**
  String get requestTotalLabel;

  /// No description provided for @cancellingRequest.
  ///
  /// In es, this message translates to:
  /// **'Cancelando...'**
  String get cancellingRequest;

  /// No description provided for @tabCatalog.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get tabCatalog;

  /// No description provided for @tabMyRequests.
  ///
  /// In es, this message translates to:
  /// **'Mis Solicitudes'**
  String get tabMyRequests;

  /// No description provided for @viewDetailsAction.
  ///
  /// In es, this message translates to:
  /// **'Ver Detalle'**
  String get viewDetailsAction;

  /// No description provided for @productCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get productCategoryLabel;

  /// No description provided for @productDescriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get productDescriptionLabel;

  /// Cantidad de unidades
  ///
  /// In es, this message translates to:
  /// **'Cantidad: {quantity}'**
  String quantityLabel(int quantity);

  /// No description provided for @paymentSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen a Pagar'**
  String get paymentSummaryTitle;

  /// No description provided for @paymentSummaryNotice.
  ///
  /// In es, this message translates to:
  /// **'Los descuentos y recargos finales se aplican y reflejan en la proforma emitida por el establecimiento.'**
  String get paymentSummaryNotice;

  /// No description provided for @paymentSummaryEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes citas completadas ni solicitudes pendientes de facturación.'**
  String get paymentSummaryEmpty;

  /// Subtotal del resumen a pagar
  ///
  /// In es, this message translates to:
  /// **'Subtotal: \${amount}'**
  String paymentSummarySubtotal(String amount);

  /// Total ICE del resumen a pagar
  ///
  /// In es, this message translates to:
  /// **'Total ICE: \${amount}'**
  String paymentSummaryTotalIce(String amount);

  /// Total IVA del resumen a pagar
  ///
  /// In es, this message translates to:
  /// **'Total IVA ({percent}%): \${amount}'**
  String paymentSummaryTotalIva(String percent, String amount);

  /// Total estimado del resumen a pagar
  ///
  /// In es, this message translates to:
  /// **'Total Estimado: \${amount}'**
  String paymentSummaryEstimatedTotal(String amount);

  /// Boton para abrir el resumen a pagar de la zona de facturacion
  ///
  /// In es, this message translates to:
  /// **'Resumen a pagar'**
  String get paymentSummaryOpenAction;

  /// Etiqueta de IVA con porcentaje para el resumen a pagar
  ///
  /// In es, this message translates to:
  /// **'IVA ({rate}%):'**
  String paymentSummaryIvaRateLabel(String rate);

  /// Etiqueta de total estimado para el resumen a pagar
  ///
  /// In es, this message translates to:
  /// **'Total estimado'**
  String get paymentSummaryEstimatedTotalLabel;

  /// No description provided for @cartTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi Carrito'**
  String get cartTitle;

  /// No description provided for @cartEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'No tienes solicitudes activas ni citas pendientes de pago.'**
  String get cartEmptyMessage;

  /// No description provided for @cartNoticeAdjustments.
  ///
  /// In es, this message translates to:
  /// **'Los descuentos y recargos finales se aplican y reflejan en la proforma emitida por el establecimiento.'**
  String get cartNoticeAdjustments;

  /// No description provided for @cartPayableTodayLabel.
  ///
  /// In es, this message translates to:
  /// **'A pagar hoy'**
  String get cartPayableTodayLabel;

  /// Total a pagar hoy en el carrito
  ///
  /// In es, this message translates to:
  /// **'A pagar hoy: \${amount}'**
  String cartPayableToday(String amount);

  /// No description provided for @cartAccumulatedTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Total acumulado'**
  String get cartAccumulatedTotalLabel;

  /// Total acumulado en el carrito
  ///
  /// In es, this message translates to:
  /// **'Total acumulado: \${amount}'**
  String cartAccumulatedTotal(String amount);

  /// No description provided for @cartProductsSection.
  ///
  /// In es, this message translates to:
  /// **'Productos Solicitados'**
  String get cartProductsSection;

  /// No description provided for @cartAppointmentsSection.
  ///
  /// In es, this message translates to:
  /// **'Citas Agendadas'**
  String get cartAppointmentsSection;

  /// Cabecera de grupo de solicitud
  ///
  /// In es, this message translates to:
  /// **'Solicitud #{id}'**
  String cartRequestGroupHeader(String id);

  /// Cantidad del producto
  ///
  /// In es, this message translates to:
  /// **'Cantidad: {quantity}'**
  String cartQuantity(int quantity);

  /// Precio unitario
  ///
  /// In es, this message translates to:
  /// **'Precio unitario: \${amount}'**
  String cartUnitPrice(String amount);

  /// Precio con impuestos
  ///
  /// In es, this message translates to:
  /// **'Precio con impuestos: \${amount}'**
  String cartPriceWithTaxes(String amount);

  /// Subtotal de linea
  ///
  /// In es, this message translates to:
  /// **'Subtotal: \${amount}'**
  String cartSubtotal(String amount);

  /// Fecha y horario de cita en carrito
  ///
  /// In es, this message translates to:
  /// **'Fecha: {date} - Horario: {slot}'**
  String cartAppointmentDateTime(String date, String slot);

  /// Mascota de la cita en carrito
  ///
  /// In es, this message translates to:
  /// **'Mascota: {pet}'**
  String cartAppointmentPet(String pet);

  /// Servicio de la cita en carrito
  ///
  /// In es, this message translates to:
  /// **'Servicio: {service}'**
  String cartAppointmentService(String service);

  /// Precio con impuestos de la cita en carrito
  ///
  /// In es, this message translates to:
  /// **'Precio con impuestos: \${amount}'**
  String cartAppointmentPrice(String amount);

  /// No description provided for @navCart.
  ///
  /// In es, this message translates to:
  /// **'Carrito'**
  String get navCart;

  /// No description provided for @myProformasTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis Proformas'**
  String get myProformasTitle;

  /// No description provided for @emptyProformasMessage.
  ///
  /// In es, this message translates to:
  /// **'No tienes proformas emitidas aún.'**
  String get emptyProformasMessage;

  /// Número formal de proforma
  ///
  /// In es, this message translates to:
  /// **'Proforma: {number}'**
  String proformaNumberLabel(String number);

  /// No description provided for @proformaDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de emisión'**
  String get proformaDateLabel;

  /// No description provided for @proformaStatusDelivered.
  ///
  /// In es, this message translates to:
  /// **'Entregada'**
  String get proformaStatusDelivered;

  /// No description provided for @proformaStatusFinalized.
  ///
  /// In es, this message translates to:
  /// **'Finalizada'**
  String get proformaStatusFinalized;

  /// No description provided for @proformaStatusVoided.
  ///
  /// In es, this message translates to:
  /// **'Anulada'**
  String get proformaStatusVoided;

  /// No description provided for @proformaStatusDraft.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get proformaStatusDraft;

  /// Motivo de anulación
  ///
  /// In es, this message translates to:
  /// **'Motivo de anulación: {reason}'**
  String proformaVoidReasonLabel(String reason);

  /// No description provided for @downloadPdfAction.
  ///
  /// In es, this message translates to:
  /// **'Descargar PDF'**
  String get downloadPdfAction;

  /// No description provided for @downloadingPdf.
  ///
  /// In es, this message translates to:
  /// **'Descargando PDF...'**
  String get downloadingPdf;

  /// No description provided for @pdfDownloadSuccess.
  ///
  /// In es, this message translates to:
  /// **'PDF descargado correctamente.'**
  String get pdfDownloadSuccess;

  /// No description provided for @pdfDownloadError.
  ///
  /// In es, this message translates to:
  /// **'Error al descargar el archivo PDF.'**
  String get pdfDownloadError;

  /// No description provided for @tabPaymentSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen a Pagar'**
  String get tabPaymentSummary;

  /// No description provided for @tabMyProformas.
  ///
  /// In es, this message translates to:
  /// **'Mis Proformas'**
  String get tabMyProformas;

  /// No description provided for @proformaDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de Proforma'**
  String get proformaDetailTitle;

  /// No description provided for @proformaDetailWithId.
  ///
  /// In es, this message translates to:
  /// **'Detalle de Proforma: {id}'**
  String proformaDetailWithId(String id);

  /// No description provided for @proformaItemsTitle.
  ///
  /// In es, this message translates to:
  /// **'Conceptos Facturados'**
  String get proformaItemsTitle;

  /// No description provided for @proformaAdjustmentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Descuentos y Recargos'**
  String get proformaAdjustmentsTitle;

  /// No description provided for @proformaAdjustmentDiscount.
  ///
  /// In es, this message translates to:
  /// **'Descuento'**
  String get proformaAdjustmentDiscount;

  /// No description provided for @proformaAdjustmentSurcharge.
  ///
  /// In es, this message translates to:
  /// **'Recargo'**
  String get proformaAdjustmentSurcharge;

  /// Un importe con el símbolo de moneda. El símbolo vive aquí y en ningún otro sitio (TRD v1.25 §1.3.5, AUD-312)
  ///
  /// In es, this message translates to:
  /// **'\${amount}'**
  String moneyAmount(String amount);

  /// Un importe que resta, como un descuento. Lleva el mismo símbolo que moneyAmount
  ///
  /// In es, this message translates to:
  /// **'-\${amount}'**
  String moneyAmountNegative(String amount);

  /// Un importe que suma, como un recargo. Lleva el mismo símbolo que moneyAmount
  ///
  /// In es, this message translates to:
  /// **'+\${amount}'**
  String moneyAmountPositive(String amount);

  /// No description provided for @proformaSubtotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Subtotal'**
  String get proformaSubtotalLabel;

  /// No description provided for @proformaDiscountLabel.
  ///
  /// In es, this message translates to:
  /// **'Descuentos'**
  String get proformaDiscountLabel;

  /// No description provided for @proformaSurchargeLabel.
  ///
  /// In es, this message translates to:
  /// **'Recargos'**
  String get proformaSurchargeLabel;

  /// No description provided for @proformaTaxableBaseLabel.
  ///
  /// In es, this message translates to:
  /// **'Base Imponible'**
  String get proformaTaxableBaseLabel;

  /// No description provided for @proformaIceLabel.
  ///
  /// In es, this message translates to:
  /// **'ICE'**
  String get proformaIceLabel;

  /// No description provided for @proformaIvaLabel.
  ///
  /// In es, this message translates to:
  /// **'IVA'**
  String get proformaIvaLabel;

  /// No description provided for @proformaTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get proformaTotalLabel;

  /// No description provided for @accountDeactivationTitle.
  ///
  /// In es, this message translates to:
  /// **'Desactivación de Cuenta'**
  String get accountDeactivationTitle;

  /// No description provided for @accountDeactivationSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de baja voluntaria de cuenta'**
  String get accountDeactivationSubtitle;

  /// No description provided for @accountDeactivationNotice.
  ///
  /// In es, this message translates to:
  /// **'Antes de continuar, revisa los conceptos que serán cancelados y los que se conservarán en el histórico de la veterinaria.'**
  String get accountDeactivationNotice;

  /// No description provided for @deactivationGroupToCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'Conceptos a Cancelar'**
  String get deactivationGroupToCancelTitle;

  /// No description provided for @deactivationGroupToCancelNotice.
  ///
  /// In es, this message translates to:
  /// **'Las siguientes citas activas y solicitudes no facturadas serán canceladas de forma definitiva. Estos conceptos no se restaurarán si la cuenta se reactiva en el futuro.'**
  String get deactivationGroupToCancelNotice;

  /// No description provided for @deactivationGroupToCancelEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes citas ni solicitudes activas por cancelar.'**
  String get deactivationGroupToCancelEmpty;

  /// No description provided for @deactivationGroupToRetainTitle.
  ///
  /// In es, this message translates to:
  /// **'Registros a Conservar'**
  String get deactivationGroupToRetainTitle;

  /// No description provided for @deactivationGroupToRetainNotice.
  ///
  /// In es, this message translates to:
  /// **'Las siguientes citas completadas y solicitudes facturadas permanecerán archivadas por motivos fiscales y contables.'**
  String get deactivationGroupToRetainNotice;

  /// No description provided for @deactivationGroupToRetainEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes registros históricos facturados.'**
  String get deactivationGroupToRetainEmpty;

  /// No description provided for @deactivationReasonCompleted.
  ///
  /// In es, this message translates to:
  /// **'Cita completada'**
  String get deactivationReasonCompleted;

  /// No description provided for @deactivationReasonBilled.
  ///
  /// In es, this message translates to:
  /// **'Facturado en proforma'**
  String get deactivationReasonBilled;

  /// No description provided for @deactivationUnknownProduct.
  ///
  /// In es, this message translates to:
  /// **'Producto no especificado'**
  String get deactivationUnknownProduct;

  /// No description provided for @deactivationPasswordPrompt.
  ///
  /// In es, this message translates to:
  /// **'Por motivos de seguridad, ingresa tu contraseña actual para confirmar la baja:'**
  String get deactivationPasswordPrompt;

  /// No description provided for @confirmDeactivationAction.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Desactivación de Cuenta'**
  String get confirmDeactivationAction;

  /// No description provided for @deactivatingAccount.
  ///
  /// In es, this message translates to:
  /// **'Procesando baja de cuenta...'**
  String get deactivatingAccount;

  /// No description provided for @accountDeactivatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta ha sido desactivada exitosamente.'**
  String get accountDeactivatedSuccess;

  /// No description provided for @adminProductsTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión de Productos'**
  String get adminProductsTitle;

  /// No description provided for @addProductAction.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Producto'**
  String get addProductAction;

  /// No description provided for @editProductAction.
  ///
  /// In es, this message translates to:
  /// **'Editar Producto'**
  String get editProductAction;

  /// No description provided for @productNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del producto'**
  String get productNameLabel;

  /// No description provided for @productCategoryPrompt.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una categoría'**
  String get productCategoryPrompt;

  /// No description provided for @productInitialStockLabel.
  ///
  /// In es, this message translates to:
  /// **'Stock inicial'**
  String get productInitialStockLabel;

  /// No description provided for @lowStockAlert.
  ///
  /// In es, this message translates to:
  /// **'Stock Bajo'**
  String get lowStockAlert;

  /// No description provided for @adjustStockAction.
  ///
  /// In es, this message translates to:
  /// **'Ajustar Stock'**
  String get adjustStockAction;

  /// No description provided for @inventoryAdjustmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajuste de Inventario'**
  String get inventoryAdjustmentTitle;

  /// No description provided for @currentStockLabel.
  ///
  /// In es, this message translates to:
  /// **'Stock actual'**
  String get currentStockLabel;

  /// No description provided for @stockDeltaLabel.
  ///
  /// In es, this message translates to:
  /// **'Ajuste de unidades (positivo o negativo)'**
  String get stockDeltaLabel;

  /// No description provided for @stockDeltaHelp.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un número entero positivo para añadir existencias o negativo para restar.'**
  String get stockDeltaHelp;

  /// Stock resultante tras ajuste
  ///
  /// In es, this message translates to:
  /// **'Stock resultante: {stock}'**
  String resultingStockLabel(int stock);

  /// No description provided for @stockAdjustSuccess.
  ///
  /// In es, this message translates to:
  /// **'Inventario actualizado exitosamente.'**
  String get stockAdjustSuccess;

  /// No description provided for @adjustingStock.
  ///
  /// In es, this message translates to:
  /// **'Ajustando...'**
  String get adjustingStock;

  /// No description provided for @adminRequestsTitle.
  ///
  /// In es, this message translates to:
  /// **'Cola de Despacho de Solicitudes'**
  String get adminRequestsTitle;

  /// Una línea de la solicitud en el panel: producto y cantidad (IN-04, CA-AD-61)
  ///
  /// In es, this message translates to:
  /// **'{product} × {quantity}'**
  String adminRequestLine(String product, int quantity);

  /// Fecha de la solicitud en el panel (IN-04)
  ///
  /// In es, this message translates to:
  /// **'Solicitada el {date}'**
  String adminRequestDate(String date);

  /// Total de la solicitud antes de impuestos; los impuestos se calculan en la proforma (IN-04, FA-09)
  ///
  /// In es, this message translates to:
  /// **'Total de la solicitud, antes de impuestos: \${amount}'**
  String adminRequestTotalBeforeTaxes(String amount);

  /// No description provided for @adminRequestDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de la solicitud'**
  String get adminRequestDetailTitle;

  /// Una línea en el detalle de la solicitud, con el precio acordado para auditoría (CA-AD-14)
  ///
  /// In es, this message translates to:
  /// **'Cantidad: {quantity} · Precio acordado: \${unitPrice} · Subtotal: \${subtotal}'**
  String adminRequestDetailLine(
    int quantity,
    String unitPrice,
    String subtotal,
  );

  /// No description provided for @adminRequestTaxNote.
  ///
  /// In es, this message translates to:
  /// **'Los impuestos se calculan en la proforma, con los porcentajes congelados de cada línea.'**
  String get adminRequestTaxNote;

  /// No description provided for @filterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos los estados'**
  String get filterAll;

  /// No description provided for @advanceToReadyAction.
  ///
  /// In es, this message translates to:
  /// **'Marcar Listo para Retiro'**
  String get advanceToReadyAction;

  /// No description provided for @advancingRequest.
  ///
  /// In es, this message translates to:
  /// **'Actualizando estado...'**
  String get advancingRequest;

  /// No description provided for @requestAdvancedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Solicitud actualizada a lista para retiro.'**
  String get requestAdvancedSuccess;

  /// No description provided for @adminProformasTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión de Proformas'**
  String get adminProformasTitle;

  /// No description provided for @proformaNewAction.
  ///
  /// In es, this message translates to:
  /// **'Nueva Proforma'**
  String get proformaNewAction;

  /// No description provided for @proformaSelectClientTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un cliente'**
  String get proformaSelectClientTitle;

  /// No description provided for @proformaPendingConceptsTitle.
  ///
  /// In es, this message translates to:
  /// **'Conceptos pendientes'**
  String get proformaPendingConceptsTitle;

  /// Subtitulo de la pantalla de conceptos pendientes de facturar
  ///
  /// In es, this message translates to:
  /// **'Citas completadas y solicitudes listas para retirar de {name}'**
  String proformaPendingConceptsSubtitle(String name);

  /// No description provided for @proformaNoPendingConcepts.
  ///
  /// In es, this message translates to:
  /// **'Este cliente no tiene conceptos pendientes de facturar.'**
  String get proformaNoPendingConcepts;

  /// No description provided for @proformaConceptAppointment.
  ///
  /// In es, this message translates to:
  /// **'Cita'**
  String get proformaConceptAppointment;

  /// No description provided for @proformaConceptProduct.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get proformaConceptProduct;

  /// No description provided for @proformaSelectedTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Total seleccionado'**
  String get proformaSelectedTotalLabel;

  /// Accion que crea el borrador con los conceptos marcados
  ///
  /// In es, this message translates to:
  /// **'Crear proforma con {count} concepto(s)'**
  String proformaCreateWithSelection(int count);

  /// Accion que incorpora los conceptos marcados a un borrador existente
  ///
  /// In es, this message translates to:
  /// **'Añadir {count} concepto(s) al borrador'**
  String proformaAddSelectionAction(int count);

  /// No description provided for @proformaAddConceptsAction.
  ///
  /// In es, this message translates to:
  /// **'Añadir conceptos'**
  String get proformaAddConceptsAction;

  /// No description provided for @newProformaAction.
  ///
  /// In es, this message translates to:
  /// **'Nueva Proforma'**
  String get newProformaAction;

  /// No description provided for @composeProformaTitle.
  ///
  /// In es, this message translates to:
  /// **'Composición de Proforma'**
  String get composeProformaTitle;

  /// No description provided for @selectClientPrompt.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un cliente'**
  String get selectClientPrompt;

  /// No description provided for @clientDebtSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Deuda Pendiente del Cliente'**
  String get clientDebtSummaryTitle;

  /// No description provided for @addSelectedItemsAction.
  ///
  /// In es, this message translates to:
  /// **'Agregar al Borrador'**
  String get addSelectedItemsAction;

  /// No description provided for @setAdjustmentsAction.
  ///
  /// In es, this message translates to:
  /// **'Configurar Descuentos / Recargos'**
  String get setAdjustmentsAction;

  /// No description provided for @adjustmentConceptLabel.
  ///
  /// In es, this message translates to:
  /// **'Concepto del ajuste'**
  String get adjustmentConceptLabel;

  /// No description provided for @adjustmentTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de ajuste'**
  String get adjustmentTypeLabel;

  /// No description provided for @adjustmentPercentLabel.
  ///
  /// In es, this message translates to:
  /// **'Porcentaje (%)'**
  String get adjustmentPercentLabel;

  /// No description provided for @adjustmentAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto fijo (USD)'**
  String get adjustmentAmountLabel;

  /// No description provided for @deliverProformaAction.
  ///
  /// In es, this message translates to:
  /// **'Emitir y Entregar'**
  String get deliverProformaAction;

  /// No description provided for @deliveringProforma.
  ///
  /// In es, this message translates to:
  /// **'Generando entrega y PDF...'**
  String get deliveringProforma;

  /// No description provided for @proformaDeliveredSuccess.
  ///
  /// In es, this message translates to:
  /// **'Proforma entregada exitosamente.'**
  String get proformaDeliveredSuccess;

  /// No description provided for @finalizeProformaAction.
  ///
  /// In es, this message translates to:
  /// **'Finalizar Proforma'**
  String get finalizeProformaAction;

  /// No description provided for @finalizingProforma.
  ///
  /// In es, this message translates to:
  /// **'Finalizando...'**
  String get finalizingProforma;

  /// No description provided for @proformaFinalizedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Proforma finalizada exitosamente.'**
  String get proformaFinalizedSuccess;

  /// No description provided for @voidProformaAction.
  ///
  /// In es, this message translates to:
  /// **'Anular Proforma'**
  String get voidProformaAction;

  /// No description provided for @voidProformaDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Anulación de Proforma'**
  String get voidProformaDialogTitle;

  /// No description provided for @voidReasonPrompt.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el motivo obligatorio de anulación (máximo 300 caracteres):'**
  String get voidReasonPrompt;

  /// No description provided for @voidReasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo de anulación'**
  String get voidReasonLabel;

  /// No description provided for @voidingProforma.
  ///
  /// In es, this message translates to:
  /// **'Anulando...'**
  String get voidingProforma;

  /// No description provided for @proformaVoidedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Proforma anulada exitosamente.'**
  String get proformaVoidedSuccess;

  /// No description provided for @adminBillingParametersTitle.
  ///
  /// In es, this message translates to:
  /// **'Parámetros de Facturación'**
  String get adminBillingParametersTitle;

  /// No description provided for @businessNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Razón Social'**
  String get businessNameLabel;

  /// No description provided for @taxIdLabel.
  ///
  /// In es, this message translates to:
  /// **'RUC / Identificación Fiscal'**
  String get taxIdLabel;

  /// No description provided for @proformaSeriesLabel.
  ///
  /// In es, this message translates to:
  /// **'Serie de Proforma'**
  String get proformaSeriesLabel;

  /// No description provided for @ivaBpLabel.
  ///
  /// In es, this message translates to:
  /// **'Porcentaje de IVA (Puntos Básicos)'**
  String get ivaBpLabel;

  /// Equivalencia en porcentaje del valor escrito en puntos basicos
  ///
  /// In es, this message translates to:
  /// **'{percent} % — 1500 puntos básicos equivalen al 15 %'**
  String ivaBpHelper(String percent);

  /// No description provided for @iceIncludedInIvaBaseLabel.
  ///
  /// In es, this message translates to:
  /// **'Incluir ICE en la base imponible del IVA'**
  String get iceIncludedInIvaBaseLabel;

  /// No description provided for @ivaNoticeFutureOnly.
  ///
  /// In es, this message translates to:
  /// **'Los cambios en el porcentaje de IVA se aplicarán exclusivamente a las futuras proformas emitidas.'**
  String get ivaNoticeFutureOnly;

  /// No description provided for @saveBillingParamsSuccess.
  ///
  /// In es, this message translates to:
  /// **'Parámetros de facturación guardados exitosamente.'**
  String get saveBillingParamsSuccess;

  /// No description provided for @productBasePriceLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio Base (USD)'**
  String get productBasePriceLabel;

  /// No description provided for @productIceBpLabel.
  ///
  /// In es, this message translates to:
  /// **'ICE (Puntos Básicos)'**
  String get productIceBpLabel;

  /// No description provided for @productStockLockedNotice.
  ///
  /// In es, this message translates to:
  /// **'El stock solo puede definirse al crear el producto. Para modificar existencias utilice Ajuste de Inventario.'**
  String get productStockLockedNotice;

  /// No description provided for @proformaEmptyError.
  ///
  /// In es, this message translates to:
  /// **'No se puede entregar una proforma sin ítems.'**
  String get proformaEmptyError;

  /// No description provided for @deliveryInProgressError.
  ///
  /// In es, this message translates to:
  /// **'La proforma ya está en proceso de entrega.'**
  String get deliveryInProgressError;

  /// No description provided for @tooManyItemsError.
  ///
  /// In es, this message translates to:
  /// **'La proforma excede el límite máximo de ítems permitidos.'**
  String get tooManyItemsError;

  /// No description provided for @voidReasonMinLengthError.
  ///
  /// In es, this message translates to:
  /// **'El motivo de anulación debe tener al menos 5 caracteres.'**
  String get voidReasonMinLengthError;

  /// No description provided for @voidReasonMaxLengthError.
  ///
  /// In es, this message translates to:
  /// **'El motivo no puede exceder los 300 caracteres.'**
  String get voidReasonMaxLengthError;

  /// No description provided for @adminInventoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Control de Inventario'**
  String get adminInventoryTitle;

  /// No description provided for @stockAdjustmentReasonPrompt.
  ///
  /// In es, this message translates to:
  /// **'Motivo del ajuste (obligatorio)'**
  String get stockAdjustmentReasonPrompt;

  /// No description provided for @productToggleActiveSuccess.
  ///
  /// In es, this message translates to:
  /// **'Estado del producto actualizado.'**
  String get productToggleActiveSuccess;

  /// No description provided for @noProductsFoundAdmin.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron productos en el catálogo.'**
  String get noProductsFoundAdmin;

  /// No description provided for @noRequestsFoundAdmin.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes de productos en esta cola.'**
  String get noRequestsFoundAdmin;

  /// No description provided for @noProformasFoundAdmin.
  ///
  /// In es, this message translates to:
  /// **'No hay proformas registradas.'**
  String get noProformasFoundAdmin;

  /// No description provided for @navAdminProducts.
  ///
  /// In es, this message translates to:
  /// **'Productos'**
  String get navAdminProducts;

  /// No description provided for @navAdminInventory.
  ///
  /// In es, this message translates to:
  /// **'Inventario'**
  String get navAdminInventory;

  /// No description provided for @navAdminRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get navAdminRequests;

  /// No description provided for @navAdminProformas.
  ///
  /// In es, this message translates to:
  /// **'Proformas'**
  String get navAdminProformas;

  /// No description provided for @createProformaDraftAction.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Borrador'**
  String get createProformaDraftAction;

  /// No description provided for @saveAction.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get saveAction;

  /// No description provided for @savingAction.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get savingAction;

  /// No description provided for @searchPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar...'**
  String get searchPlaceholder;

  /// No description provided for @productSavedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Producto guardado exitosamente.'**
  String get productSavedSuccess;

  /// No description provided for @productActiveStatusLabel.
  ///
  /// In es, this message translates to:
  /// **'Producto Activo'**
  String get productActiveStatusLabel;

  /// No description provided for @adminGovernanceUnderConstruction.
  ///
  /// In es, this message translates to:
  /// **'Módulo en construcción. La gestión de gobierno y cuentas estará disponible próximamente.'**
  String get adminGovernanceUnderConstruction;

  /// No description provided for @adminClientsManagementTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión de Clientes'**
  String get adminClientsManagementTitle;

  /// No description provided for @adminClientsActiveTab.
  ///
  /// In es, this message translates to:
  /// **'Clientes Activos'**
  String get adminClientsActiveTab;

  /// No description provided for @adminClientsDeactivatedTab.
  ///
  /// In es, this message translates to:
  /// **'Cuentas Desactivadas'**
  String get adminClientsDeactivatedTab;

  /// No description provided for @adminClientsSearchLabel.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o cédula'**
  String get adminClientsSearchLabel;

  /// No description provided for @adminClientsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre del cliente...'**
  String get adminClientsSearchHint;

  /// No description provided for @adminClientsEmptyActive.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron clientes registrados.'**
  String get adminClientsEmptyActive;

  /// No description provided for @adminClientsEmptyDeactivated.
  ///
  /// In es, this message translates to:
  /// **'No hay cuentas desactivadas actualmente.'**
  String get adminClientsEmptyDeactivated;

  /// No description provided for @adminClientsStatusDeactivated.
  ///
  /// In es, this message translates to:
  /// **'Estado: DESACTIVADA'**
  String get adminClientsStatusDeactivated;

  /// No description provided for @adminClientsReactivateTitle.
  ///
  /// In es, this message translates to:
  /// **'Reactivar Cuenta'**
  String get adminClientsReactivateTitle;

  /// No description provided for @adminClientsReactivateContent.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas reactivar la cuenta de {fullName}?'**
  String adminClientsReactivateContent(String fullName);

  /// No description provided for @adminClientsReactivateConfirm.
  ///
  /// In es, this message translates to:
  /// **'Reactivar'**
  String get adminClientsReactivateConfirm;

  /// No description provided for @adminClientsTooltipView.
  ///
  /// In es, this message translates to:
  /// **'Ver Ficha'**
  String get adminClientsTooltipView;

  /// No description provided for @adminClientsSemanticsView.
  ///
  /// In es, this message translates to:
  /// **'Ver ficha de cliente'**
  String get adminClientsSemanticsView;

  /// No description provided for @adminClientsSemanticsReactivate.
  ///
  /// In es, this message translates to:
  /// **'Reactivar cuenta de usuario'**
  String get adminClientsSemanticsReactivate;

  /// No description provided for @adminClientDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Ficha de Cliente: {fullName}'**
  String adminClientDetailTitle(String fullName);

  /// No description provided for @adminClientIdentityTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de Identidad (Sólo Lectura)'**
  String get adminClientIdentityTitle;

  /// No description provided for @adminClientFieldFullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre Completo'**
  String get adminClientFieldFullName;

  /// No description provided for @adminClientFieldDocument.
  ///
  /// In es, this message translates to:
  /// **'Documento de Identidad'**
  String get adminClientFieldDocument;

  /// No description provided for @adminClientFieldEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo Electrónico'**
  String get adminClientFieldEmail;

  /// No description provided for @adminClientFieldPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono de Contacto'**
  String get adminClientFieldPhone;

  /// No description provided for @adminClientFieldAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección Domiciliaria'**
  String get adminClientFieldAddress;

  /// No description provided for @adminClientFieldRole.
  ///
  /// In es, this message translates to:
  /// **'Rol en el Sistema'**
  String get adminClientFieldRole;

  /// No description provided for @adminClientAddressNotRegistered.
  ///
  /// In es, this message translates to:
  /// **'No registrada'**
  String get adminClientAddressNotRegistered;

  /// No description provided for @adminClientPetsRegisteredTitle.
  ///
  /// In es, this message translates to:
  /// **'Mascotas Registradas ({count})'**
  String adminClientPetsRegisteredTitle(int count);

  /// No description provided for @adminClientNoPets.
  ///
  /// In es, this message translates to:
  /// **'El cliente no tiene mascotas registradas.'**
  String get adminClientNoPets;

  /// No description provided for @adminClientTooltipBack.
  ///
  /// In es, this message translates to:
  /// **'Volver al listado'**
  String get adminClientTooltipBack;

  /// No description provided for @adminClientSemanticsBack.
  ///
  /// In es, this message translates to:
  /// **'Volver al listado de clientes'**
  String get adminClientSemanticsBack;

  /// No description provided for @adminPetCorrectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Corregir Ficha de {name}'**
  String adminPetCorrectionTitle(String name);

  /// No description provided for @adminPetCorrectionNote.
  ///
  /// In es, this message translates to:
  /// **'Nota: El personal sólo está autorizado a rectificar el sexo y estado reproductivo de la mascota.'**
  String get adminPetCorrectionNote;

  /// No description provided for @adminPetCorrectionSexLabel.
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get adminPetCorrectionSexLabel;

  /// No description provided for @adminPetCorrectionReproductiveLabel.
  ///
  /// In es, this message translates to:
  /// **'Estado Reproductivo'**
  String get adminPetCorrectionReproductiveLabel;

  /// No description provided for @adminPetCorrectionSexMale.
  ///
  /// In es, this message translates to:
  /// **'Macho (MALE)'**
  String get adminPetCorrectionSexMale;

  /// No description provided for @adminPetCorrectionSexFemale.
  ///
  /// In es, this message translates to:
  /// **'Hembra (FEMALE)'**
  String get adminPetCorrectionSexFemale;

  /// No description provided for @adminPetCorrectionReproductiveIntact.
  ///
  /// In es, this message translates to:
  /// **'Fértil / Entero (INTACT)'**
  String get adminPetCorrectionReproductiveIntact;

  /// No description provided for @adminPetCorrectionReproductiveNeutered.
  ///
  /// In es, this message translates to:
  /// **'Esterilizado / Castrado (NEUTERED)'**
  String get adminPetCorrectionReproductiveNeutered;

  /// No description provided for @adminPetCorrectionReproductiveUnknown.
  ///
  /// In es, this message translates to:
  /// **'Desconocido (UNKNOWN)'**
  String get adminPetCorrectionReproductiveUnknown;

  /// No description provided for @adminPetCorrectionSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar Corrección'**
  String get adminPetCorrectionSave;

  /// No description provided for @adminPetCorrectionAction.
  ///
  /// In es, this message translates to:
  /// **'Corregir'**
  String get adminPetCorrectionAction;

  /// No description provided for @adminPetCorrectionTooltip.
  ///
  /// In es, this message translates to:
  /// **'Corregir Sexo/Estado'**
  String get adminPetCorrectionTooltip;

  /// No description provided for @adminPetCorrectionSemantics.
  ///
  /// In es, this message translates to:
  /// **'Corregir sexo y estado reproductivo de la mascota'**
  String get adminPetCorrectionSemantics;

  /// No description provided for @adminPetSpeciesLabel.
  ///
  /// In es, this message translates to:
  /// **'Especie: {species} | Raza: {breed}'**
  String adminPetSpeciesLabel(String species, String breed);

  /// No description provided for @adminPetSexReproductiveLabel.
  ///
  /// In es, this message translates to:
  /// **'Sexo: {sex} | Reproductivo: {reproductiveStatus}'**
  String adminPetSexReproductiveLabel(String sex, String reproductiveStatus);

  /// No description provided for @adminPetBreedNotSpecified.
  ///
  /// In es, this message translates to:
  /// **'No especificada'**
  String get adminPetBreedNotSpecified;

  /// No description provided for @adminBlockAvailabilityTitle.
  ///
  /// In es, this message translates to:
  /// **'Bloquear Disponibilidad'**
  String get adminBlockAvailabilityTitle;

  /// No description provided for @adminBlockAction.
  ///
  /// In es, this message translates to:
  /// **'Bloquear'**
  String get adminBlockAction;

  /// No description provided for @adminRescheduleAppointmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Reagendar Cita'**
  String get adminRescheduleAppointmentTitle;

  /// No description provided for @adminRescheduleAction.
  ///
  /// In es, this message translates to:
  /// **'Reagendar'**
  String get adminRescheduleAction;

  /// No description provided for @adminAgendaTitle.
  ///
  /// In es, this message translates to:
  /// **'Agenda Administrativa'**
  String get adminAgendaTitle;

  /// No description provided for @adminStatusFilterLabel.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get adminStatusFilterLabel;

  /// No description provided for @adminConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get adminConfirmAction;

  /// No description provided for @adminCompleteAction.
  ///
  /// In es, this message translates to:
  /// **'Completar'**
  String get adminCompleteAction;

  /// No description provided for @adminViewModeWeek.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get adminViewModeWeek;

  /// No description provided for @adminViewModeMonth.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get adminViewModeMonth;

  /// No description provided for @adminStatusFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos los estados'**
  String get adminStatusFilterAll;

  /// No description provided for @adminStatusFilterPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get adminStatusFilterPending;

  /// No description provided for @adminStatusFilterConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmadas'**
  String get adminStatusFilterConfirmed;

  /// No description provided for @adminStatusFilterCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completadas'**
  String get adminStatusFilterCompleted;

  /// No description provided for @adminStatusFilterCancelled.
  ///
  /// In es, this message translates to:
  /// **'Canceladas'**
  String get adminStatusFilterCancelled;

  /// No description provided for @clinicalEntryAnnulmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Anulación de Entrada Clínica'**
  String get clinicalEntryAnnulmentTitle;

  /// No description provided for @clinicalEntryAnnulAction.
  ///
  /// In es, this message translates to:
  /// **'Anular Registro'**
  String get clinicalEntryAnnulAction;

  /// No description provided for @clinicalViewVersionsAction.
  ///
  /// In es, this message translates to:
  /// **'Ver Versiones'**
  String get clinicalViewVersionsAction;

  /// No description provided for @clinicalCorrectAction.
  ///
  /// In es, this message translates to:
  /// **'Corregir'**
  String get clinicalCorrectAction;

  /// No description provided for @clinicalConsultationAnnulmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Anulación de Registro Clínico'**
  String get clinicalConsultationAnnulmentTitle;

  /// No description provided for @clinicalConfirmAnnulmentAction.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Anulación'**
  String get clinicalConfirmAnnulmentAction;

  /// No description provided for @clinicalPrescribeTreatmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Prescribir Tratamiento'**
  String get clinicalPrescribeTreatmentTitle;

  /// No description provided for @clinicalAddPrescriptionLineAction.
  ///
  /// In es, this message translates to:
  /// **'Añadir Línea'**
  String get clinicalAddPrescriptionLineAction;

  /// No description provided for @clinicalPrescribeMedicationAction.
  ///
  /// In es, this message translates to:
  /// **'Prescribir Medicamento'**
  String get clinicalPrescribeMedicationAction;

  /// No description provided for @clinicalUploadAttachmentAction.
  ///
  /// In es, this message translates to:
  /// **'Subir Archivo Adjunto'**
  String get clinicalUploadAttachmentAction;

  /// No description provided for @clinicalUpdatePetPhotoAction.
  ///
  /// In es, this message translates to:
  /// **'Actualizar Foto Mascota'**
  String get clinicalUpdatePetPhotoAction;

  /// Etiqueta de fecha del bloqueo
  ///
  /// In es, this message translates to:
  /// **'Fecha (YYYY-MM-DD)'**
  String get agendaBlockDateLabel;

  /// Ejemplo de fecha de bloqueo
  ///
  /// In es, this message translates to:
  /// **'2026-09-02'**
  String get agendaBlockDateHint;

  /// Etiqueta de franja del bloqueo
  ///
  /// In es, this message translates to:
  /// **'Franja horaria (opcional, ej. 09:00)'**
  String get agendaBlockSlotLabel;

  /// Ayuda de franja del bloqueo
  ///
  /// In es, this message translates to:
  /// **'Dejar en blanco para bloquear día completo'**
  String get agendaBlockSlotHint;

  /// Etiqueta de motivo del bloqueo
  ///
  /// In es, this message translates to:
  /// **'Motivo del bloqueo'**
  String get agendaBlockReasonLabel;

  /// Ejemplos de motivo de bloqueo
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento, feriado o ausencia médica'**
  String get agendaBlockReasonHint;

  /// Nueva fecha al reagendar
  ///
  /// In es, this message translates to:
  /// **'Nueva Fecha (YYYY-MM-DD)'**
  String get agendaRescheduleDateLabel;

  /// Nueva franja al reagendar
  ///
  /// In es, this message translates to:
  /// **'Nueva Franja (HH:mm)'**
  String get agendaRescheduleSlotLabel;

  /// Tooltip de cancelar cita
  ///
  /// In es, this message translates to:
  /// **'Cancelar Cita'**
  String get agendaCancelAppointmentTooltip;

  /// Etiqueta accesible de cancelar
  ///
  /// In es, this message translates to:
  /// **'Cancelar cita en conflicto'**
  String get agendaCancelConflictSemantic;

  /// Tooltip de reagendar cita
  ///
  /// In es, this message translates to:
  /// **'Reagendar Cita'**
  String get agendaRescheduleAppointmentTooltip;

  /// Etiqueta accesible de reagendar
  ///
  /// In es, this message translates to:
  /// **'Reagendar cita en conflicto'**
  String get agendaRescheduleConflictSemantic;

  /// Navegacion al dia anterior
  ///
  /// In es, this message translates to:
  /// **'Día anterior'**
  String get agendaPreviousDayTooltip;

  /// Etiqueta accesible del dia anterior
  ///
  /// In es, this message translates to:
  /// **'Día anterior'**
  String get agendaPreviousDaySemantic;

  /// Navegacion al dia siguiente
  ///
  /// In es, this message translates to:
  /// **'Día siguiente'**
  String get agendaNextDayTooltip;

  /// Etiqueta accesible del dia siguiente
  ///
  /// In es, this message translates to:
  /// **'Día siguiente'**
  String get agendaNextDaySemantic;

  /// Motivo de anulacion clinica
  ///
  /// In es, this message translates to:
  /// **'Motivo obligatorio de anulación *'**
  String get clinicalAnnulReasonLabel;

  /// Medicamento prescrito
  ///
  /// In es, this message translates to:
  /// **'Medicamento *'**
  String get clinicalMedicationLabel;

  /// Dosis prescrita
  ///
  /// In es, this message translates to:
  /// **'Dosis * (ej: 10 mg/kg)'**
  String get clinicalDoseLabel;

  /// Via de administracion
  ///
  /// In es, this message translates to:
  /// **'Vía de administración *'**
  String get clinicalRouteLabel;

  /// Duracion del tratamiento
  ///
  /// In es, this message translates to:
  /// **'Duración * (ej: 7 días)'**
  String get clinicalDurationLabel;

  /// Modalidad del tratamiento
  ///
  /// In es, this message translates to:
  /// **'Modalidad *'**
  String get clinicalModalityLabel;

  /// Tooltip de anulacion
  ///
  /// In es, this message translates to:
  /// **'Anular registro clínico'**
  String get clinicalAnnulRecordTooltip;

  /// Etiqueta accesible de anulacion
  ///
  /// In es, this message translates to:
  /// **'Anular registro clínico'**
  String get clinicalAnnulRecordSemantic;

  /// Tooltip de aplazamiento
  ///
  /// In es, this message translates to:
  /// **'Aplazar o cerrar el registro'**
  String get clinicalDeferTooltip;

  /// Etiqueta accesible de aplazamiento
  ///
  /// In es, this message translates to:
  /// **'Aplazar formulario'**
  String get clinicalDeferSemantic;

  /// Accion de aplazar
  ///
  /// In es, this message translates to:
  /// **'Aplazar'**
  String get clinicalDeferAction;

  /// Motivo de consulta
  ///
  /// In es, this message translates to:
  /// **'Motivo de consulta *'**
  String get clinicalReasonLabel;

  /// Enfermedad actual
  ///
  /// In es, this message translates to:
  /// **'Enfermedad actual (opcional)'**
  String get clinicalCurrentIllnessLabel;

  /// Antecedentes medicos
  ///
  /// In es, this message translates to:
  /// **'Antecedentes médicos (opcional)'**
  String get clinicalBackgroundLabel;

  /// Diagnostico
  ///
  /// In es, this message translates to:
  /// **'Diagnóstico'**
  String get clinicalDiagnosisLabel;

  /// Tipo de diagnostico
  ///
  /// In es, this message translates to:
  /// **'Tipo de Diagnóstico'**
  String get clinicalDiagnosisTypeLabel;

  /// Diagnostico presuntivo
  ///
  /// In es, this message translates to:
  /// **'Presuntivo'**
  String get clinicalDiagnosisPresumptive;

  /// Diagnostico definitivo
  ///
  /// In es, this message translates to:
  /// **'Definitivo'**
  String get clinicalDiagnosisDefinitive;

  /// Indicaciones al propietario
  ///
  /// In es, this message translates to:
  /// **'Indicaciones para el propietario (opcional)'**
  String get clinicalOwnerInstructionsLabel;

  /// Temperatura
  ///
  /// In es, this message translates to:
  /// **'T° (°C)'**
  String get clinicalTemperatureLabel;

  /// Ejemplo de temperatura
  ///
  /// In es, this message translates to:
  /// **'ej: 38.5'**
  String get clinicalTemperatureHint;

  /// Frecuencia cardiaca
  ///
  /// In es, this message translates to:
  /// **'FC (lpm)'**
  String get clinicalHeartRateLabel;

  /// Rango de frecuencia cardiaca
  ///
  /// In es, this message translates to:
  /// **'10..400'**
  String get clinicalHeartRateHint;

  /// Frecuencia respiratoria
  ///
  /// In es, this message translates to:
  /// **'FR (rpm)'**
  String get clinicalRespRateLabel;

  /// Rango de frecuencia respiratoria
  ///
  /// In es, this message translates to:
  /// **'5..200'**
  String get clinicalRespRateHint;

  /// Peso
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get clinicalWeightLabel;

  /// Ejemplo de peso
  ///
  /// In es, this message translates to:
  /// **'ej: 12.5'**
  String get clinicalWeightHint;

  /// Condicion corporal
  ///
  /// In es, this message translates to:
  /// **'CC (1 a 9)'**
  String get clinicalBodyConditionLabel;

  /// Sistema no examinado
  ///
  /// In es, this message translates to:
  /// **'No examinado'**
  String get clinicalSystemNotExamined;

  /// Sistema normal
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get clinicalSystemNormal;

  /// Sistema alterado
  ///
  /// In es, this message translates to:
  /// **'Alterado'**
  String get clinicalSystemAbnormal;

  /// Sin versiones previas
  ///
  /// In es, this message translates to:
  /// **'No existen versiones anteriores registradas.'**
  String get clinicalNoPreviousVersions;

  /// Motivo de anulacion en historial
  ///
  /// In es, this message translates to:
  /// **'Motivo obligatorio de anulación *'**
  String get clinicalAnnulReasonHistoryLabel;

  /// Sin registros clinicos
  ///
  /// In es, this message translates to:
  /// **'La mascota no tiene registros clínicos registrados.'**
  String get clinicalNoRecords;

  /// Tooltip de atajos
  ///
  /// In es, this message translates to:
  /// **'Ver atajos de teclado (?)'**
  String get dashboardShortcutsTooltip;

  /// Etiqueta accesible de atajos
  ///
  /// In es, this message translates to:
  /// **'Ver atajos de teclado'**
  String get dashboardShortcutsSemantic;

  /// Tooltip de refresco
  ///
  /// In es, this message translates to:
  /// **'Actualizar métricas'**
  String get dashboardRefreshTooltip;

  /// Etiqueta accesible de refresco
  ///
  /// In es, this message translates to:
  /// **'Actualizar métricas'**
  String get dashboardRefreshSemantic;

  /// Hallazgos por sistema
  ///
  /// In es, this message translates to:
  /// **'Hallazgos descriptivos obligatorios para {system} *'**
  String clinicalFindingsLabel(String system);

  /// Entrada de version del historial
  ///
  /// In es, this message translates to:
  /// **'Versión {number} - {date}'**
  String clinicalVersionEntry(String number, String date);

  /// Titulo del historial clinico
  ///
  /// In es, this message translates to:
  /// **'Historial Clínico: {pet}'**
  String clinicalHistoryTitle(String pet);

  /// Error de carga del historial
  ///
  /// In es, this message translates to:
  /// **'Error al cargar historial: {error}'**
  String clinicalHistoryLoadError(String error);

  /// Resumen de diagnostico
  ///
  /// In es, this message translates to:
  /// **'Diagnóstico: {diagnosis}'**
  String clinicalDiagnosisSummary(String diagnosis);

  /// Tooltip de detalle de metrica
  ///
  /// In es, this message translates to:
  /// **'Ver detalle de {metric}'**
  String dashboardMetricDetailTooltip(String metric);

  /// Ayuda del campo de hallazgos
  ///
  /// In es, this message translates to:
  /// **'Requerido al marcar el sistema como alterado.'**
  String get clinicalFindingsHelper;

  /// Ayuda del motivo de consulta
  ///
  /// In es, this message translates to:
  /// **'Obligatorio. Máximo 500 caracteres.'**
  String get clinicalReasonHelper;

  /// Linea de prescripcion
  ///
  /// In es, this message translates to:
  /// **'{medication} ({dose})'**
  String clinicalPrescriptionLine(String medication, String dose);

  /// Linea de adjunto clinico
  ///
  /// In es, this message translates to:
  /// **'{path} ({bytes} B)'**
  String clinicalAttachmentLine(String path, String bytes);

  /// Distintivo de version
  ///
  /// In es, this message translates to:
  /// **'v{number}'**
  String clinicalVersionBadge(String number);

  /// Etiqueta accesible de metrica
  ///
  /// In es, this message translates to:
  /// **'{metric}: {value}'**
  String dashboardMetricSemantic(String metric, String value);

  /// Destino: tablero de administracion
  ///
  /// In es, this message translates to:
  /// **'Panel'**
  String get navAdminDashboard;

  /// Destino: gestion de clientes
  ///
  /// In es, this message translates to:
  /// **'Clientes'**
  String get navAdminClients;

  /// Destino: catalogo de servicios
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get navAdminServices;

  /// Destino: registros clinicos
  ///
  /// In es, this message translates to:
  /// **'Clínica'**
  String get navAdminClinical;

  /// Titulo del modulo de gobierno
  ///
  /// In es, this message translates to:
  /// **'Gobierno y Cuentas'**
  String get govTitle;

  /// Pestana de gestion de cuentas
  ///
  /// In es, this message translates to:
  /// **'Cuentas de Usuario'**
  String get govTabAccounts;

  /// Pestana de configuracion operativa
  ///
  /// In es, this message translates to:
  /// **'Configuración Operativa'**
  String get govTabOperatingParameters;

  /// Pestana de registro de auditoria
  ///
  /// In es, this message translates to:
  /// **'Registro de Auditoría'**
  String get govTabAuditLog;

  /// Texto sugerido para busqueda de usuarios
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre, correo o cédula...'**
  String get govSearchPlaceholder;

  /// Boton para crear una nueva cuenta
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get govCreateAccountButton;

  /// Filtro: todos los roles
  ///
  /// In es, this message translates to:
  /// **'Todos los roles'**
  String get govRoleFilterAll;

  /// Rol: Super Usuario
  ///
  /// In es, this message translates to:
  /// **'Super Usuario'**
  String get govRoleSuperAdmin;

  /// Rol: Administrador
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get govRoleAdmin;

  /// Rol: Cliente
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get govRoleClient;

  /// Estado: Activo
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get govStatusActive;

  /// Estado: Desactivado
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get govStatusDeactivated;

  /// Estado: Eliminado
  ///
  /// In es, this message translates to:
  /// **'Eliminado'**
  String get govStatusDeleted;

  /// Encabezado de columna: Nombre
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get govColumnName;

  /// Encabezado de columna: Correo
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get govColumnEmail;

  /// Encabezado de columna: Rol
  ///
  /// In es, this message translates to:
  /// **'Rol'**
  String get govColumnRole;

  /// Encabezado de columna: Estado
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get govColumnStatus;

  /// Encabezado de columna: Acciones
  ///
  /// In es, this message translates to:
  /// **'Acciones'**
  String get govColumnActions;

  /// Distintivo para cuenta de Super Usuario
  ///
  /// In es, this message translates to:
  /// **'Inmutable'**
  String get govSuperAdminImmutableBadge;

  /// Accion para editar identidad de cuenta
  ///
  /// In es, this message translates to:
  /// **'Editar Identidad'**
  String get govActionEditIdentity;

  /// Accion para restablecer contrasena
  ///
  /// In es, this message translates to:
  /// **'Restablecer Contraseña'**
  String get govActionResetPassword;

  /// Accion para desactivar cuenta
  ///
  /// In es, this message translates to:
  /// **'Desactivar Cuenta'**
  String get govActionDeactivate;

  /// Accion para reactivar una cuenta desactivada
  ///
  /// In es, this message translates to:
  /// **'Reactivar Cuenta'**
  String get govActionReactivate;

  /// Accion para dar de baja a personal
  ///
  /// In es, this message translates to:
  /// **'Eliminar Personal'**
  String get govActionDeleteStaff;

  /// Mensaje cuando la lista de cuentas esta vacia
  ///
  /// In es, this message translates to:
  /// **'No se encontraron cuentas de usuario.'**
  String get govNoAccountsFound;

  /// Titulo del dialogo de creacion de cuenta
  ///
  /// In es, this message translates to:
  /// **'Crear Nueva Cuenta'**
  String get govCreateAccountDialogTitle;

  /// Campo de correo electronico
  ///
  /// In es, this message translates to:
  /// **'Correo Electrónico'**
  String get govFieldEmail;

  /// Campo de nombre completo
  ///
  /// In es, this message translates to:
  /// **'Nombre Completo'**
  String get govFieldFullName;

  /// Campo para seleccionar rol
  ///
  /// In es, this message translates to:
  /// **'Rol de la Cuenta'**
  String get govFieldRole;

  /// Campo de telefono celular
  ///
  /// In es, this message translates to:
  /// **'Teléfono (+593...)'**
  String get govFieldPhone;

  /// Campo de tipo de documento
  ///
  /// In es, this message translates to:
  /// **'Tipo de Documento'**
  String get govFieldDocumentType;

  /// Campo de numero de documento
  ///
  /// In es, this message translates to:
  /// **'Número de Documento'**
  String get govFieldDocumentNumber;

  /// Campo de direccion
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get govFieldAddress;

  /// Boton de cancelacion
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get govButtonCancel;

  /// Boton para enviar creacion de cuenta
  ///
  /// In es, this message translates to:
  /// **'Crear y Generar Enlace'**
  String get govButtonCreate;

  /// Mensaje de validacion para campo vacio
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get govValidationRequired;

  /// Mensaje de validacion de correo invalido
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico no válido'**
  String get govValidationInvalidEmail;

  /// Mensaje de validacion de telefono invalido
  ///
  /// In es, this message translates to:
  /// **'Teléfono no válido (+593 seguido de 9 dígitos)'**
  String get govValidationInvalidPhone;

  /// Titulo del dialogo para editar identidad
  ///
  /// In es, this message translates to:
  /// **'Editar Identidad de Cuenta'**
  String get govEditIdentityDialogTitle;

  /// Aviso de correo inmutable
  ///
  /// In es, this message translates to:
  /// **'El correo electrónico es de sólo lectura y no puede modificarse.'**
  String get govEmailReadOnlyNotice;

  /// Boton para guardar cambios
  ///
  /// In es, this message translates to:
  /// **'Guardar Cambios'**
  String get govButtonSave;

  /// Titulo del dialogo con enlace de cuenta creada
  ///
  /// In es, this message translates to:
  /// **'Cuenta Aprovisionada con Éxito'**
  String get govLinkDialogTitleCreated;

  /// Titulo del dialogo con enlace de restablecimiento
  ///
  /// In es, this message translates to:
  /// **'Enlace de Restablecimiento Generado'**
  String get govLinkDialogTitleReset;

  /// Aviso de entrega manual sin envio de correo
  ///
  /// In es, this message translates to:
  /// **'Entregue el siguiente enlace al usuario de forma presencial o por canal seguro. El sistema NO despacha correos automáticos:'**
  String get govLinkDialogNotice;

  /// Boton para copiar enlace
  ///
  /// In es, this message translates to:
  /// **'Copiar Enlace'**
  String get govButtonCopyLink;

  /// Mensaje de enlace copiado
  ///
  /// In es, this message translates to:
  /// **'Enlace copiado al portapapeles.'**
  String get govLinkCopiedSnackbar;

  /// Boton de cierre de dialogo
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get govButtonClose;

  /// Titulo de confirmacion de desactivacion
  ///
  /// In es, this message translates to:
  /// **'Confirmar Desactivación'**
  String get govConfirmDeactivateTitle;

  /// Mensaje de confirmacion de desactivacion
  ///
  /// In es, this message translates to:
  /// **'¿Está seguro de que desea desactivar la cuenta de {name}? Se revocarán sus sesiones y se cancelarán citas activas.'**
  String govConfirmDeactivateMessage(String name);

  /// Boton para confirmar desactivacion
  ///
  /// In es, this message translates to:
  /// **'Desactivar'**
  String get govButtonConfirmDeactivate;

  /// Titulo de confirmacion de reactivacion de cuenta
  ///
  /// In es, this message translates to:
  /// **'Confirmar Reactivación'**
  String get govConfirmReactivateTitle;

  /// Mensaje de confirmacion de reactivacion de cuenta
  ///
  /// In es, this message translates to:
  /// **'¿Está seguro de que desea reactivar la cuenta de {name}? Volverá a tener acceso al sistema.'**
  String govConfirmReactivateMessage(String name);

  /// Boton para confirmar reactivacion
  ///
  /// In es, this message translates to:
  /// **'Reactivar'**
  String get govButtonConfirmReactivate;

  /// Titulo de confirmacion de eliminacion logica de personal
  ///
  /// In es, this message translates to:
  /// **'Confirmar Baja Lógica de Personal'**
  String get govConfirmDeleteStaffTitle;

  /// Mensaje de confirmacion de eliminacion logica
  ///
  /// In es, this message translates to:
  /// **'¿Está seguro de dar de baja lógica a {name}? Su cuenta quedará deshabilitada pero su historial clínico y contable se preservará íntegro.'**
  String govConfirmDeleteStaffMessage(String name);

  /// Boton para confirmar eliminacion logica de personal
  ///
  /// In es, this message translates to:
  /// **'Eliminar Personal'**
  String get govButtonConfirmDelete;

  /// Titulo de parametros operativos
  ///
  /// In es, this message translates to:
  /// **'Parámetros Operativos del Negocio'**
  String get govOperatingParamsTitle;

  /// Descripcion de parametros operativos
  ///
  /// In es, this message translates to:
  /// **'Configuración general de horarios, turnos y umbrales de inventario. La zona horaria institucional es inmutable (America/Guayaquil).'**
  String get govOperatingParamsDescription;

  /// Campo hora de apertura
  ///
  /// In es, this message translates to:
  /// **'Hora de Apertura (HH:mm)'**
  String get govFieldOpeningTime;

  /// Campo hora de cierre
  ///
  /// In es, this message translates to:
  /// **'Hora de Cierre (HH:mm)'**
  String get govFieldClosingTime;

  /// Campo duracion de turno
  ///
  /// In es, this message translates to:
  /// **'Duración de Turno (minutos)'**
  String get govFieldSlotDuration;

  /// Campo dias laborables
  ///
  /// In es, this message translates to:
  /// **'Días Laborables'**
  String get govFieldWorkingDays;

  /// Campo umbral de stock bajo
  ///
  /// In es, this message translates to:
  /// **'Umbral de Stock Bajo'**
  String get govFieldLowStockThreshold;

  /// Dia lunes
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get govDayMonday;

  /// Dia martes
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get govDayTuesday;

  /// Dia miercoles
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get govDayWednesday;

  /// Dia jueves
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get govDayThursday;

  /// Dia viernes
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get govDayFriday;

  /// Dia sabado
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get govDaySaturday;

  /// Dia domingo
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get govDaySunday;

  /// Boton guardar parametros
  ///
  /// In es, this message translates to:
  /// **'Guardar Parámetros'**
  String get govButtonSaveParams;

  /// Mensaje de parametros guardados
  ///
  /// In es, this message translates to:
  /// **'Parámetros operativos actualizados correctamente.'**
  String get govParamsSavedSuccess;

  /// Validacion de orden de horarios
  ///
  /// In es, this message translates to:
  /// **'La hora de apertura debe ser anterior a la de cierre.'**
  String get govInvalidTimeOrder;

  /// Titulo de registro de auditoria
  ///
  /// In es, this message translates to:
  /// **'Registro de Auditoría'**
  String get govAuditLogTitle;

  /// Mensaje de log vacio
  ///
  /// In es, this message translates to:
  /// **'No hay registros de auditoría disponibles.'**
  String get govAuditLogEmpty;

  /// Columna fecha y hora de auditoria
  ///
  /// In es, this message translates to:
  /// **'Fecha y Hora'**
  String get govAuditColumnDate;

  /// Columna actor de auditoria
  ///
  /// In es, this message translates to:
  /// **'Actor'**
  String get govAuditColumnActor;

  /// Columna accion de auditoria
  ///
  /// In es, this message translates to:
  /// **'Acción'**
  String get govAuditColumnAction;

  /// Columna objetivo de auditoria
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get govAuditColumnTarget;

  /// Columna metadatos de auditoria
  ///
  /// In es, this message translates to:
  /// **'Metadatos'**
  String get govAuditColumnMetadata;

  /// Boton actualizar
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get govButtonRefresh;

  /// Filtro de accion en auditoria
  ///
  /// In es, this message translates to:
  /// **'Filtrar por acción'**
  String get govAuditFilterAction;

  /// Opcion todas las acciones
  ///
  /// In es, this message translates to:
  /// **'Todas las acciones'**
  String get govAuditAllActions;

  /// Titulo de navegacion de clientes
  ///
  /// In es, this message translates to:
  /// **'Clientes'**
  String get adminNavClients;

  /// Titulo de navegacion de registro clinico
  ///
  /// In es, this message translates to:
  /// **'Registro Clínico'**
  String get adminNavClinical;

  /// Titulo de navegacion de bandeja de mensajeria
  ///
  /// In es, this message translates to:
  /// **'Bandeja de Mensajería'**
  String get adminNavChat;

  /// Titulo del panel o resumen de seleccion de productos
  ///
  /// In es, this message translates to:
  /// **'Productos seleccionados'**
  String get catalogSelectionTitle;

  /// Boton para limpiar los productos seleccionados
  ///
  /// In es, this message translates to:
  /// **'Limpiar selección'**
  String get catalogClearSelection;

  /// Boton para solicitar seleccionados con conteo
  ///
  /// In es, this message translates to:
  /// **'Solicitar {count} producto(s)'**
  String catalogSubmitRequestWithCount(int count);

  /// Boton para agregar un producto a la seleccion
  ///
  /// In es, this message translates to:
  /// **'Agregar a la solicitud'**
  String get catalogAddToSelection;

  /// Boton para quitar un producto de la seleccion
  ///
  /// In es, this message translates to:
  /// **'Eliminar de la selección'**
  String get catalogRemoveFromSelection;

  /// Mensaje de exito al enviar la solicitud
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada exitosamente'**
  String get catalogRequestSuccess;

  /// Mensaje cuando no hay productos seleccionados
  ///
  /// In es, this message translates to:
  /// **'No has seleccionado ningún producto'**
  String get catalogSelectionEmpty;

  /// Precios unitario y total por linea de seleccion
  ///
  /// In es, this message translates to:
  /// **'Unitario: \${unit} · Total: \${total}'**
  String catalogSelectionLinePrices(String unit, String total);

  /// Insignia de cantidad seleccionada para el producto
  ///
  /// In es, this message translates to:
  /// **'En la solicitud: {quantity}'**
  String catalogInSelectionBadge(int quantity);

  /// Resumen de unidades y lineas seleccionadas
  ///
  /// In es, this message translates to:
  /// **'{units, plural, =1{1 unidad} other{{units} unidades}} · {lines, plural, =1{1 producto} other{{lines} productos}}'**
  String catalogSelectionSummary(int units, int lines);

  /// Total formateado en detalle de producto
  ///
  /// In es, this message translates to:
  /// **'Total: \${amount}'**
  String productDetailTotal(String amount);

  /// Boton para abrir el carrito de compras
  ///
  /// In es, this message translates to:
  /// **'Mi carrito'**
  String get cartOpenAction;

  /// Subtotal del desglose del carrito
  ///
  /// In es, this message translates to:
  /// **'Subtotal: \${amount}'**
  String cartBreakdownSubtotal(String amount);

  /// Desglose de ICE en el carrito
  ///
  /// In es, this message translates to:
  /// **'ICE: \${amount}'**
  String cartBreakdownIce(String amount);

  /// Desglose de IVA en el carrito
  ///
  /// In es, this message translates to:
  /// **'IVA: \${amount}'**
  String cartBreakdownIva(String amount);

  /// Etiqueta para el selector de cantidad
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get productQuantityLabel;

  /// Rotulo accesible del boton que borra la busqueda del catalogo
  ///
  /// In es, this message translates to:
  /// **'Borrar la búsqueda'**
  String get catalogClearSearch;

  /// Rotulo accesible del boton que resta una unidad
  ///
  /// In es, this message translates to:
  /// **'Quitar una unidad'**
  String get catalogDecreaseQuantity;

  /// Rotulo accesible del boton que suma una unidad
  ///
  /// In es, this message translates to:
  /// **'Añadir una unidad'**
  String get catalogIncreaseQuantity;

  /// Titulo de la pantalla que sustituye al error interno del enrutador cuando la direccion no corresponde a ninguna pantalla (AUD-343, N-15)
  ///
  /// In es, this message translates to:
  /// **'Esta página no existe'**
  String get routeNotFoundTitle;

  /// Explicacion para quien llega a una direccion desconocida, sin texto tecnico ni identificadores internos
  ///
  /// In es, this message translates to:
  /// **'La dirección que abriste no corresponde a ninguna pantalla. Puede que el enlace venga de una versión anterior.'**
  String get routeNotFoundMessage;

  /// Rotulo del control que devuelve al usuario a su pantalla inicial desde la pantalla de direccion desconocida
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get routeNotFoundAction;

  /// Rotulo del control que abre el registro clinico de una mascota desde la ficha de cliente (AUD-344, CL-03)
  ///
  /// In es, this message translates to:
  /// **'Registro clínico'**
  String get adminPetClinicalRecordAction;

  /// Rotulo accesible del control que abre el registro clinico, con el nombre real de la mascota (N-06)
  ///
  /// In es, this message translates to:
  /// **'Abrir el registro clínico de {petName}'**
  String adminPetClinicalRecordSemantics(String petName);

  /// Advertencia del dialogo de anulacion de un registro clinico (CL-08)
  ///
  /// In es, this message translates to:
  /// **'La anulación es inmutable. El registro quedará marcado como ANNULLED y no se podrá volver a editar.'**
  String get clinicalAnnulmentWarning;

  /// Titulo del formulario cuando corrige una consulta ya guardada (CL-12)
  ///
  /// In es, this message translates to:
  /// **'Corregir Consulta Clínica'**
  String get clinicalCorrectConsultationTitle;

  /// Titulo de la seccion 2 del formulario de consulta (PRD 3.5.2)
  ///
  /// In es, this message translates to:
  /// **'2. Motivo y Anamnesis'**
  String get clinicalSectionReasonTitle;

  /// Titulo de la seccion 3 del formulario de consulta
  ///
  /// In es, this message translates to:
  /// **'3. Signos Vitales'**
  String get clinicalSectionVitalsTitle;

  /// Titulo de la seccion 4, examen fisico por sistemas
  ///
  /// In es, this message translates to:
  /// **'4. Examen Físico por Sistemas (10 Sistemas)'**
  String get clinicalSectionExamTitle;

  /// Ayuda de la seccion de examen fisico: ningun sistema se marca normal por omision
  ///
  /// In es, this message translates to:
  /// **'Todos los sistemas inician por omisión en \"NOT_EXAMINED\". Si marca \"ABNORMAL\", es obligatorio ingresar el hallazgo descriptivo.'**
  String get clinicalSectionExamHelp;

  /// Titulo de la seccion 5, diagnostico y plan
  ///
  /// In es, this message translates to:
  /// **'5. Diagnóstico y Tratamiento'**
  String get clinicalSectionPlanTitle;

  /// Rotulo de la lista de lineas de tratamiento prescritas
  ///
  /// In es, this message translates to:
  /// **'Líneas de Tratamiento:'**
  String get clinicalTreatmentLinesLabel;

  /// Estado vacio de la lista de medicamentos prescritos
  ///
  /// In es, this message translates to:
  /// **'No se han prescrito medicamentos para esta consulta.'**
  String get clinicalNoPrescriptions;

  /// Aviso de que la entrada no admite correccion (CL-12, CL-08)
  ///
  /// In es, this message translates to:
  /// **'Este registro clínico no puede ser editado porque está anulado o usted no es el autor original ni Super Usuario.'**
  String get clinicalNotEditableNotice;

  /// Accion de guardar una correccion, que conserva la version anterior (CL-12)
  ///
  /// In es, this message translates to:
  /// **'Guardar Corrección con Versionado'**
  String get clinicalSaveCorrectionAction;

  /// Accion de guardar la entrada de consulta (CL-03)
  ///
  /// In es, this message translates to:
  /// **'Guardar Consulta Clínica'**
  String get clinicalSaveConsultationAction;

  /// Titulo del bloque congelado de identificacion del paciente (PRD 3.5.2)
  ///
  /// In es, this message translates to:
  /// **'1. Bloque de Datos del Paciente (Congelado de Solo Lectura)'**
  String get clinicalSectionPatientTitle;

  /// Nombre del sistema anatomico: mucosas
  ///
  /// In es, this message translates to:
  /// **'Mucosas'**
  String get clinicalSystemMucous;

  /// Nombre del sistema anatomico: piel y anexos
  ///
  /// In es, this message translates to:
  /// **'Piel y Anexos'**
  String get clinicalSystemSkin;

  /// Nombre del sistema anatomico: oidos
  ///
  /// In es, this message translates to:
  /// **'Oídos'**
  String get clinicalSystemEars;

  /// Nombre del sistema anatomico: cardiovascular
  ///
  /// In es, this message translates to:
  /// **'Cardiovascular'**
  String get clinicalSystemCardiovascular;

  /// Nombre del sistema anatomico: respiratorio
  ///
  /// In es, this message translates to:
  /// **'Respiratorio'**
  String get clinicalSystemRespiratory;

  /// Nombre del sistema anatomico: gastrointestinal
  ///
  /// In es, this message translates to:
  /// **'Gastrointestinal'**
  String get clinicalSystemGastrointestinal;

  /// Nombre del sistema anatomico: nervioso
  ///
  /// In es, this message translates to:
  /// **'Nervioso'**
  String get clinicalSystemNervous;

  /// Nombre del sistema anatomico: musculo-esqueletico
  ///
  /// In es, this message translates to:
  /// **'Músculo-esquelético'**
  String get clinicalSystemMusculoskeletal;

  /// Nombre del sistema anatomico: genito-urinario
  ///
  /// In es, this message translates to:
  /// **'Génito-urinario'**
  String get clinicalSystemGenitourinary;

  /// Titulo de la hoja que lista las versiones de una entrada (CL-12, CA-AD-52)
  ///
  /// In es, this message translates to:
  /// **'Historial de Versiones'**
  String get clinicalVersionsSheetTitle;

  /// Texto cuando la version anterior no conserva fecha legible
  ///
  /// In es, this message translates to:
  /// **'Fecha anterior'**
  String get clinicalVersionDateUnknown;

  /// Texto cuando la version anterior no conserva motivo
  ///
  /// In es, this message translates to:
  /// **'Sin motivo'**
  String get clinicalVersionReasonUnknown;

  /// Advertencia del dialogo de anulacion desde el historial (CL-08)
  ///
  /// In es, this message translates to:
  /// **'Esta acción es definitiva e inmutable. Se guardará el motivo de la anulación.'**
  String get clinicalAnnulEntryWarning;

  /// Accion de anular una entrada clinica desde su tarjeta (CL-08, CA-AD-31)
  ///
  /// In es, this message translates to:
  /// **'Anular'**
  String get clinicalAnnulAction;

  /// Aviso de que no hay sesion valida para ejecutar la accion
  ///
  /// In es, this message translates to:
  /// **'Sesión no válida'**
  String get sessionInvalid;

  /// Rotulo accesible del control que crea un bloqueo (AG-06, N-06)
  ///
  /// In es, this message translates to:
  /// **'Crear bloqueo de disponibilidad'**
  String get adminBlockAvailabilitySemantics;

  /// Explicacion de que un bloqueo dejo citas en conflicto (AG-06, CA-AD-55)
  ///
  /// In es, this message translates to:
  /// **'Existen citas agendadas en la franja o fecha bloqueada. Resuelva cada conflicto cancelando o reagendando la cita individualmente:'**
  String get adminBlockConflictsHelp;

  /// Estado vacio de la agenda con los filtros puestos (AG-01)
  ///
  /// In es, this message translates to:
  /// **'No hay citas agendadas para el período o filtros seleccionados.'**
  String get adminAgendaEmpty;

  /// Indicador de cita en conflicto con un bloqueo de disponibilidad
  ///
  /// In es, this message translates to:
  /// **'En conflicto con bloqueo'**
  String get adminAppointmentBlockConflict;

  /// Indicador de cita completada con registro clinico pendiente (CL-10, CA-AD-44)
  ///
  /// In es, this message translates to:
  /// **'Ficha clínica pendiente'**
  String get adminAppointmentClinicalPending;

  /// Rotulo accesible del control que confirma una cita (AG-02, N-06)
  ///
  /// In es, this message translates to:
  /// **'Confirmar cita'**
  String get agendaConfirmAppointmentSemantics;

  /// Ayuda emergente del control que confirma una cita (AG-02)
  ///
  /// In es, this message translates to:
  /// **'Confirmar Cita'**
  String get agendaConfirmAppointmentTooltip;

  /// Ayuda emergente del control que completa una cita (AG-03)
  ///
  /// In es, this message translates to:
  /// **'Completar Cita'**
  String get agendaCompleteAppointmentTooltip;

  /// Rotulo accesible del control que completa una cita (AG-03, N-06)
  ///
  /// In es, this message translates to:
  /// **'Completar cita'**
  String get agendaCompleteAppointmentSemantics;

  /// Rotulo accesible del control que reagenda una cita (AG-08, N-06)
  ///
  /// In es, this message translates to:
  /// **'Reagendar cita'**
  String get agendaRescheduleAppointmentSemantics;

  /// Rotulo accesible del control que cancela una cita (AG-05, N-06)
  ///
  /// In es, this message translates to:
  /// **'Cancelar cita'**
  String get agendaCancelAppointmentSemantics;

  /// Descripcion por defecto para adjunto clinico simulado
  ///
  /// In es, this message translates to:
  /// **'Informe clínico complementario #{count}'**
  String clinicalAttachmentDefaultDesc(int count);

  /// Detalles de linea de tratamiento medico
  ///
  /// In es, this message translates to:
  /// **'Vía: {route} | Duración: {duration} | Mod.: {modality}'**
  String clinicalTreatmentLineDetails(
    String route,
    String duration,
    String modality,
  );

  /// Titulo de seccion de adjuntos clinicos con contador
  ///
  /// In es, this message translates to:
  /// **'6. Adjuntos Clínicos ({count}/{max})'**
  String clinicalSectionAttachmentsTitle(int count, int max);

  /// Ficha congelada: datos de la mascota
  ///
  /// In es, this message translates to:
  /// **'Mascota: {name} ({species} - {breed}) | Sexo: {sex} | Edad: {age}'**
  String clinicalPatientDataPet(
    String name,
    String species,
    String breed,
    String sex,
    String age,
  );

  /// Ficha congelada: estado reproductivo y nacimiento
  ///
  /// In es, this message translates to:
  /// **'Estado Reproductivo: {status} | Nacimiento: {birthDate}'**
  String clinicalPatientDataReproductive(String status, String birthDate);

  /// Ficha congelada: datos del propietario y documento
  ///
  /// In es, this message translates to:
  /// **'Propietario: {name} | {docType}: {docNumber}'**
  String clinicalPatientDataOwner(
    String name,
    String docType,
    String docNumber,
  );

  /// Ficha congelada: contacto y direccion
  ///
  /// In es, this message translates to:
  /// **'Contacto: {phone} | Correo: {email} | Dirección: {address}'**
  String clinicalPatientDataContact(String phone, String email, String address);

  /// Subtitulo de version en historial clinico con editor y motivo
  ///
  /// In es, this message translates to:
  /// **'Editado por: {editor}\nMotivo: {reason}'**
  String clinicalVersionEditedByReason(String editor, String reason);

  /// Insignia de registro clinico corregido con version
  ///
  /// In es, this message translates to:
  /// **'CORREGIDO (v{version})'**
  String clinicalRecordCorrectedBadge(int version);

  /// Nombre del profesional que atendio la consulta
  ///
  /// In es, this message translates to:
  /// **'Atendido por: {authorName}'**
  String clinicalRecordAttendedBy(String authorName);

  /// Motivo de la consulta en historial clinico
  ///
  /// In es, this message translates to:
  /// **'Motivo: {reason}'**
  String clinicalRecordReason(String reason);

  /// Motivo de anulacion del registro clinico
  ///
  /// In es, this message translates to:
  /// **'Motivo de anulación: {reason}'**
  String clinicalRecordAnnulmentReason(String reason);

  /// Cabecera de conflictos detectados por bloqueo de agenda
  ///
  /// In es, this message translates to:
  /// **'Conflictos de Bloqueo Detectados ({count})'**
  String adminBlockConflictsDetected(int count);

  /// Detalle de cita en conflicto con servicio fecha y franja
  ///
  /// In es, this message translates to:
  /// **'{service} | {date} a las {timeSlot}'**
  String adminConflictServiceDateTime(
    String service,
    String date,
    String timeSlot,
  );

  /// Linea de cliente y nombre de mascota en tarjeta de cita
  ///
  /// In es, this message translates to:
  /// **'{clientName} (Mascota: {petName})'**
  String adminAppointmentClientPet(String clientName, String petName);

  /// Nota del cliente en tarjeta de cita de agenda
  ///
  /// In es, this message translates to:
  /// **'Nota del cliente: {notes}'**
  String adminAppointmentClientNotes(String notes);

  /// Etiqueta y nombre de cliente en tarjeta de proforma de administración
  ///
  /// In es, this message translates to:
  /// **'Cliente: {clientName}'**
  String adminProformaClient(String clientName);

  /// Resumen de ítems y total en tarjeta de proforma para administración
  ///
  /// In es, this message translates to:
  /// **'Ítems: {count} · {totalLabel}: \${amount}'**
  String adminProformaCardSummary(int count, String totalLabel, String amount);

  /// Cantidad de unidades de un ítem en resumen de pago
  ///
  /// In es, this message translates to:
  /// **'Cant: {quantity}'**
  String paymentSummaryItemQuantity(int quantity);

  /// Precio base de un ítem en resumen de pago
  ///
  /// In es, this message translates to:
  /// **'Base: \${amount}'**
  String paymentSummaryItemBase(String amount);

  /// Importe de ICE de un ítem en resumen de pago
  ///
  /// In es, this message translates to:
  /// **'ICE ({rate}%): \${amount}'**
  String paymentSummaryItemIce(String rate, String amount);

  /// Importe de IVA de un ítem en resumen de pago
  ///
  /// In es, this message translates to:
  /// **'IVA ({rate}%): \${amount}'**
  String paymentSummaryItemIva(String rate, String amount);

  /// Cantidad, precio base e ICE de un ítem en composición de proforma
  ///
  /// In es, this message translates to:
  /// **'Cant: {quantity} × \${amount} | ICE: {iceBp} bp'**
  String proformaItemQuantityAndIce(int quantity, String amount, int iceBp);

  /// Rótulo de accesibilidad para mostrar contraseña
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get showPassword;

  /// Rótulo de accesibilidad para ocultar contraseña
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get hidePassword;

  /// Título de bienvenida en pantalla de inicio de sesión
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a PetShop'**
  String get loginWelcomeTitle;

  /// Subtítulo en pantalla de inicio de sesión
  ///
  /// In es, this message translates to:
  /// **'Ingresa tus credenciales para acceder a tu panel'**
  String get loginSubtitle;

  /// Título de éxito en recuperación de contraseña
  ///
  /// In es, this message translates to:
  /// **'Instrucciones enviadas'**
  String get forgotPasswordInstructionsSentTitle;

  /// Título de controles de moderación en bandeja de staff
  ///
  /// In es, this message translates to:
  /// **'Controles de Moderación (Exclusivo Super Usuario)'**
  String get staffInboxModerationControlsTitle;

  /// Mensaje en panel vacío de mensajes en bandeja de staff
  ///
  /// In es, this message translates to:
  /// **'Seleccione una conversación para ver los mensajes.'**
  String get staffInboxSelectConversationPrompt;

  /// Cabecera de lista de conversaciones con clientes
  ///
  /// In es, this message translates to:
  /// **'CONVERSACIONES CON CLIENTES'**
  String get staffInboxClientConversationsHeader;

  /// Aviso de conversación bloqueada
  ///
  /// In es, this message translates to:
  /// **'Esta conversación se encuentra bloqueada administrativamente.'**
  String get staffInboxConversationBlockedNotice;

  /// Aviso de conversación archivada
  ///
  /// In es, this message translates to:
  /// **'Esta conversación se encuentra archivada.'**
  String get staffInboxConversationArchivedNotice;

  /// Etiqueta del botón de moderar chat
  ///
  /// In es, this message translates to:
  /// **'Moderar'**
  String get staffInboxModerateButtonLabel;

  /// Insignia de registro clínico anulado
  ///
  /// In es, this message translates to:
  /// **'ANULADO'**
  String get clinicalRecordAnnulledBadge;

  /// Identificador de proforma en tarjeta de administración
  ///
  /// In es, this message translates to:
  /// **'Proforma: {id}'**
  String adminProformaCardId(String id);

  /// Mensaje cuando una proforma no tiene ítems
  ///
  /// In es, this message translates to:
  /// **'Esta proforma no contiene ítems agregados.'**
  String get proformaNoItemsAdded;

  /// Documento y teléfono de cliente en lista administrativa
  ///
  /// In es, this message translates to:
  /// **'{docType}: {docNumber} | Tel: {phone}'**
  String adminClientDocAndPhone(String docType, String docNumber, String phone);

  /// Correo y teléfono de cliente en lista administrativa
  ///
  /// In es, this message translates to:
  /// **'Correo: {email} | Tel: {phone}'**
  String adminClientEmailAndPhone(String email, String phone);

  /// Mensaje de descarga exitosa de PDF con tamaño en KB
  ///
  /// In es, this message translates to:
  /// **'{message} ({sizeKb} KB)'**
  String pdfDownloadSuccessWithSize(String message, String sizeKb);

  /// Título de pantalla de perfil para personal staff
  ///
  /// In es, this message translates to:
  /// **'Perfil del Personal'**
  String get staffProfileTitle;

  /// Título del canal interno en la bandeja de staff
  ///
  /// In es, this message translates to:
  /// **'Canal Interno (STAFF_INTERNAL)'**
  String get staffInboxInternalChannelTitle;

  /// Rótulo de cliente con nombre en chat de staff
  ///
  /// In es, this message translates to:
  /// **'Cliente: {name}'**
  String staffInboxClientLabel(String name);

  /// Saludo en inicio del cliente
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String clientHomeGreeting(String name);

  /// Subtítulo en inicio del cliente
  ///
  /// In es, this message translates to:
  /// **'Resumen de tu cuenta en PetShop'**
  String get clientHomeSubtitle;

  /// Título de tarjeta de próxima cita
  ///
  /// In es, this message translates to:
  /// **'Próxima cita'**
  String get clientHomeNextAppointmentTitle;

  /// Texto cuando no hay citas programadas
  ///
  /// In es, this message translates to:
  /// **'Sin citas programadas'**
  String get clientHomeNoAppointments;

  /// Título de tarjeta de mascotas activas
  ///
  /// In es, this message translates to:
  /// **'Mascotas activas'**
  String get clientHomeActivePetsTitle;

  /// Título de tarjeta de solicitudes en curso
  ///
  /// In es, this message translates to:
  /// **'Solicitudes en curso'**
  String get clientHomeActiveRequestsTitle;

  /// Texto cuando no hay solicitudes activas
  ///
  /// In es, this message translates to:
  /// **'Sin solicitudes activas'**
  String get clientHomeNoRequests;

  /// Título de tarjeta de accesos rápidos
  ///
  /// In es, this message translates to:
  /// **'Accesos rápidos'**
  String get clientHomeQuickActionsTitle;

  /// Título de tarjeta de mensajes recientes
  ///
  /// In es, this message translates to:
  /// **'Mensajes recientes'**
  String get clientHomeRecentMessagesTitle;

  /// Texto cuando no hay mensajes nuevos
  ///
  /// In es, this message translates to:
  /// **'Sin mensajes nuevos del negocio'**
  String get clientHomeNoRecentMessages;

  /// Acción rápida de agendar cita
  ///
  /// In es, this message translates to:
  /// **'Agendar cita'**
  String get clientHomeBookAppointmentAction;

  /// Acción rápida de ver catálogo
  ///
  /// In es, this message translates to:
  /// **'Ver catálogo'**
  String get clientHomeViewCatalogAction;

  /// Acción rápida de registrar mascota
  ///
  /// In es, this message translates to:
  /// **'Registrar mascota'**
  String get clientHomeRegisterPetAction;

  /// Subtítulo del panel administrativo
  ///
  /// In es, this message translates to:
  /// **'Resumen operativo del día'**
  String get adminDashboardSubtitle;

  /// Métrica de citas hoy
  ///
  /// In es, this message translates to:
  /// **'Citas hoy'**
  String get adminDashboardAppointmentsToday;

  /// Métrica de solicitudes pendientes
  ///
  /// In es, this message translates to:
  /// **'Solicitudes pendientes'**
  String get adminDashboardPendingRequests;

  /// Métrica de stock bajo
  ///
  /// In es, this message translates to:
  /// **'Productos con stock bajo'**
  String get adminDashboardLowStock;

  /// Métrica de ingresos del día
  ///
  /// In es, this message translates to:
  /// **'Ingresos del día'**
  String get adminDashboardTodayIncome;

  /// Título de tarjeta de próximas citas en dashboard
  ///
  /// In es, this message translates to:
  /// **'Próximas citas'**
  String get adminDashboardUpcomingAppointments;

  /// Título de tarjeta de actividad reciente en dashboard
  ///
  /// In es, this message translates to:
  /// **'Actividad reciente'**
  String get adminDashboardRecentActivity;

  /// Texto cuando no hay actividad reciente
  ///
  /// In es, this message translates to:
  /// **'Sin actividad reciente'**
  String get adminDashboardNoActivity;

  /// Cabecera de tabla Mascota
  ///
  /// In es, this message translates to:
  /// **'MASCOTA'**
  String get tableHeaderPet;

  /// Cabecera de tabla Servicio
  ///
  /// In es, this message translates to:
  /// **'SERVICIO'**
  String get tableHeaderService;

  /// Cabecera de tabla Fecha y Hora
  ///
  /// In es, this message translates to:
  /// **'FECHA Y HORA'**
  String get tableHeaderDateTime;

  /// Cabecera de tabla Estado
  ///
  /// In es, this message translates to:
  /// **'ESTADO'**
  String get tableHeaderState;

  /// Cabecera de tabla Acción
  ///
  /// In es, this message translates to:
  /// **'ACCIÓN'**
  String get tableHeaderAction;

  /// Cabecera de tabla Producto
  ///
  /// In es, this message translates to:
  /// **'PRODUCTO'**
  String get tableHeaderProduct;

  /// Cabecera de tabla Categoría
  ///
  /// In es, this message translates to:
  /// **'CATEGORÍA'**
  String get tableHeaderCategory;

  /// Cabecera de tabla Stock
  ///
  /// In es, this message translates to:
  /// **'STOCK'**
  String get tableHeaderStock;

  /// Cabecera de tabla Precio
  ///
  /// In es, this message translates to:
  /// **'PRECIO'**
  String get tableHeaderPrice;

  /// Cabecera de tabla Cliente
  ///
  /// In es, this message translates to:
  /// **'CLIENTE'**
  String get tableHeaderClient;

  /// Cabecera de tabla Hora
  ///
  /// In es, this message translates to:
  /// **'HORA'**
  String get tableHeaderHour;

  /// Cabecera de tabla Precio Base
  ///
  /// In es, this message translates to:
  /// **'PRECIO BASE'**
  String get tableHeaderBasePrice;

  /// Cabecera de tabla Duración
  ///
  /// In es, this message translates to:
  /// **'DURACIÓN'**
  String get tableHeaderDuration;

  /// Cabecera de tabla Tipo
  ///
  /// In es, this message translates to:
  /// **'TIPO'**
  String get tableHeaderType;

  /// Cabecera de tabla Rol
  ///
  /// In es, this message translates to:
  /// **'ROL'**
  String get tableHeaderRole;

  /// Cabecera de tabla Correo
  ///
  /// In es, this message translates to:
  /// **'CORREO'**
  String get tableHeaderEmail;

  /// Cabecera de tabla Teléfono
  ///
  /// In es, this message translates to:
  /// **'TELÉFONO'**
  String get tableHeaderPhone;

  /// Cabecera de tabla Nombre
  ///
  /// In es, this message translates to:
  /// **'NOMBRE'**
  String get tableHeaderName;

  /// Cabecera de tabla Número de documento
  ///
  /// In es, this message translates to:
  /// **'N.°'**
  String get tableHeaderNumber;

  /// Cabecera de tabla Total
  ///
  /// In es, this message translates to:
  /// **'TOTAL'**
  String get tableHeaderTotal;

  /// Aviso de la consulta clínica mientras adjuntar archivos y la foto de la mascota están desactivados
  ///
  /// In es, this message translates to:
  /// **'Por ahora no se pueden adjuntar archivos ni actualizar la foto de la mascota desde la consulta.'**
  String get clinicalUploadsContainedNotice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'es':
      {
        switch (locale.countryCode) {
          case '419':
            return AppLocalizationsEs419();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
