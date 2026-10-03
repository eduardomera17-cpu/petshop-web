// ignore_for_file: subtype_of_sealed_class, annotate_overrides, overridden_fields, unused_element
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/models/chat_message.dart';
import 'package:mipetshop/data/models/clinical_record.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/repositories/chat_repository.dart';
import 'package:mipetshop/domain/use_cases/preview_proforma_pricing.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/showcase/mock_data.dart';
import 'package:mipetshop/ui/core/admin_navigation_shell.dart';
import 'package:mipetshop/ui/core/client_navigation_shell.dart';
import 'package:mipetshop/ui/features/admin/agenda/view_models/admin_agenda_view_model.dart';
import 'package:mipetshop/ui/features/admin/agenda/views/admin_agenda_view.dart';
import 'package:mipetshop/ui/features/admin/clients/view_models/admin_clients_view_model.dart';
import 'package:mipetshop/ui/features/admin/clients/views/admin_clients_list_view.dart';
import 'package:mipetshop/ui/features/admin/clinical/view_models/clinical_consultation_view_model.dart';
import 'package:mipetshop/ui/features/admin/clinical/views/clinical_consultation_form_view.dart';
import 'package:mipetshop/ui/features/admin/dashboard/view_models/admin_dashboard_view_model.dart';
import 'package:mipetshop/ui/features/admin/dashboard/views/admin_dashboard_view.dart';
import 'package:mipetshop/ui/features/admin/governance/view_models/governance_view_model.dart';
import 'package:mipetshop/ui/features/admin/governance/views/admin_governance_view.dart';
import 'package:mipetshop/ui/features/admin/inventory/view_models/admin_inventory_view_model.dart';
import 'package:mipetshop/ui/features/admin/inventory/views/admin_inventory_view.dart';
import 'package:mipetshop/ui/features/admin/products/view_models/admin_products_view_model.dart';
import 'package:mipetshop/ui/features/admin/products/views/admin_products_list_view.dart';
import 'package:mipetshop/ui/features/admin/proformas/view_models/admin_proformas_view_model.dart';
import 'package:mipetshop/ui/features/admin/proformas/view_models/billing_config_view_model.dart';
import 'package:mipetshop/ui/features/admin/proformas/views/admin_proformas_list_view.dart';
import 'package:mipetshop/ui/features/admin/proformas/views/pending_concepts_view.dart';
import 'package:mipetshop/ui/features/admin/requests/view_models/admin_requests_view_model.dart';
import 'package:mipetshop/ui/features/admin/requests/views/admin_requests_view.dart';
import 'package:mipetshop/ui/features/admin/services/view_models/services_view_model.dart';
import 'package:mipetshop/ui/features/admin/services/views/services_list_view.dart';
import 'package:mipetshop/ui/features/appointments/view_models/booking_view_model.dart';
import 'package:mipetshop/ui/features/appointments/view_models/history_view_model.dart';
import 'package:mipetshop/ui/features/appointments/views/appointments_history_view.dart';
import 'package:mipetshop/ui/features/appointments/views/booking_flow_view.dart';
import 'package:mipetshop/ui/features/auth/views/change_password_view.dart';
import 'package:mipetshop/ui/features/auth/views/forgot_password_view.dart';
import 'package:mipetshop/ui/features/auth/views/login_view.dart';
import 'package:mipetshop/ui/features/auth/views/register_view.dart';
import 'package:mipetshop/ui/features/billing/view_models/cart_view_model.dart';
import 'package:mipetshop/ui/features/billing/view_models/my_proformas_view_model.dart';
import 'package:mipetshop/ui/features/billing/view_models/payment_summary_view_model.dart';
import 'package:mipetshop/ui/features/billing/views/cart_view.dart';
import 'package:mipetshop/ui/features/billing/views/my_proformas_view.dart';
import 'package:mipetshop/ui/features/billing/views/payment_summary_view.dart';
import 'package:mipetshop/ui/features/catalog/view_models/catalog_view_model.dart';
import 'package:mipetshop/ui/features/catalog/view_models/my_requests_view_model.dart';
import 'package:mipetshop/ui/features/catalog/views/catalog_view.dart';
import 'package:mipetshop/ui/features/catalog/views/my_requests_view.dart';
import 'package:mipetshop/ui/features/chat/view_models/chat_view_model.dart';
import 'package:mipetshop/ui/features/chat/view_models/staff_inbox_view_model.dart';
import 'package:mipetshop/ui/features/chat/views/chat_screen.dart';
import 'package:mipetshop/ui/features/chat/views/staff_inbox_screen.dart';
import 'package:mipetshop/ui/features/pets/view_models/pets_list_view_model.dart';
import 'package:mipetshop/ui/features/pets/views/pets_list_view.dart';
import 'package:mipetshop/ui/features/profile/view_models/profile_view_model.dart';
import 'package:mipetshop/ui/features/profile/views/profile_view.dart';

void main() {
  runApp(const ShowcaseApp());
}

class ShowcaseChatViewModel extends ChangeNotifier implements ChatViewModel {
  final ChatRepository chatRepository;
  final String chatId;
  final String currentUid;
  final String currentUserName;
  final String currentUserRole;

  ShowcaseChatViewModel({
    required this.chatRepository,
    required this.chatId,
    required this.currentUid,
    required this.currentUserName,
    required this.currentUserRole,
  }) {
    _messagesSub = chatRepository.streamMessages(chatId).listen((msgs) {
      _messages = msgs;
      _isLoading = false;
      notifyListeners();
    });
  }

  StreamSubscription<List<ChatMessageDto>>? _messagesSub;
  List<ChatMessageDto> _messages = [];
  bool _isLoading = false;

  @override
  List<ChatMessageDto> get messages => _messages;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isSending => false;

  @override
  bool get isUploadingImage => false;

  @override
  bool get isBlocked => false;

  @override
  bool get isPurging => false;

  @override
  Failure? get failure => null;

  @override
  Future<Uint8List?> imageBytes(String imagePath) async => null;

  Future<Result<String>> sendMessage(String text) async => const Ok('msg-ok');

  Future<Result<void>> purgeChat() async => const Ok(null);

  @override
  Future<bool> deleteMessage(String messageId) async => true;

  @override
  Future<bool> sendImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async =>
      true;

  @override
  void init() {}

  @override
  void dispose() {
    _messagesSub?.cancel();
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ClientHomeView extends StatelessWidget {
  const ClientHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shortcuts = [
      {'title': 'Mis Mascotas', 'subtitle': 'Registro e historial clínico', 'icon': Icons.pets, 'color': const Color(0xFF1B6E96)},
      {'title': 'Agendar Cita', 'subtitle': 'Consultas y servicios médicos', 'icon': Icons.calendar_month, 'color': const Color(0xFF2E7D32)},
      {'title': 'Historial de Citas', 'subtitle': 'Control de atenciones pasadas', 'icon': Icons.history, 'color': const Color(0xFF00838F)},
      {'title': 'Catálogo de Productos', 'subtitle': 'Alimentos, accesorios y farmacia', 'icon': Icons.storefront, 'color': const Color(0xFFE65100)},
      {'title': 'Mis Solicitudes', 'subtitle': 'Estado de retiro de pedidos', 'icon': Icons.assignment, 'color': const Color(0xFF6A1B9A)},
      {'title': 'Carrito de Compras', 'subtitle': 'Pre-facturación y conceptos', 'icon': Icons.shopping_cart, 'color': const Color(0xFFC2185B)},
      {'title': 'Mis Proformas', 'subtitle': 'Comprobantes emitidos y facturación', 'icon': Icons.receipt_long, 'color': const Color(0xFF4527A0)},
      {'title': 'Chat de Soporte', 'subtitle': 'Atención veterinaria directa', 'icon': Icons.forum, 'color': const Color(0xFF00695C)},
      {'title': 'Mi Perfil', 'subtitle': 'Datos personales y contacto', 'icon': Icons.person, 'color': const Color(0xFF37474F)},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.navHome ?? 'PetShop - Inicio'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 8.0),
                Text('Cliente Demo E.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Color(0xFF1B6E96),
                            child: Icon(Icons.pets, size: 32, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¡Bienvenido a PetShop, Cliente Demo!',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1B6E96),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Sistema Integral de Gestión Veterinaria y Cuidado de Mascotas. Selecciona un módulo para comenzar:',
                                  style: TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Módulos de Servicio al Cliente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: shortcuts.length,
                    itemBuilder: (context, index) {
                      final item = shortcuts[index];
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: (item['color'] as Color).withValues(alpha: 0.15),
                                child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['subtitle'] as String,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  static Widget buildScreen(String key) {
    switch (key) {
      // ──────────────────────────────────────────────
      // 1. Módulos de Autenticación
      // ──────────────────────────────────────────────
      case '01_Cliente_Inicio_Sesion':
        return const LoginView();
      case '02_Cliente_Registro':
        return const RegisterView();
      case '03_Cliente_Recuperar_Contrasena':
        return const ForgotPasswordView();
      case '04_Cliente_Cambiar_Contrasena':
        return const ChangePasswordView();

      // ──────────────────────────────────────────────
      // 2. Módulos de Cliente
      // ──────────────────────────────────────────────
      case '05_Cliente_Home_Principal':
        return const ClientNavigationShell(
          location: '/',
          role: 'CLIENT',
          child: ClientHomeView(),
        );

      case '06_Cliente_Mis_Mascotas':
        return ClientNavigationShell(
          location: '/pets',
          role: 'CLIENT',
          child: PetsListView(
            viewModel: PetsListViewModel(repository: ShowcasePetsRepo()),
            ownerId: kClientProfile.uid,
          ),
        );

      case '07_Cliente_Agendamiento_Cita':
        return ClientNavigationShell(
          location: '/appointments',
          role: 'CLIENT',
          child: BookingFlowView(
            viewModel: BookingViewModel(
              appointmentsRepository: ShowcaseAppointmentsRepo(),
              catalogRepository: ShowcaseCatalogRepo(),
              petsRepository: ShowcasePetsRepo(),
              ownerId: kClientProfile.uid,
            ),
          ),
        );

      case '08_Cliente_Historial_Citas':
        return ClientNavigationShell(
          location: '/appointments',
          role: 'CLIENT',
          child: AppointmentsHistoryView(
            viewModel: HistoryViewModel(
              repository: ShowcaseAppointmentsRepo(),
              clientId: kClientProfile.uid,
            ),
            onNavigateToBooking: () {},
          ),
        );

      case '09_Cliente_Catalogo_Productos':
        return ClientNavigationShell(
          location: '/catalog',
          role: 'CLIENT',
          child: CatalogView(
            viewModel: CatalogViewModel(
              productsRepository: ShowcaseProductsRepo(),
              catalogRepository: ShowcaseCatalogRepo(),
            ),
            currentUid: kClientProfile.uid,
            onNavigateToRequests: () {},
          ),
        );

      case '10_Cliente_Solicitud_Producto':
        return ClientNavigationShell(
          location: '/catalog',
          role: 'CLIENT',
          child: MyRequestsView(
            viewModel: MyRequestsViewModel(
              repository: ShowcaseProductRequestsRepo(),
              catalogRepository: ShowcaseCatalogRepo(),
              clientId: kClientProfile.uid,
            ),
          ),
        );

      case '11_Cliente_Carrito_Compras':
        return ClientNavigationShell(
          location: '/billing/cart',
          role: 'CLIENT',
          child: CartView(
            viewModel: CartViewModel(
              productRequestsRepository: ShowcaseProductRequestsRepo(),
              appointmentsRepository: ShowcaseAppointmentsRepo(),
              catalogRepository: ShowcaseCatalogRepo(),
              clientId: kClientProfile.uid,
            ),
          ),
        );

      case '12_Cliente_Resumen_Pago':
        return ClientNavigationShell(
          location: '/billing/summary',
          role: 'CLIENT',
          child: PaymentSummaryView(
            viewModel: PaymentSummaryViewModel(
              productRequestsRepository: ShowcaseProductRequestsRepo(),
              appointmentsRepository: ShowcaseAppointmentsRepo(),
              catalogRepository: ShowcaseCatalogRepo(),
              clientId: kClientProfile.uid,
            ),
          ),
        );

      case '13_Cliente_Mis_Proformas':
        return ClientNavigationShell(
          location: '/billing',
          role: 'CLIENT',
          child: MyProformasView(
            viewModel: MyProformasViewModel(
              repository: ShowcaseProformasRepo(),
              clientId: kClientProfile.uid,
            ),
            onOpenCart: () {},
            onOpenPaymentSummary: () {},
          ),
        );

      case '14_Cliente_Chat_Soporte':
        return ClientNavigationShell(
          location: '/chat',
          role: 'CLIENT',
          child: ChatScreen(
            viewModel: ShowcaseChatViewModel(
              chatRepository: ShowcaseChatRepo(),
              chatId: kClientProfile.uid,
              currentUid: kClientProfile.uid,
              currentUserName: kClientProfile.fullName,
              currentUserRole: 'CLIENT',
            ),
          ),
        );

      case '15_Cliente_Perfil':
        return ClientNavigationShell(
          location: '/profile',
          role: 'CLIENT',
          child: ProfileView(
            viewModel: ProfileViewModel(repository: ShowcaseProfileRepo())
              ..loadProfile(kClientProfile.uid),
            title: 'Mi Perfil de Usuario',
          ),
        );

      // ──────────────────────────────────────────────
      // 3. Módulos de Administrador
      // ──────────────────────────────────────────────
      case '16_Admin_Dashboard_General':
        return AdminNavigationShell(
          location: '/admin',
          role: 'SUPERADMIN',
          onSignOut: () async {},
          child: AdminDashboardView(
            viewModel: AdminDashboardViewModel(
              dashboardRepository: ShowcaseDashboardRepo(),
            ),
          ),
        );

      case '17_Admin_Agenda_Citas':
        return AdminNavigationShell(
          location: '/admin/agenda',
          role: 'SUPERADMIN',
          onSignOut: () async {},
          child: AdminAgendaView(
            viewModel: AdminAgendaViewModel(
              agendaRepository: ShowcaseAgendaRepo(),
            ),
          ),
        );

      case '18_Admin_Atencion_Clinica':
        final clinicalVm = ClinicalConsultationViewModel(
          clinicalRepository: ShowcaseClinicalRepo(),
          petId: kPet1.id,
          ownerId: kClientProfile.uid,
          patientSnapshot: PatientSnapshot(
            pet: PatientPetSnapshot(
              name: kPet1.name,
              species: kPet1.species,
              breed: kPet1.breed ?? 'Labrador Retriever',
              sex: kPet1.sex,
              reproductiveStatus: kPet1.reproductiveStatus,
              birthDate: kPet1.birthDate ?? '2023-03-15',
              ageAtAttention: '3 años 6 meses',
            ),
            owner: PatientOwnerSnapshot(
              fullName: kClientProfile.fullName,
              documentType: kClientProfile.documentType,
              documentNumber: kClientProfile.documentNumber,
              phone: kClientProfile.phone,
              address: kClientProfile.address,
              email: kClientProfile.email,
            ),
          ),
          currentStaffUid: kStaffProfile.uid,
          currentStaffName: kStaffProfile.fullName,
          currentStaffRole: 'SUPERADMIN',
        );
        clinicalVm.reason = 'Control general anual y evaluación dermatológica';
        clinicalVm.currentIllness =
            'Paciente presenta prurito leve en zona auricular posterior sin lesiones dérmicas evidentes.';
        clinicalVm.temperatureDeciC = 385;
        clinicalVm.heartRateBpm = 95;
        clinicalVm.respiratoryRateRpm = 24;
        clinicalVm.weightGrams = 28500;
        clinicalVm.bodyConditionScore = 5;
        clinicalVm.diagnosis =
            'Dermatitis atópica estacional en remisión / Estado general óptimo';
        clinicalVm.diagnosisType = 'DEFINITIVE';
        clinicalVm.ownerInstructions =
            'Mantener dieta hipoalergénica, aplicar champú neutro y control en 3 meses.';

        return AdminNavigationShell(
          location: '/admin/clinical',
          role: 'SUPERADMIN',
          onSignOut: () async {},
          child: ClinicalConsultationFormView(
            viewModel: clinicalVm,
            onSaved: () {},
            onCancel: () {},
          ),
        );

      case '19_Admin_Servicios_Veterinarios':
        return AdminNavigationShell(
          location: '/admin/services',
          role: 'SUPERADMIN',
          onSignOut: () async {},
          child: ServicesListView(
            viewModel: ServicesViewModel(
              repository: ShowcaseCatalogRepo(),
            ),
            currentUid: kStaffProfile.uid,
          ),
        );

      case '20_Admin_Catalogo_Productos':
        return AdminNavigationShell(
          location: '/admin/products',
          role: 'SUPERADMIN',
          onSignOut: () async {},
          child: AdminProductsListView(
            viewModel: AdminProductsViewModel(
              productsRepository: ShowcaseProductsRepo(),
            ),
            currentUid: kStaffProfile.uid,
          ),
        );

      case '21_Admin_Inventario_Stock':
        return AdminNavigationShell(
          location: '/admin/inventory',
          role: 'SUPERADMIN',
          onSignOut: () async {},
          child: AdminInventoryView(
            viewModel: AdminInventoryViewModel(
              productsRepository: ShowcaseProductsRepo(),
            ),
          ),
        );

      case '22_Admin_Solicitudes_Pedidos':
        return AdminNavigationShell(
          location: '/admin/requests',
          role: 'SUPERADMIN',
          onSignOut: () async {},
          child: AdminRequestsView(
            viewModel: AdminRequestsViewModel(
              requestsRepository: ShowcaseProductRequestsRepo(),
            ),
          ),
        );

      case '23_Admin_Proformas_Facturacion':
        return AdminNavigationShell(
          location: '/admin/proformas',
          role: 'SUPERADMIN',
          onSignOut: () async {},
          child: AdminProformasListView(
            viewModel: AdminProformasViewModel(
              proformasRepository: ShowcaseProformasRepo(),
            ),
            billingConfigViewModel: BillingConfigViewModel(
              proformasRepository: ShowcaseProformasRepo(),
            ),
            currentUid: kStaffProfile.uid,
            previewUseCase: const PreviewProformaPricingUseCase(),
            pricingConfig: const PublicPricingConfig(
              ivaBp: 1500,
              iceIncludedInIvaBase: true,
            ),
            proformasRepository: ShowcaseProformasRepo(),
            clientsStream: (query) => Stream.value(const [
              ProformaClientOption(
                uid: 'client-demo-01',
                fullName: 'Cliente Demo Ejemplo',
                email: 'cliente.demo@example.com',
              ),
            ]),
          ),
        );

      case '24_Admin_Directorio_Clientes':
        return AdminNavigationShell(
          location: '/admin/clients',
          role: 'SUPERADMIN',
          onSignOut: () async {},
          child: AdminClientsListView(
            viewModel: AdminClientsViewModel(
              agendaRepository: ShowcaseAgendaRepo(),
            ),
            staffUid: kStaffProfile.uid,
          ),
        );

      case '25_Admin_Bandeja_Chat_Staff':
        return AdminNavigationShell(
          location: '/admin/chat',
          role: 'SUPERADMIN',
          onSignOut: () async {},
          child: StaffInboxScreen(
            viewModel: StaffInboxViewModel(
              chatRepository: ShowcaseChatRepo(),
              currentStaffUid: kStaffProfile.uid,
              currentStaffName: kStaffProfile.fullName,
              currentStaffRole: 'SUPERADMIN',
            ),
          ),
        );

      case '26_Admin_Gobernanza_Auditoria':
        return AdminNavigationShell(
          location: '/admin/governance',
          role: 'SUPERADMIN',
          onSignOut: () async {},
          child: AdminGovernanceView(
            viewModel: GovernanceViewModel(
              repository: ShowcaseGovernanceRepo(),
            ),
          ),
        );

      case '27_Admin_Perfil_Personal':
        return AdminNavigationShell(
          location: '/admin/profile',
          role: 'SUPERADMIN',
          onSignOut: () async {},
          child: ProfileView(
            viewModel: ProfileViewModel(repository: ShowcaseProfileRepo())
              ..loadProfile(kStaffProfile.uid),
            showDeactivation: false,
            title: 'Perfil Administrativo - Superadmin',
          ),
        );

      default:
        return const LoginView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenKey =
        Uri.base.queryParameters['screen'] ?? '01_Cliente_Inicio_Sesion';

    return MaterialApp(
      title: 'PetShop Tesis Showcase',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', '419'),
      supportedLocales: const [
        Locale('es', '419'),
        Locale('es'),
      ],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B6E96),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B6E96),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: buildScreen(screenKey),
    );
  }
}
