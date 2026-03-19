// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(count) =>
      "${Intl.plural(count, zero: 'No appointments', one: '1 appointment', other: '${count} appointments')}";

  static String m1(date) => "Block time – ${date}";

  static String m2(count) => "Delete all ${count} active requests and disable?";

  static String m3(value) => "Error: ${value}";

  static String m4(url) => "Could not open ${url}";

  static String m5(price) => "Price: ${price}";

  static String m6(value) => "Price: €${value}";

  static String m7(dur) => "Range must be at least ${dur} min";

  static String m8(minutes) => "Time: ${minutes}m";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "_app_common":
            MessageLookupByLibrary.simpleMessage("Common app strings"),
        "_booking_admin_dialogs": MessageLookupByLibrary.simpleMessage(
            "Texts used in create/edit appointment dialogs"),
        "_carrousel_dart": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar donde estan estos textos"),
        "_onboarding_screenn": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar donde estan estos textos"),
        "aboutMe": MessageLookupByLibrary.simpleMessage("About me"),
        "access": MessageLookupByLibrary.simpleMessage("Access"),
        "acrylicA": MessageLookupByLibrary.simpleMessage("Acrylic Aplication"),
        "acrylicM": MessageLookupByLibrary.simpleMessage("Acrylic Maintenance"),
        "activeBookingRequests":
            MessageLookupByLibrary.simpleMessage("Active booking requests"),
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "addDay": MessageLookupByLibrary.simpleMessage("Add day"),
        "addNewBlock": MessageLookupByLibrary.simpleMessage("Add new block"),
        "addRange": MessageLookupByLibrary.simpleMessage("+ Add range"),
        "adminHome": MessageLookupByLibrary.simpleMessage("Admin Home"),
        "adminModeEnabled":
            MessageLookupByLibrary.simpleMessage("Admin mode enabled"),
        "adminRole": MessageLookupByLibrary.simpleMessage("Admin"),
        "adminSchedule": MessageLookupByLibrary.simpleMessage("Admin Schedule"),
        "adminWorkerRole":
            MessageLookupByLibrary.simpleMessage("Admin + Worker"),
        "all": MessageLookupByLibrary.simpleMessage("All"),
        "any": MessageLookupByLibrary.simpleMessage("Any"),
        "anyTime": MessageLookupByLibrary.simpleMessage("Any time"),
        "appTitle": MessageLookupByLibrary.simpleMessage("Nails Studio"),
        "appointmentCreated":
            MessageLookupByLibrary.simpleMessage("Appointment created"),
        "appointmentDeleted":
            MessageLookupByLibrary.simpleMessage("Appointment deleted"),
        "appointmentUpdated":
            MessageLookupByLibrary.simpleMessage("Appointment updated"),
        "appointments": MessageLookupByLibrary.simpleMessage("Appointments"),
        "appointmentsCount": m0,
        "atRiskClients":
            MessageLookupByLibrary.simpleMessage("At risk (30–45d)"),
        "attended": MessageLookupByLibrary.simpleMessage("Attended"),
        "blockThisTime":
            MessageLookupByLibrary.simpleMessage("Block this time"),
        "blockTimeDateLabel": m1,
        "bookNowButton": MessageLookupByLibrary.simpleMessage("Book Now"),
        "bookNowSubtitle": MessageLookupByLibrary.simpleMessage(
            "Schedule your appointment in a few seconds"),
        "bookNowTitle":
            MessageLookupByLibrary.simpleMessage("Schedule Appointment"),
        "bookingRequest":
            MessageLookupByLibrary.simpleMessage("Booking request"),
        "bookingRequestCreated":
            MessageLookupByLibrary.simpleMessage("Booking request created"),
        "bookingTab": MessageLookupByLibrary.simpleMessage("Booking"),
        "bottom_navigationbar": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "category": MessageLookupByLibrary.simpleMessage("Category"),
        "checking": MessageLookupByLibrary.simpleMessage("Checking…"),
        "clientCancelledAppointment": MessageLookupByLibrary.simpleMessage(
            "Client cancelled the appointment"),
        "clientCreated": MessageLookupByLibrary.simpleMessage("Client created"),
        "clientDeleted": MessageLookupByLibrary.simpleMessage("Client deleted"),
        "clientDidNotAttend":
            MessageLookupByLibrary.simpleMessage("Client did not attend"),
        "clientFallback": MessageLookupByLibrary.simpleMessage("Client"),
        "clientUpdated": MessageLookupByLibrary.simpleMessage("Client updated"),
        "clientsNoVisitRecently": MessageLookupByLibrary.simpleMessage(
            "Clients who haven\'t visited recently"),
        "clientsTab": MessageLookupByLibrary.simpleMessage("Clients"),
        "close": MessageLookupByLibrary.simpleMessage("Close"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
        "confirmBooking":
            MessageLookupByLibrary.simpleMessage("Confirm booking"),
        "console_firebase_database": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente"),
        "continueAsGuest":
            MessageLookupByLibrary.simpleMessage("Continue as guest"),
        "continueWithGoogle":
            MessageLookupByLibrary.simpleMessage("Continue with Google"),
        "countryCode": MessageLookupByLibrary.simpleMessage("Country code"),
        "countryLabel": MessageLookupByLibrary.simpleMessage("Country"),
        "create": MessageLookupByLibrary.simpleMessage("Create"),
        "createAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Create appointment"),
        "createClient": MessageLookupByLibrary.simpleMessage("Create client"),
        "createRequest": MessageLookupByLibrary.simpleMessage("Create request"),
        "cutilage": MessageLookupByLibrary.simpleMessage("Cutilage"),
        "days": MessageLookupByLibrary.simpleMessage("Days"),
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "deleteAppointmentBody": MessageLookupByLibrary.simpleMessage(
            "This action cannot be undone."),
        "deleteAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Delete appointment?"),
        "deleteBookingRequests":
            MessageLookupByLibrary.simpleMessage("Delete booking request(s)?"),
        "deleteClient": MessageLookupByLibrary.simpleMessage("Delete client"),
        "deleteClientConfirm": MessageLookupByLibrary.simpleMessage(
            "This will delete the client document. Continue?"),
        "deleteClientTitle":
            MessageLookupByLibrary.simpleMessage("Delete client?"),
        "deleteRequest": MessageLookupByLibrary.simpleMessage("Delete request"),
        "deleteRequestConfirm": MessageLookupByLibrary.simpleMessage(
            "This will delete this booking request."),
        "deleteRequestTitle":
            MessageLookupByLibrary.simpleMessage("Delete request?"),
        "deletedPermanently":
            MessageLookupByLibrary.simpleMessage("Deleted permanently"),
        "disableBookingConfirmMany": m2,
        "disableBookingConfirmNone": MessageLookupByLibrary.simpleMessage(
            "Disable \'Looking for appointment\'. Continue?"),
        "disableBookingRequests":
            MessageLookupByLibrary.simpleMessage("Disable booking requests?"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Dismiss"),
        "duplicateName": MessageLookupByLibrary.simpleMessage("Duplicate name"),
        "editAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Edit appointment"),
        "editClient": MessageLookupByLibrary.simpleMessage("Edit client"),
        "editRequest": MessageLookupByLibrary.simpleMessage("Edit request"),
        "endMustBeAfterStart":
            MessageLookupByLibrary.simpleMessage("End must be after start"),
        "errorLoadingServices":
            MessageLookupByLibrary.simpleMessage("Error loading services"),
        "errorLoadingSpecialists":
            MessageLookupByLibrary.simpleMessage("Error loading specialists"),
        "errorWithValue": m3,
        "existingBlocks":
            MessageLookupByLibrary.simpleMessage("Existing blocks"),
        "feet": MessageLookupByLibrary.simpleMessage("feet"),
        "fiberA": MessageLookupByLibrary.simpleMessage("Fiber Aplication"),
        "fiberM": MessageLookupByLibrary.simpleMessage("Fiber Maintenance"),
        "finalPriceOptional":
            MessageLookupByLibrary.simpleMessage("Final price (optional)"),
        "firstNameLabel": MessageLookupByLibrary.simpleMessage("First name"),
        "firstNameRequired":
            MessageLookupByLibrary.simpleMessage("First name is required"),
        "from": MessageLookupByLibrary.simpleMessage("From"),
        "gelA": MessageLookupByLibrary.simpleMessage("Gel Aplication"),
        "gelM": MessageLookupByLibrary.simpleMessage("Gel Maintenance"),
        "gelVarnish":
            MessageLookupByLibrary.simpleMessage("Gel Varnish Reinforcement"),
        "gelVarnishPedicure":
            MessageLookupByLibrary.simpleMessage("Gel Varnish Pedicure"),
        "googleLoginSuccess":
            MessageLookupByLibrary.simpleMessage("Google login successful"),
        "guest": MessageLookupByLibrary.simpleMessage("Guest"),
        "hands": MessageLookupByLibrary.simpleMessage("hands"),
        "homeTab": MessageLookupByLibrary.simpleMessage("Home"),
        "instagram": MessageLookupByLibrary.simpleMessage("Instagram"),
        "instagramOptionalLabel":
            MessageLookupByLibrary.simpleMessage("Instagram (optional)"),
        "intro": MessageLookupByLibrary.simpleMessage(
            "Manicure, Pedicure and Eyebrows and Eyelashes Design"),
        "invalidFinalPrice":
            MessageLookupByLibrary.simpleMessage("Invalid final price"),
        "keep": MessageLookupByLibrary.simpleMessage("Keep"),
        "language": MessageLookupByLibrary.simpleMessage("Language"),
        "lastNameLabel": MessageLookupByLibrary.simpleMessage("Last name"),
        "lastNameRequired":
            MessageLookupByLibrary.simpleMessage("Last name is required"),
        "lastVisit": MessageLookupByLibrary.simpleMessage("Last visit"),
        "logout": MessageLookupByLibrary.simpleMessage("Sign out"),
        "lookingForAppointment":
            MessageLookupByLibrary.simpleMessage("Looking for appointment"),
        "lostClients": MessageLookupByLibrary.simpleMessage("Lost clients"),
        "lostClientsButton":
            MessageLookupByLibrary.simpleMessage("Lost clients  (30d+ / 45d+)"),
        "lostClientsTab": MessageLookupByLibrary.simpleMessage("Lost (45d+)"),
        "mapsTab": MessageLookupByLibrary.simpleMessage("Maps"),
        "markedAsCancelled":
            MessageLookupByLibrary.simpleMessage("Marked as cancelled"),
        "markedAsConfirmed": MessageLookupByLibrary.simpleMessage(
            "Marked as confirmed appointment."),
        "markedAsNoShow":
            MessageLookupByLibrary.simpleMessage("Marked as no-show"),
        "markedAsReservation": MessageLookupByLibrary.simpleMessage(
            "Marked as reservation: pending client confirmation."),
        "modeCancelled": MessageLookupByLibrary.simpleMessage("Cancelled"),
        "modeExisting": MessageLookupByLibrary.simpleMessage("Existing"),
        "modeLooking": MessageLookupByLibrary.simpleMessage("Looking"),
        "modeNew": MessageLookupByLibrary.simpleMessage("New"),
        "modeNoShow": MessageLookupByLibrary.simpleMessage("No-show"),
        "mostCommonBadge": MessageLookupByLibrary.simpleMessage("Most common"),
        "myError": MessageLookupByLibrary.simpleMessage("My error"),
        "nailDecorations": MessageLookupByLibrary.simpleMessage("Decorations"),
        "nailRecomposition":
            MessageLookupByLibrary.simpleMessage("Nail Recomposition"),
        "nailRemove": MessageLookupByLibrary.simpleMessage("Nail Removal"),
        "newAppointment":
            MessageLookupByLibrary.simpleMessage("New appointment"),
        "newBookingRequest":
            MessageLookupByLibrary.simpleMessage("New booking request"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "noAccess": MessageLookupByLibrary.simpleMessage("No access"),
        "noActiveBookingRequests": MessageLookupByLibrary.simpleMessage(
            "No active booking requests right now."),
        "noAppointmentsForDay": MessageLookupByLibrary.simpleMessage(
            "No appointments for this day"),
        "noAtRiskClients": MessageLookupByLibrary.simpleMessage(
            "No at-risk clients right now"),
        "noAvailability":
            MessageLookupByLibrary.simpleMessage("No availability"),
        "noClientsMatchFilter": MessageLookupByLibrary.simpleMessage(
            "No clients match this filter."),
        "noLostClients":
            MessageLookupByLibrary.simpleMessage("No lost clients right now"),
        "noMatches": MessageLookupByLibrary.simpleMessage("No matches"),
        "noNotifications":
            MessageLookupByLibrary.simpleMessage("No notifications."),
        "noPastAppointments":
            MessageLookupByLibrary.simpleMessage("No past appointments"),
        "noPhotos": MessageLookupByLibrary.simpleMessage("No photos yet"),
        "noRolesAssigned":
            MessageLookupByLibrary.simpleMessage("No roles assigned"),
        "noServicesAssigned":
            MessageLookupByLibrary.simpleMessage("No services assigned"),
        "noServicesFound":
            MessageLookupByLibrary.simpleMessage("No services found"),
        "noShow": MessageLookupByLibrary.simpleMessage("No show"),
        "noSpecialistsFound":
            MessageLookupByLibrary.simpleMessage("No specialists found"),
        "noUpcomingAppointments":
            MessageLookupByLibrary.simpleMessage("No upcoming appointments"),
        "none": MessageLookupByLibrary.simpleMessage("None"),
        "notLooking": MessageLookupByLibrary.simpleMessage("Not looking"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
        "openUrlError": m4,
        "past": MessageLookupByLibrary.simpleMessage("Past"),
        "pendingConfirmation":
            MessageLookupByLibrary.simpleMessage("Pending confirmation"),
        "pendingConfirmationLabel":
            MessageLookupByLibrary.simpleMessage("PENDING"),
        "pendingConfirmationMsg": MessageLookupByLibrary.simpleMessage(
            "Client still needs to confirm this time."),
        "phoneLabel": MessageLookupByLibrary.simpleMessage("Phone"),
        "phoneOrInstagramRequired": MessageLookupByLibrary.simpleMessage(
            "Phone or Instagram is required"),
        "phoneOrInstagramRequiredMsg":
            MessageLookupByLibrary.simpleMessage("Phone or Instagram required"),
        "pickEndTime": MessageLookupByLibrary.simpleMessage("Pick end time"),
        "pickPreferredDay":
            MessageLookupByLibrary.simpleMessage("Pick preferred day"),
        "pickProcedureTitle":
            MessageLookupByLibrary.simpleMessage("Pick a Procedure"),
        "pickStartTime":
            MessageLookupByLibrary.simpleMessage("Pick start time"),
        "pickTypeTitle": MessageLookupByLibrary.simpleMessage("Pick a Type"),
        "price": m5,
        "priceLabel": m6,
        "priceOnRequest":
            MessageLookupByLibrary.simpleMessage("Price on request"),
        "procedureLabel": MessageLookupByLibrary.simpleMessage("Procedure"),
        "procedureRequired":
            MessageLookupByLibrary.simpleMessage("Procedure is required"),
        "profileTab": MessageLookupByLibrary.simpleMessage("Profile"),
        "rangeMustBeAtLeast": m7,
        "ranges": MessageLookupByLibrary.simpleMessage("Ranges"),
        "reasonOptional":
            MessageLookupByLibrary.simpleMessage("Reason (optional)"),
        "remove": MessageLookupByLibrary.simpleMessage("Remove"),
        "removeAppointment":
            MessageLookupByLibrary.simpleMessage("Remove appointment"),
        "removeBlock": MessageLookupByLibrary.simpleMessage("Remove block?"),
        "removePermanently": MessageLookupByLibrary.simpleMessage(
            "Remove permanently (wrong booking)"),
        "request": MessageLookupByLibrary.simpleMessage("Request"),
        "requestUpdated":
            MessageLookupByLibrary.simpleMessage("Request updated"),
        "required": MessageLookupByLibrary.simpleMessage("Required"),
        "reservationPending": MessageLookupByLibrary.simpleMessage(
            "Reservation (pending confirmation)"),
        "results": MessageLookupByLibrary.simpleMessage("Results"),
        "roles": MessageLookupByLibrary.simpleMessage("Roles"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "saveClient": MessageLookupByLibrary.simpleMessage("Save client"),
        "schedule": MessageLookupByLibrary.simpleMessage("Schedule"),
        "searchClientLabel": MessageLookupByLibrary.simpleMessage(
            "Search (name / phone / instagram)"),
        "searchEllipsis": MessageLookupByLibrary.simpleMessage("Search..."),
        "searchHint": MessageLookupByLibrary.simpleMessage("Search"),
        "seeking": MessageLookupByLibrary.simpleMessage("Seeking"),
        "selectExistingClient":
            MessageLookupByLibrary.simpleMessage("Select an existing client"),
        "selectProcedureFirst":
            MessageLookupByLibrary.simpleMessage("Select a procedure first"),
        "selectProcedureHelper":
            MessageLookupByLibrary.simpleMessage("Please select a procedure"),
        "selectProcedurePlaceholder":
            MessageLookupByLibrary.simpleMessage("Select Procedure"),
        "selectTimePlaceholder":
            MessageLookupByLibrary.simpleMessage("Select time"),
        "selectTypePlaceholder":
            MessageLookupByLibrary.simpleMessage("Select Type"),
        "serviceFallback": MessageLookupByLibrary.simpleMessage("Service"),
        "services": MessageLookupByLibrary.simpleMessage("services"),
        "servicesStillLoading": MessageLookupByLibrary.simpleMessage(
            "Services are still loading..."),
        "signInToManage": MessageLookupByLibrary.simpleMessage(
            "Sign in to manage your appointments"),
        "simplePedicure":
            MessageLookupByLibrary.simpleMessage("Simple Pedicure"),
        "simpleVarnish": MessageLookupByLibrary.simpleMessage("Simple Varnish"),
        "start": MessageLookupByLibrary.simpleMessage("Get Started"),
        "startAdminMode":
            MessageLookupByLibrary.simpleMessage("Start admin mode"),
        "subtitleCancelled": MessageLookupByLibrary.simpleMessage(
            "Most cancellations (then most attended)"),
        "subtitleLooking": MessageLookupByLibrary.simpleMessage(
            "Clients looking for appointments"),
        "subtitleNoShow": MessageLookupByLibrary.simpleMessage(
            "Most no-shows (then most attended)"),
        "successBooking": MessageLookupByLibrary.simpleMessage(
            "Your appointment is confirmed!"),
        "tabInfo": MessageLookupByLibrary.simpleMessage("Info"),
        "tabPortfolio": MessageLookupByLibrary.simpleMessage("Portfolio"),
        "tapToOpenClient":
            MessageLookupByLibrary.simpleMessage("Tap to open client"),
        "tapToViewProfile":
            MessageLookupByLibrary.simpleMessage("Tap to view profile"),
        "timeIsConfirmed":
            MessageLookupByLibrary.simpleMessage("Time is confirmed."),
        "timeMinutesEmpty": MessageLookupByLibrary.simpleMessage("Time: —"),
        "timeMinutesLabel": m8,
        "timeRequired":
            MessageLookupByLibrary.simpleMessage("Time is required"),
        "tipAddDays": MessageLookupByLibrary.simpleMessage(
            "Tip: add one or more days, and optionally time ranges."),
        "title":
            MessageLookupByLibrary.simpleMessage("Geisimara Nail Designer"),
        "typeLabel": MessageLookupByLibrary.simpleMessage("Type"),
        "typeRequired":
            MessageLookupByLibrary.simpleMessage("Type is required"),
        "unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
        "upcoming": MessageLookupByLibrary.simpleMessage("Upcoming"),
        "upcomingAppointments":
            MessageLookupByLibrary.simpleMessage("Upcoming appointments"),
        "userRole": MessageLookupByLibrary.simpleMessage("User"),
        "viewDay": MessageLookupByLibrary.simpleMessage("Day"),
        "viewProfileAndCatalog":
            MessageLookupByLibrary.simpleMessage("View profile & catalog"),
        "viewWeek": MessageLookupByLibrary.simpleMessage("Week"),
        "weekdayFri": MessageLookupByLibrary.simpleMessage("Fri"),
        "weekdayMon": MessageLookupByLibrary.simpleMessage("Mon"),
        "weekdaySat": MessageLookupByLibrary.simpleMessage("Sat"),
        "weekdaySun": MessageLookupByLibrary.simpleMessage("Sun"),
        "weekdayThu": MessageLookupByLibrary.simpleMessage("Thu"),
        "weekdayTue": MessageLookupByLibrary.simpleMessage("Tue"),
        "weekdayWed": MessageLookupByLibrary.simpleMessage("Wed"),
        "worker": MessageLookupByLibrary.simpleMessage("Worker"),
        "workerId": MessageLookupByLibrary.simpleMessage("Worker ID"),
        "workerNotFound":
            MessageLookupByLibrary.simpleMessage("Worker not found"),
        "workerRole": MessageLookupByLibrary.simpleMessage("Worker")
      };
}
