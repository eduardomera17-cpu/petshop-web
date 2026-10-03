// ignore_for_file: subtype_of_sealed_class, annotate_overrides, overridden_fields
import 'dart:async';
import 'dart:typed_data';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/models/chat.dart';
import 'package:mipetshop/data/models/chat_message.dart';
import 'package:mipetshop/data/models/clinical_record.dart';
import 'package:mipetshop/data/repositories/agenda_repository.dart';
import 'package:mipetshop/data/repositories/appointments_repository.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/repositories/chat_repository.dart';
import 'package:mipetshop/data/repositories/clinical_repository.dart';
import 'package:mipetshop/data/repositories/dashboard_repository.dart';
import 'package:mipetshop/data/repositories/governance_repository.dart';
import 'package:mipetshop/data/repositories/pets_repository.dart';
import 'package:mipetshop/data/repositories/product_requests_repository.dart';
import 'package:mipetshop/data/repositories/products_repository.dart';
import 'package:mipetshop/data/repositories/profile_repository.dart';
import 'package:mipetshop/data/repositories/proformas_repository.dart';
import 'package:mipetshop/domain/models/appointment.dart';
import 'package:mipetshop/domain/models/audit_log_entry.dart';
import 'package:mipetshop/domain/models/billing_parameters.dart';
import 'package:mipetshop/domain/models/operating_parameters.dart';
import 'package:mipetshop/domain/models/pet.dart';
import 'package:mipetshop/domain/models/product.dart';
import 'package:mipetshop/domain/models/product_request.dart';
import 'package:mipetshop/domain/models/proforma.dart';
import 'package:mipetshop/domain/models/service.dart';
import 'package:mipetshop/domain/models/user_profile.dart';

abstract class FakeRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const kClientProfile = UserProfile(
  uid: 'client-demo-01',
  email: 'cliente.demo@example.com',
  fullName: 'Cliente Demo Ejemplo',
  searchName: 'cliente demo ejemplo',
  phone: '+593 99 000 0001',
  documentType: 'CEDULA',
  documentNumber: '0000000001',
  address: 'Calle Ejemplo 123, Ciudad Demo',
  role: 'CLIENT',
  status: 'ACTIVE',
);

const kStaffProfile = UserProfile(
  uid: 'staff-super-01',
  email: 'admin.demo@example.com',
  fullName: 'Administrador Demo (Superadmin)',
  searchName: 'administrador demo',
  phone: '+593 99 000 0001',
  documentType: 'CEDULA',
  documentNumber: '0000000001',
  address: 'Clínica Veterinaria PetShop Demo, Ciudad Demo',
  role: 'SUPERADMIN',
  status: 'ACTIVE',
);

const kPet1 = Pet(
  id: 'pet-max-01',
  ownerId: 'client-demo-01',
  name: 'Max',
  searchName: 'max',
  species: 'CANINE',
  sex: 'MALE',
  reproductiveStatus: 'INTACT',
  breed: 'Labrador Retriever',
  birthDate: '2023-03-15',
  allergies: 'Ninguna conocida',
  status: 'ACTIVE',
);

const kPet2 = Pet(
  id: 'pet-luna-02',
  ownerId: 'client-demo-01',
  name: 'Luna',
  searchName: 'luna',
  species: 'FELINE',
  sex: 'FEMALE',
  reproductiveStatus: 'NEUTERED',
  breed: 'Siamés',
  birthDate: '2024-01-10',
  allergies: 'Sensibilidad a champús con sulfatos',
  status: 'ACTIVE',
);

const kService1 = Service(
  id: 'srv-001',
  name: 'Consulta Veterinaria General',
  searchName: 'consulta veterinaria general',
  description: 'Evaluación física completa, constantes fisiológicas y diagnóstico preventivo.',
  basePriceCents: 2000,
  iceBp: 0,
  isClinical: true,
  estimatedDurationMinutes: 30,
  isActive: true,
);

const kService2 = Service(
  id: 'srv-002',
  name: 'Vacunación Séxtuple Canina',
  searchName: 'vacunacion sextuple canina',
  description: 'Inmunización contra parvovirus, moquillo, hepatitis, leptospira y adenovirus.',
  basePriceCents: 2500,
  iceBp: 0,
  isClinical: true,
  estimatedDurationMinutes: 20,
  isActive: true,
);

const kService3 = Service(
  id: 'srv-003',
  name: 'Peluquería y Baño Completo',
  searchName: 'peluqueria y bano completo',
  description: 'Baño dermocosmético, corte de pelo estilizado, corte de uñas y limpieza ótica.',
  basePriceCents: 1800,
  iceBp: 0,
  isClinical: false,
  estimatedDurationMinutes: 45,
  isActive: true,
);

const kService4 = Service(
  id: 'srv-004',
  name: 'Profilaxis Dental Ultrasónica',
  searchName: 'profilaxis dental ultrasonica',
  description: 'Eliminación profunda de sarro y pulido dental con ultrasonido.',
  basePriceCents: 3500,
  iceBp: 0,
  isClinical: true,
  estimatedDurationMinutes: 60,
  isActive: true,
);

const kProduct1 = Product(
  id: 'prod-001',
  name: 'Croquetas ProPlan Adulto 15kg',
  searchName: 'croquetas proplan adulto 15kg',
  description: 'Alimento de alta gama con proteína de pollo para perros medianos y grandes.',
  category: 'Alimentos',
  basePriceCents: 6500,
  iceBp: 0,
  stock: 18,
  isActive: true,
);

const kProduct2 = Product(
  id: 'prod-002',
  name: 'Shampoo Hipoalergénico 500ml',
  searchName: 'shampoo hipoalergenico 500ml',
  description: 'Limpieza suave con extracto de avena para mascotas de piel reactiva.',
  category: 'Higiene',
  basePriceCents: 1450,
  iceBp: 0,
  stock: 12,
  isActive: true,
);

const kProduct3 = Product(
  id: 'prod-003',
  name: 'Pipeta Antipulgas Bravecto 20-40kg',
  searchName: 'pipeta antipulgas bravecto 20-40kg',
  description: 'Tratamiento sistémico oral/tópico de hasta 12 semanas contra parásitos.',
  category: 'Farmacia',
  basePriceCents: 2800,
  iceBp: 0,
  stock: 4,
  isActive: true,
);

const kProduct4 = Product(
  id: 'prod-004',
  name: 'Collar Antiparasitario Seresto',
  searchName: 'collar antiparasitario seresto',
  description: 'Collar repelente con liberación prolongada de principios activos hasta por 8 meses.',
  category: 'Farmacia',
  basePriceCents: 3800,
  iceBp: 0,
  stock: 8,
  isActive: true,
);

const kProduct5 = Product(
  id: 'prod-005',
  name: 'Snacks Dentales Pedigree Dentastix',
  searchName: 'snacks dentales pedigree dentastix',
  description: 'Barritas masticables para el control del sarro y aliento fresco.',
  category: 'Snacks',
  basePriceCents: 650,
  iceBp: 0,
  stock: 25,
  isActive: true,
);

const kProduct6 = Product(
  id: 'prod-006',
  name: 'Arnés Ergonómico Reflectivo Talla M',
  searchName: 'arnes ergonomico reflectivo talla m',
  description: 'Pechera de nailon reforzado con bandas de alta visibilidad nocturna.',
  category: 'Accesorios',
  basePriceCents: 1600,
  iceBp: 0,
  stock: 7,
  isActive: true,
);

const kAppt1 = Appointment(
  id: 'appt-001',
  clientId: 'client-demo-01',
  clientName: 'Cliente Demo Ejemplo',
  petId: 'pet-max-01',
  petName: 'Max',
  serviceId: 'srv-001',
  serviceName: 'Consulta Veterinaria General',
  isClinical: true,
  dateString: '2026-09-22',
  timeSlot: '10:00 - 10:30',
  slotKey: '2026-09-22_10:00',
  petDayKey: 'pet-max-01_2026-09-22',
  actionDateString: '2026-09-22',
  status: 'CONFIRMED',
  basePriceCents: 2000,
  iceBp: 0,
  ivaBp: 1500,
  iceAmountCents: 0,
  ivaAmountCents: 300,
  finalPriceCents: 2300,
  clientNotes: 'Control de rutina y chequeo preventivo semestral.',
);

const kAppt2 = Appointment(
  id: 'appt-002',
  clientId: 'client-demo-01',
  clientName: 'Cliente Demo Ejemplo',
  petId: 'pet-luna-02',
  petName: 'Luna',
  serviceId: 'srv-002',
  serviceName: 'Vacunación Séxtuple Canina',
  isClinical: true,
  dateString: '2026-09-22',
  timeSlot: '14:00 - 14:30',
  slotKey: '2026-09-22_14:00',
  petDayKey: 'pet-luna-02_2026-09-22',
  actionDateString: '2026-09-22',
  status: 'PENDING',
  basePriceCents: 2500,
  iceBp: 0,
  ivaBp: 1500,
  iceAmountCents: 0,
  ivaAmountCents: 375,
  finalPriceCents: 2875,
  clientNotes: 'Refuerzo anual de inmunización.',
);

const kAppt3 = Appointment(
  id: 'appt-003',
  clientId: 'client-demo-01',
  clientName: 'Cliente Demo Ejemplo',
  petId: 'pet-max-01',
  petName: 'Max',
  serviceId: 'srv-003',
  serviceName: 'Peluquería y Baño Completo',
  isClinical: false,
  dateString: '2026-09-18',
  timeSlot: '11:00 - 11:45',
  slotKey: '2026-09-18_11:00',
  petDayKey: 'pet-max-01_2026-09-18',
  actionDateString: '2026-09-18',
  status: 'COMPLETED',
  basePriceCents: 1800,
  iceBp: 0,
  ivaBp: 1500,
  iceAmountCents: 0,
  ivaAmountCents: 270,
  finalPriceCents: 2070,
  isBilled: true,
  proformaId: 'prof-001',
);

// Mocks implementations
class ShowcaseProfileRepo extends FakeRepo implements ProfileRepository {
  @override
  Future<Result<UserProfile>> getUserProfile(String uid) async =>
      Ok(uid.contains('staff') ? kStaffProfile : kClientProfile);

  @override
  Stream<UserProfile?> profileStream(String uid) =>
      Stream.value(uid.contains('staff') ? kStaffProfile : kClientProfile);

  @override
  Future<Result<Uint8List?>> getPhotoBytes(String? storagePath) async =>
      const Ok(null);

  @override
  Future<Result<void>> updateUserProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String documentType,
    required String documentNumber,
    required String address,
  }) async =>
      const Ok(null);
}

class ShowcasePetsRepo extends FakeRepo implements PetsRepository {
  final List<Pet> _pets = [kPet1, kPet2];

  @override
  Future<Result<List<Pet>>> getPets(String ownerId) async => Ok(_pets);

  @override
  Stream<List<Pet>> streamPets(String ownerId) => Stream.value(_pets);

  @override
  Future<Result<Pet>> getPetById(String petId) async =>
      Ok(_pets.firstWhere((p) => p.id == petId, orElse: () => kPet1));

  @override
  Future<Result<Uint8List?>> getPhotoBytes(String? storagePath) async =>
      const Ok(null);
}

class ShowcaseCatalogRepo extends FakeRepo implements CatalogRepository {
  final List<Service> _services = [kService1, kService2, kService3, kService4];

  @override
  Future<Result<List<Service>>> getServices({bool onlyActive = false}) async =>
      Ok(_services);

  @override
  Stream<List<Service>> streamServices({bool onlyActive = false}) =>
      Stream.value(_services);

  @override
  Future<Result<PublicPricingConfig>> getPublicPricing() async =>
      const Ok(PublicPricingConfig(ivaBp: 1500, iceIncludedInIvaBase: true));

  @override
  Stream<PublicPricingConfig> streamPublicPricing() =>
      Stream.value(const PublicPricingConfig(ivaBp: 1500, iceIncludedInIvaBase: true));
}

class ShowcaseAppointmentsRepo extends FakeRepo implements AppointmentsRepository {
  final List<Appointment> _appts = [kAppt1, kAppt2, kAppt3];

  @override
  Stream<List<Appointment>> streamClientAppointments(String clientId) =>
      Stream.value(_appts);

  @override
  Stream<List<Appointment>> streamCartAppointments(String clientId) =>
      Stream.value(_appts.where((a) => !a.isBilled).toList());

  @override
  Stream<Set<String>> streamSlotLocks() => Stream.value(const {});

  @override
  Stream<Set<String>> streamAvailabilityBlocks() => Stream.value(const {});

  @override
  Stream<PublicOperatingConfig> streamOperatingConfig() => Stream.value(
        const PublicOperatingConfig(
          timezone: 'America/Guayaquil',
          openingTime: '08:00',
          closingTime: '18:00',
          slotDurationMinutes: 30,
          workingWeekdays: [1, 2, 3, 4, 5, 6],
        ),
      );

  @override
  Stream<PublicPricingConfig> streamPricingConfig() => Stream.value(
        const PublicPricingConfig(ivaBp: 1500, iceIncludedInIvaBase: true),
      );

  @override
  Future<Result<String>> createAppointment({
    required String petId,
    required String serviceId,
    required String dateString,
    required String timeSlot,
    String? clientNotes,
    String? requestId,
  }) async =>
      const Ok('appt-new-001');
}

class ShowcaseProductsRepo extends FakeRepo implements ProductsRepository {
  final List<Product> _products = [
    kProduct1,
    kProduct2,
    kProduct3,
    kProduct4,
    kProduct5,
    kProduct6,
  ];

  @override
  Stream<List<Product>> streamAllProducts() => Stream.value(_products);

  @override
  Stream<List<Product>> streamActiveProducts({String? category}) => Stream.value(
        category == null
            ? _products
            : _products.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList(),
      );

  @override
  Stream<int> streamLowStockThreshold() => Stream.value(5);

  @override
  Future<Result<int>> getLowStockThreshold() async => const Ok(5);
}

class ShowcaseProductRequestsRepo extends FakeRepo implements ProductRequestsRepository {
  final List<ProductRequest> _requests = [
    const ProductRequest(
      id: 'req-001',
      clientId: 'client-demo-01',
      clientName: 'Cliente Demo Ejemplo',
      items: [
        ProductRequestLine(
          productId: 'prod-003',
          productName: 'Pipeta Antipulgas Bravecto 20-40kg',
          quantity: 1,
          agreedUnitPriceCents: 2800,
          iceBp: 0,
          ivaBp: 1500,
        ),
      ],
      status: 'READY_FOR_PICKUP',
      actionDateString: '2026-09-22',
    ),
    const ProductRequest(
      id: 'req-002',
      clientId: 'client-demo-01',
      clientName: 'Cliente Demo Ejemplo',
      items: [
        ProductRequestLine(
          productId: 'prod-001',
          productName: 'Croquetas ProPlan Adulto 15kg',
          quantity: 1,
          agreedUnitPriceCents: 6500,
          iceBp: 0,
          ivaBp: 1500,
        ),
      ],
      status: 'PENDING_DISPATCH',
      actionDateString: '2026-09-21',
    ),
  ];

  @override
  Stream<List<ProductRequest>> streamMyRequests(String clientId) =>
      Stream.value(_requests);

  @override
  Stream<List<ProductRequest>> streamAdminRequests({String? status}) =>
      Stream.value(status == null ? _requests : _requests.where((r) => r.status == status).toList());
}

class ShowcaseProformasRepo extends FakeRepo implements ProformasRepository {
  final List<Proforma> _proformas = [
    Proforma(
      id: 'prof-001',
      clientId: 'client-demo-01',
      clientName: 'Cliente Demo Ejemplo',
      status: 'DELIVERED',
      issuedAt: DateTime.now().subtract(const Duration(hours: 2)),
      subtotalCents: 4800,
      ivaTotalCents: 720,
      iceTotalCents: 0,
      totalCents: 5520,
      items: const [
        ProformaItem(
          type: 'SERVICE',
          referenceId: 'appt-001',
          title: 'Consulta Veterinaria General - Max',
          basePriceCents: 2000,
          quantity: 1,
          subtotalCents: 2000,
          iceBp: 0,
          iceAmountCents: 0,
          ivaBp: 1500,
          ivaAmountCents: 300,
          totalCents: 2300,
        ),
        ProformaItem(
          type: 'PRODUCT',
          referenceId: 'prod-003',
          title: 'Pipeta Antipulgas Bravecto 20-40kg',
          basePriceCents: 2800,
          quantity: 1,
          subtotalCents: 2800,
          iceBp: 0,
          iceAmountCents: 0,
          ivaBp: 1500,
          ivaAmountCents: 420,
          totalCents: 3220,
        ),
      ],
    ),
    Proforma(
      id: 'prof-002',
      clientId: 'client-demo-01',
      clientName: 'Cliente Demo Ejemplo',
      status: 'FINALIZED',
      issuedAt: DateTime.now().subtract(const Duration(days: 4)),
      subtotalCents: 2450,
      ivaTotalCents: 368,
      iceTotalCents: 0,
      totalCents: 2818,
      items: const [
        ProformaItem(
          type: 'SERVICE',
          referenceId: 'appt-003',
          title: 'Peluquería y Baño Completo - Max',
          basePriceCents: 1800,
          quantity: 1,
          subtotalCents: 1800,
          iceBp: 0,
          iceAmountCents: 0,
          ivaBp: 1500,
          ivaAmountCents: 270,
          totalCents: 2070,
        ),
        ProformaItem(
          type: 'PRODUCT',
          referenceId: 'prod-005',
          title: 'Snacks Dentales Pedigree Dentastix',
          basePriceCents: 650,
          quantity: 1,
          subtotalCents: 650,
          iceBp: 0,
          iceAmountCents: 0,
          ivaBp: 1500,
          ivaAmountCents: 98,
          totalCents: 748,
        ),
      ],
    ),
  ];

  @override
  Stream<List<Proforma>> streamClientProformas(String clientId) =>
      Stream.value(_proformas);

  @override
  Stream<List<Proforma>> streamAdminProformas({String? status}) =>
      Stream.value(status == null ? _proformas : _proformas.where((p) => p.status == status).toList());

  @override
  Stream<BillingParameters> streamBillingParameters() => Stream.value(
        const BillingParameters(
          businessName: 'PetShop Demo',
          taxId: '0000000000001',
          address: 'Calle Ejemplo 123, Ciudad Demo',
          phone: '+593 99 000 0001',
          proformaSeries: '001-001',
          ivaBp: 1500,
          iceIncludedInIvaBase: true,
        ),
      );
}

class ShowcaseChatRepo extends FakeRepo implements ChatRepository {
  final List<ChatMessageDto> _messages = [
    ChatMessageDto(
      id: 'msg-01',
      senderUid: 'client-demo-01',
      senderName: 'Cliente Demo Ejemplo',
      senderRole: 'CLIENT',
      text: '¡Buenos días! Quisiera confirmar si hoy tienen disponible la pipeta Bravecto para perros de 25 kg.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ChatMessageDto(
      id: 'msg-02',
      senderUid: 'staff-super-01',
      senderName: 'Dra. Veterinaria Demo - PetShop',
      senderRole: 'VET',
      text: '¡Hola Cliente! Sí, disponemos de stock en clínica. Se la dejamos reservada para retirarla junto con la consulta de Max a las 10:00.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
    ),
    ChatMessageDto(
      id: 'msg-03',
      senderUid: 'client-demo-01',
      senderName: 'Cliente Demo Ejemplo',
      senderRole: 'CLIENT',
      text: 'Excelente, muchísimas gracias. Allá estaremos puntuales con Max.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
    ),
    ChatMessageDto(
      id: 'msg-04',
      senderUid: 'staff-super-01',
      senderName: 'Recepción PetShop',
      senderRole: 'ADMIN',
      text: '¡Perfecto! Los esperamos en sala de atención 1.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
    ),
  ];

  final List<ChatDto> _staffChats = [
    ChatDto(
      id: 'chat-client-01',
      type: 'CLIENT_STAFF',
      clientId: 'client-demo-01',
      clientName: 'Cliente Demo Ejemplo',
      isArchived: false,
      lastMessageText: '¡Perfecto! Los esperamos en sala de atención 1.',
      lastMessageTimestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isBlocked: false,
    ),
    ChatDto(
      id: 'chat-client-02',
      type: 'CLIENT_STAFF',
      clientId: 'client-02',
      clientName: 'Cliente Dos Demo',
      isArchived: false,
      lastMessageText: '¿A qué hora abre la peluquería canina?',
      lastMessageTimestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isBlocked: false,
    ),
  ];

  @override
  Stream<List<ChatMessageDto>> streamMessages(String chatId, {int limit = 50}) =>
      Stream.value(_messages);

  @override
  Stream<ChatDto?> streamChat(String chatId) =>
      Stream.value(_staffChats.first);

  @override
  Stream<List<ChatDto>> streamStaffChats({bool includeArchived = false}) =>
      Stream.value(_staffChats);

  @override
  Future<Result<String>> sendMessage({
    required String chatId,
    required String senderUid,
    required String senderName,
    required String senderRole,
    String? text,
    String? imagePath,
  }) async =>
      const Ok('msg-new');
}

class ShowcaseAgendaRepo extends FakeRepo implements AgendaRepository {
  final List<Appointment> _agendaAppts = [kAppt1, kAppt2];

  @override
  Stream<List<Appointment>> streamAppointments({
    String? status,
    String? serviceId,
    String? dateString,
  }) =>
      Stream.value(_agendaAppts);

  @override
  Stream<List<AvailabilityBlock>> streamAvailabilityBlocks() =>
      Stream.value(const [
        AvailabilityBlock(
          id: 'block-01',
          dateString: '2026-09-22',
          timeSlot: '13:00 - 14:00',
          reason: 'Almuerzo y desinfección de quirófano',
        ),
      ]);

  @override
  Stream<List<UserProfile>> streamClients({String? prefixQuery}) => Stream.value(const [
        kClientProfile,
        UserProfile(
          uid: 'client-02',
          email: 'cliente2.demo@example.com',
          fullName: 'Cliente Dos Demo',
          searchName: 'cliente dos demo',
          phone: '+593 99 000 0002',
          documentType: 'CEDULA',
          documentNumber: '0000000002',
          address: 'Calle Ejemplo 456, Ciudad Demo',
          role: 'CLIENT',
          status: 'ACTIVE',
        ),
      ]);

  @override
  Stream<List<Pet>> streamClientPets(String clientId) =>
      Stream.value(const [kPet1, kPet2]);

  @override
  Future<Result<void>> confirmAppointment(String appointmentId) async =>
      const Ok(null);

  @override
  Future<Result<void>> cancelAppointmentByStaff(String appointmentId) async =>
      const Ok(null);
}

class ShowcaseDashboardRepo extends FakeRepo implements DashboardRepository {
  @override
  Future<Result<DashboardMetrics>> getDashboardMetrics() async => const Ok(
        DashboardMetrics(
          todayAppointmentsCount: 8,
          pendingAppointmentsCount: 3,
          pendingRequestsCount: 2,
          monthlyClientsCount: 45,
          lowStockProductsCount: 2,
          conflictedAppointmentsCount: 0,
          isDegraded: false,
        ),
      );
}

class ShowcaseClinicalRepo extends FakeRepo implements ClinicalRepository {
  @override
  Stream<List<ClinicalRecord>> streamClinicalRecords(String petId) =>
      Stream.value(const []);
}

class ShowcaseGovernanceRepo extends FakeRepo implements GovernanceRepository {
  final List<UserProfile> _allUsers = const [
    kStaffProfile,
    UserProfile(
      uid: 'staff-vet-01',
      email: 'veterinaria.demo@example.com',
      fullName: 'Dra. Veterinaria Demo',
      searchName: 'dra. veterinaria demo',
      phone: '+593 99 000 0003',
      documentType: 'CEDULA',
      documentNumber: '0000000003',
      address: 'Ciudad Demo',
      role: 'VETERINARIO',
      status: 'ACTIVE',
    ),
    UserProfile(
      uid: 'staff-recep-01',
      email: 'recepcion.demo@example.com',
      fullName: 'Recepción Demo',
      searchName: 'recepcion demo',
      phone: '+593 99 000 0004',
      documentType: 'CEDULA',
      documentNumber: '0000000004',
      address: 'Ciudad Demo',
      role: 'RECEPCIONISTA',
      status: 'ACTIVE',
    ),
    kClientProfile,
  ];

  @override
  Future<Result<List<UserProfile>>> getUsers() async => Ok(_allUsers);

  @override
  Stream<List<UserProfile>> streamUsers() => Stream.value(_allUsers);

  @override
  Future<Result<OperatingParameters>> getOperatingParameters() async =>
      const Ok(
        OperatingParameters(
          openingTime: '08:00',
          closingTime: '18:00',
          slotDurationMinutes: 30,
          workingWeekdays: [1, 2, 3, 4, 5, 6],
          lowStockThreshold: 5,
        ),
      );

  @override
  Future<Result<List<AuditLogEntry>>> getAuditLogs({int limit = 50}) async =>
      Ok([
        AuditLogEntry(
          id: 'aud-001',
          action: 'CONFIRM_APPOINTMENT',
          actorUid: 'staff-super-01',
          actorName: 'Administrador Demo (Superadmin)',
          actorRole: 'SUPERADMIN',
          targetType: 'appointment',
          targetId: 'appt-001',
          createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
          metadata: const {'status': 'CONFIRMED', 'petName': 'Max'},
        ),
        AuditLogEntry(
          id: 'aud-002',
          action: 'CREATE_PROFORMA',
          actorUid: 'staff-super-01',
          actorName: 'Administrador Demo (Superadmin)',
          actorRole: 'SUPERADMIN',
          targetType: 'proforma',
          targetId: 'prof-001',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          metadata: const {'seriesNumber': '001-001-000102', 'totalCents': 5520},
        ),
        AuditLogEntry(
          id: 'aud-003',
          action: 'USER_LOGIN',
          actorUid: 'client-demo-01',
          actorName: 'Cliente Demo Ejemplo',
          actorRole: 'CLIENT',
          targetType: 'users',
          targetId: 'client-demo-01',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          metadata: const {'method': 'password', 'ip': '192.168.0.103'},
        ),
      ]);
}
