// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/profile/views/profile_edit_view.dart
// Propósito: Pantalla de edición de datos personales del cliente con validación canónica de identificación oficial ecuatoriana y protección de correo.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/services/web_file_picker.dart';
import 'package:mipetshop/core/validators/document.dart';
import 'package:mipetshop/core/validators/phone.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/features/profile/view_models/profile_view_model.dart';

/// Formulario interactivo para la actualización de datos de perfil del cliente.
///
/// Implementa reglas estrictas de integridad y seguridad:
/// - Permite modificar exclusivamente los campos autorizados: nombres completos, teléfono de contacto,
///   tipo de documento (`CEDULA`, `RUC`, `PASAPORTE`), número de documento tributario y dirección física.
/// - El correo electrónico institucional o de autenticación permanece estrictamente bloqueado en modo de solo lectura.
/// - Validación en tiempo real del algoritmo de módulo 10 para cédulas de identidad ecuatorianas y formato RUC.
/// - Soporte para selección y carga de nueva fotografía de perfil mediante [WebFilePicker].
class ProfileEditView extends StatefulWidget {
  /// Modelo de vista reactivo gestor de las operaciones de consulta y guardado del perfil.
  final ProfileViewModel viewModel;

  /// Constructor de la vista de edición de perfil.
  const ProfileEditView({
    super.key,
    required this.viewModel,
  });

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}


class _ProfileEditViewState extends State<ProfileEditView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _documentNumberController;
  late final TextEditingController _addressController;

  String _documentType = DocumentTypes.cedula;

  @override
  void initState() {
    super.initState();
    final profile = widget.viewModel.profile;

    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _documentNumberController =
        TextEditingController(text: profile?.documentNumber ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');

    if (profile != null && isValidDocumentType(profile.documentType)) {
      _documentType = profile.documentType;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final profile = widget.viewModel.profile;
    if (profile == null) return;

    final success = await widget.viewModel.updateProfile(
      uid: profile.uid,
      fullName: _fullNameController.text,
      phone: _phoneController.text,
      documentType: _documentType,
      documentNumber: _documentNumberController.text,
      address: _addressController.text,
    );

    if (success && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.profileUpdateSuccess ?? ''),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.editProfileTitle ?? ''),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return ResponsiveLayout(
            builder: (context, breakpoint) {
              final horizontalPadding = breakpoint.isCompact ? 16.0 : 32.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAvatarSection(theme, l10n),
                          const SizedBox(height: 24.0),
                          if (widget.viewModel.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                widget.viewModel.errorMessage!,
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                          ],
                          _buildFullNameField(l10n),
                          const SizedBox(height: 16.0),
                          _buildImmutableEmailField(l10n, theme),
                          const SizedBox(height: 16.0),
                          _buildPhoneField(l10n),
                          const SizedBox(height: 16.0),
                          _buildDocumentFields(l10n),
                          const SizedBox(height: 16.0),
                          _buildAddressField(l10n),
                          const SizedBox(height: 32.0),
                          _buildFormButtons(l10n),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection(ThemeData theme, AppLocalizations? l10n) {
    final photoBytes = widget.viewModel.photoBytes;
    final changeText = l10n?.changePhotoAction ?? '';

    return Column(
      children: [
        CircleAvatar(
          radius: 48.0,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
          child: photoBytes == null
              ? Icon(
                  Icons.person,
                  size: 48.0,
                  color: theme.colorScheme.onPrimaryContainer,
                )
              : null,
        ),
        const SizedBox(height: 12.0),
        TappableArea(
          semanticLabel: changeText,
          tooltip: changeText,
          minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          onTap: () {
            _showImageSelectDialog(l10n);
          },
          child: OutlinedButton.icon(
            onPressed: () {
              _showImageSelectDialog(l10n);
            },
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(changeText),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140.0, 48.0),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showImageSelectDialog(AppLocalizations? l10n) async {
    final profile = widget.viewModel.profile;
    if (profile == null) return;

    final pickResult = await pickPlatformFile();
    if (!mounted) return;

    switch (pickResult.status) {
      case FilePickStatus.cancelled:
        return;
      case FilePickStatus.unsupportedFormat:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.imageFormatUnsupported ?? '',
            ),
          ),
        );
        return;
      case FilePickStatus.rejectedHeic:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.imageFormatHeicRejected ?? '',
            ),
          ),
        );
        return;
      case FilePickStatus.sizeExceeded:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.imageSizeExceeded ?? '',
            ),
          ),
        );
        return;
      case FilePickStatus.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pickResult.errorMessage ??
                  (l10n?.errorGeneric ?? ''),
            ),
          ),
        );
        return;
      case FilePickStatus.success:
        final file = pickResult.file!;
        await widget.viewModel.uploadPhoto(
          uid: profile.uid,
          fileName: file.name,
          bytes: file.bytes,
          mimeType: file.mimeType,
        );
        return;
    }
  }

  Widget _buildFullNameField(AppLocalizations? l10n) {
    return TextFormField(
      key: const Key('profile_fullname_field'),
      controller: _fullNameController,
      decoration: InputDecoration(
        labelText: l10n?.fullNameLabel ?? '',
        prefixIcon: const Icon(Icons.person_outline),
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return l10n?.validationFullNameRequired;
        }
        if (!isValidFullName(val)) {
          return l10n?.validationFullNameRequired;
        }
        return null;
      },
    );
  }

  Widget _buildImmutableEmailField(AppLocalizations? l10n, ThemeData theme) {
    return TextFormField(
      key: const Key('profile_email_field'),
      controller: _emailController,
      readOnly: true,
      enabled: false,
      decoration: InputDecoration(
        labelText: l10n?.emailLabel ?? '',
        helperText: l10n?.profileEmailNotice ?? '',
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        filled: true,
      ),
    );
  }

  Widget _buildPhoneField(AppLocalizations? l10n) {
    return TextFormField(
      key: const Key('profile_phone_field'),
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: l10n?.phoneLabel ?? '',
        prefixIcon: const Icon(Icons.phone_outlined),
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return l10n?.validationPhoneRequired;
        }
        if (!isValidPhone(val)) {
          return l10n?.validationPhoneInvalid;
        }
        return null;
      },
    );
  }

  Widget _buildDocumentFields(AppLocalizations? l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            key: const Key('profile_document_type_field'),
            initialValue: _documentType,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n?.documentTypeLabel ?? '',
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: DocumentTypes.cedula,
                child: Text(l10n?.docTypeCedula ?? ''),
              ),
              DropdownMenuItem(
                value: DocumentTypes.ruc,
                child: Text(l10n?.docTypeRuc ?? ''),
              ),
              DropdownMenuItem(
                value: DocumentTypes.passport,
                child: Text(l10n?.docTypePassport ?? ''),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _documentType = val;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          flex: 3,
          child: TextFormField(
            key: const Key('profile_document_number_field'),
            controller: _documentNumberController,
            decoration: InputDecoration(
              labelText: l10n?.documentNumberLabel ?? '',
              border: const OutlineInputBorder(),
            ),
            validator: (val) {
              return validateDocumentNumber(_documentType, val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddressField(AppLocalizations? l10n) {
    return TextFormField(
      key: const Key('profile_address_field'),
      controller: _addressController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: l10n?.addressLabel ?? '',
        prefixIcon: const Icon(Icons.location_on_outlined),
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return l10n?.validationAddressRequired;
        }
        if (!isValidAddress(val)) {
          return l10n?.validationAddressMaxLength;
        }
        return null;
      },
    );
  }

  Widget _buildFormButtons(AppLocalizations? l10n) {
    final isSaving = widget.viewModel.isSaving;
    final saveText = l10n?.saveChangesAction ?? '';
    final cancelText = l10n?.cancel ?? '';

    return Row(
      children: [
        Expanded(
          child: TappableArea(
            semanticLabel: cancelText,
            tooltip: cancelText,
            minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
            onTap: isSaving ? null : () => Navigator.of(context).pop(),
            child: OutlinedButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48.0),
              ),
              child: Text(cancelText),
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: TappableArea(
            semanticLabel: saveText,
            tooltip: saveText,
            minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
            onTap: isSaving ? null : _submitForm,
            child: ElevatedButton(
              onPressed: isSaving ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48.0),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : Text(saveText),
            ),
          ),
        ),
      ],
    );
  }
}
