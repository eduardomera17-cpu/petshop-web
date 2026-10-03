// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: di.dart
// Propósito: Contenedor raíz de inyección de dependencias (DI) que provee servicios, repositorios y clientes de infraestructura al árbol de widgets de Flutter.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:mipetshop/app/bootstrap.dart';
import 'package:mipetshop/data/repositories/agenda_repository.dart';
import 'package:mipetshop/data/repositories/appointments_repository.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/repositories/chat_repository.dart';
import 'package:mipetshop/data/repositories/clinical_repository.dart';
import 'package:mipetshop/data/repositories/dashboard_repository.dart';
import 'package:mipetshop/data/repositories/governance_repository.dart';
import 'package:mipetshop/data/repositories/pets_repository.dart';
import 'package:mipetshop/data/repositories/product_requests_repository.dart';
import 'package:mipetshop/data/repositories/products_repository.dart';
import 'package:mipetshop/data/repositories/proformas_repository.dart';
import 'package:mipetshop/data/repositories/profile_repository.dart';
import 'package:mipetshop/data/services/firebase_auth_service.dart';
import 'package:mipetshop/data/services/functions_service.dart';
import 'package:mipetshop/data/services/recaptcha_service.dart';
import 'package:mipetshop/data/services/storage_service.dart';
import 'package:provider/provider.dart';

/// Contenedor de Inyección de Dependencias de la aplicación (TRD §1.2, §1.3.1).
///
/// Provee instancias compartidas de infraestructura, repositorios y servicios a todo
/// el árbol de widgets mediante [MultiProvider]. Permite sobreescribir cualquier
/// dependencia de forma opcional (por ejemplo, para el modo de demostración).
class AppDependencies extends StatelessWidget {
  /// Resultado del arranque preliminar que contiene los clientes oficiales de Firebase.
  final BootstrapResult bootstrapResult;

  /// Repositorio de autenticación y sesión de usuario.
  final AuthRepository? authRepository;

  /// Repositorio del perfil personal del cliente.
  final ProfileRepository? profileRepository;

  /// Repositorio de administración de mascotas.
  final PetsRepository? petsRepository;

  /// Repositorio del catálogo público de servicios.
  final CatalogRepository? catalogRepository;

  /// Repositorio de agendamiento y gestión de citas.
  final AppointmentsRepository? appointmentsRepository;

  /// Repositorio del catálogo e inventario comercial de productos.
  final ProductsRepository? productsRepository;

  /// Repositorio de solicitudes y pedidos de artículos de la tienda.
  final ProductRequestsRepository? productRequestsRepository;

  /// Repositorio de proformas, cotizaciones y cálculo de impuestos.
  final ProformasRepository? proformasRepository;

  /// Repositorio de mensajería y soporte en tiempo real.
  final ChatRepository? chatRepository;

  /// Repositorio de agenda global y turnos disponibles para el personal.
  final AgendaRepository? agendaRepository;

  /// Repositorio de métricas y analítica del panel administrativo.
  final DashboardRepository? dashboardRepository;

  /// Repositorio de historias clínicas y consultas veterinarias.
  final ClinicalRepository? clinicalRepository;

  /// Repositorio de gobernanza, parámetros del negocio y auditoría.
  final GovernanceRepository? governanceRepository;

  /// Servicio base de autenticación con Firebase Auth.
  final FirebaseAuthService? authService;

  /// Servicio de invocación de Cloud Functions transaccionales.
  final FunctionsService? functionsService;

  /// Servicio de validación contra bots mediante Google reCAPTCHA.
  final RecaptchaService? recaptchaService;

  /// Servicio de almacenamiento seguro en Firebase Storage.
  final StorageService? storageService;

  /// Widget raíz hijo que tendrá acceso a todos los proveedores del árbol.
  final Widget child;

  /// Constructor con parámetros requeridos y dependencias opcionales.
  const AppDependencies({
    super.key,
    required this.bootstrapResult,
    this.authRepository,
    this.profileRepository,
    this.petsRepository,
    this.catalogRepository,
    this.appointmentsRepository,
    this.productsRepository,
    this.productRequestsRepository,
    this.proformasRepository,
    this.chatRepository,
    this.agendaRepository,
    this.dashboardRepository,
    this.clinicalRepository,
    this.governanceRepository,
    this.authService,
    this.functionsService,
    this.recaptchaService,
    this.storageService,
    required this.child,
  });

  /// Construye el árbol de inyección mediante [MultiProvider], registrando cada
  /// servicio y repositorio para su consumo a través de `context.read<T>()` o `Provider.of<T>(context)`.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BootstrapResult>.value(value: bootstrapResult),
        Provider<FirebaseFirestore>.value(value: bootstrapResult.firestore),
        Provider<FirebaseAuthService>.value(
          value: authService ?? FirebaseAuthService(),
        ),
        Provider<FunctionsService>.value(
          value: functionsService ?? FunctionsService(),
        ),
        Provider<RecaptchaService>.value(
          value: recaptchaService ?? RecaptchaService(),
        ),
        Provider<StorageService>(
          create: (_) => storageService ?? StorageService(),
        ),
        Provider<ProfileRepository>(
          create: (_) =>
              profileRepository ??
              ProfileRepository(firestore: bootstrapResult.firestore),
        ),
        Provider<PetsRepository>(
          create: (_) =>
              petsRepository ??
              PetsRepository(
                firestore: bootstrapResult.firestore,
                functionsService: functionsService,
              ),
        ),
        Provider<CatalogRepository>(
          create: (_) =>
              catalogRepository ??
              CatalogRepository(firestore: bootstrapResult.firestore),
        ),
        Provider<AppointmentsRepository>(
          create: (_) =>
              appointmentsRepository ??
              AppointmentsRepository(
                firestore: bootstrapResult.firestore,
                functionsService: functionsService,
              ),
        ),
        Provider<ProductsRepository>(
          create: (_) =>
              productsRepository ??
              ProductsRepository(
                firestore: bootstrapResult.firestore,
                functionsService: functionsService,
              ),
        ),
        Provider<ProductRequestsRepository>(
          create: (_) =>
              productRequestsRepository ??
              ProductRequestsRepository(
                firestore: bootstrapResult.firestore,
                functionsService: functionsService,
              ),
        ),
        Provider<ProformasRepository>(
          create: (_) =>
              proformasRepository ??
              ProformasRepository(
                firestore: bootstrapResult.firestore,
                functionsService: functionsService,
                storageService: storageService ?? StorageService(),
              ),
        ),
        Provider<ChatRepository>(
          create: (_) =>
              chatRepository ??
              ChatRepository(
                firestore: bootstrapResult.firestore,
                functionsService: functionsService,
              ),
        ),
        Provider<AgendaRepository>(
          create: (_) =>
              agendaRepository ??
              AgendaRepository(
                firestore: bootstrapResult.firestore,
                functionsService: functionsService,
              ),
        ),
        Provider<DashboardRepository>(
          create: (_) =>
              dashboardRepository ??
              DashboardRepository(firestore: bootstrapResult.firestore),
        ),
        Provider<ClinicalRepository>(
          create: (_) =>
              clinicalRepository ??
              ClinicalRepository(
                firestore: bootstrapResult.firestore,
                functionsService: functionsService,
                storageService: storageService ?? StorageService(),
              ),
        ),
        Provider<GovernanceRepository>(
          create: (_) =>
              governanceRepository ??
              GovernanceRepository(
                firestore: bootstrapResult.firestore,
                functionsService: functionsService ?? FunctionsService(),
              ),
        ),
        if (authRepository != null)
          ChangeNotifierProvider<AuthRepository>.value(
            value: authRepository!,
          )
        else
          ChangeNotifierProvider<AuthRepository>(
            create: (_) =>
                AuthRepository(firestore: bootstrapResult.firestore),
          ),
      ],
      child: child,
    );
  }
}
