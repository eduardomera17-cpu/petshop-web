// Cloud Functions entrypoint for PetShop
// All function exports will be registered here as they are implemented.

export { verifyHuman } from './callables/verifyHuman.js';
export { completeRegistration } from './callables/completeRegistration.js';
export { createAppointment } from './callables/createAppointment.js';
export { cancelAppointmentByClient } from './callables/cancelAppointmentByClient.js';
export { confirmAppointment } from './callables/confirmAppointment.js';
export { completeAppointment } from './callables/completeAppointment.js';
export { cancelAppointmentByStaff } from './callables/cancelAppointmentByStaff.js';
export { deactivatePet } from './callables/deactivatePet.js';
export { previewPetDeactivation } from './callables/previewPetDeactivation.js';
export { beforeUserCreated } from './auth/beforeUserCreated.js';
export { beforeUserSignedIn } from './auth/beforeUserSignedIn.js';
export {
  normalizeUserSearchName,
  normalizePetSearchName,
  normalizeServiceSearchName,
  normalizeProductSearchName,
} from './triggers/normalize_search_name.js';
export { replicatePublicPricing } from './triggers/replicate_public_pricing.js';
export { onObjectFinalized } from './triggers/on_object_finalized.js';
export { adjustProductStock } from './callables/adjustProductStock.js';
export { createProductRequest } from './callables/createProductRequest.js';
export { cancelProductRequestByClient } from './callables/cancelProductRequestByClient.js';
export { advanceProductRequest } from './callables/advanceProductRequest.js';
export { createProformaDraft } from './callables/createProformaDraft.js';
export { addProformaItems } from './callables/addProformaItems.js';
export { setProformaAdjustments } from './callables/setProformaAdjustments.js';
export { deliverProforma } from './callables/deliverProforma.js';
export { finalizeProforma } from './callables/finalizeProforma.js';
export { voidProforma } from './callables/voidProforma.js';
export { previewAccountDeactivation } from './callables/previewAccountDeactivation.js';
export { deactivateOwnAccount } from './callables/deactivateOwnAccount.js';
export { rescheduleAppointment } from './callables/rescheduleAppointment.js';
export { setAvailabilityBlock } from './callables/setAvailabilityBlock.js';
export { reactivateAccountOrPet } from './callables/reactivateAccountOrPet.js';
export { createClinicalRecord } from './callables/createClinicalRecord.js';
export { updateClinicalRecord } from './callables/updateClinicalRecord.js';
export { annulClinicalRecord } from './callables/annulClinicalRecord.js';
export { projectPetWeight } from './triggers/project_pet_weight.js';
export { closePendingClinical } from './triggers/close_pending_clinical.js';
export { onMessageCreated, onMessageDeleted } from './triggers/chat_inbox.js';
export { purgeChatByClient } from './callables/purgeChatByClient.js';
export { moderateChat } from './callables/moderateChat.js';
export { markChatAsRead } from './callables/markChatAsRead.js';
export { updateOperatingParameters } from './callables/updateOperatingParameters.js';
export { replicatePublicOperating } from './triggers/replicate_public_operating.js';

// Despachador del correo de AG-09 (TRD v1.15 §3.5.H, ADR-021 Ruta B, AUD-INT-16)
export { dispatchMail } from './triggers/dispatch_mail.js';

// WP-5.3: Callables de gobierno de cuentas (SUPERADMIN)
export { createUserAccount } from './callables/createUserAccount.js';
export { updateUserIdentity } from './callables/updateUserIdentity.js';
export { resetUserPassword } from './callables/resetUserPassword.js';
export { deactivateUserAccount } from './callables/deactivateUserAccount.js';
export { deleteStaffAccount } from './callables/deleteStaffAccount.js';
