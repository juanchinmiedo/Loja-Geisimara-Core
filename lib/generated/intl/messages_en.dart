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

  static String m1(value) => "Error: ${value}";

  static String m2(url) => "Could not open ${url}";

  static String m3(price) => "Price: ${price}";

  static String m4(value) => "Price: €${value}";

  static String m5(minutes) => "Time: ${minutes}m";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "Aservices": MessageLookupByLibrary.simpleMessage("All Services"),
        "Aspecialists": MessageLookupByLibrary.simpleMessage("All Specialists"),
        "Bservices": MessageLookupByLibrary.simpleMessage("Best Services"),
        "Bspecialists":
            MessageLookupByLibrary.simpleMessage("Best Specialists"),
        "_app_common":
            MessageLookupByLibrary.simpleMessage("Common app strings"),
        "_booking_admin_dialogs": MessageLookupByLibrary.simpleMessage(
            "Texts used in create/edit appointment dialogs"),
        "_carrousel_dart": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar donde estan estos textos"),
        "_home_screenn": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar donde estan estos textos"),
        "_maps_screen_dart": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar donde estan estos textos"),
        "_onboarding_screenn": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar donde estan estos textos"),
        "aboutMe": MessageLookupByLibrary.simpleMessage("About me"),
        "acrylicA": MessageLookupByLibrary.simpleMessage("Acrylic Aplication"),
        "acrylicM": MessageLookupByLibrary.simpleMessage("Acrylic Maintenance"),
        "adminModeEnabled":
            MessageLookupByLibrary.simpleMessage("Admin mode enabled"),
        "appTitle": MessageLookupByLibrary.simpleMessage("Nails Studio"),
        "appointmentCreated":
            MessageLookupByLibrary.simpleMessage("Appointment created"),
        "appointmentDeleted":
            MessageLookupByLibrary.simpleMessage("Appointment deleted"),
        "appointmentUpdated":
            MessageLookupByLibrary.simpleMessage("Appointment updated"),
        "appointmentsCount": m0,
        "bookNowButton": MessageLookupByLibrary.simpleMessage("Book Now"),
        "bookNowSubtitle": MessageLookupByLibrary.simpleMessage(
            "Schedule your appointment in a few seconds"),
        "bookNowTitle":
            MessageLookupByLibrary.simpleMessage("Schedule Appointment"),
        "bookingTab": MessageLookupByLibrary.simpleMessage("Booking"),
        "bottom_navigationbar": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "category": MessageLookupByLibrary.simpleMessage("Category"),
        "clientFallback": MessageLookupByLibrary.simpleMessage("Client"),
        "clientsTab": MessageLookupByLibrary.simpleMessage("Clients"),
        "confirmBooking":
            MessageLookupByLibrary.simpleMessage("Confirm booking"),
        "console_firebase_database": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente"),
        "continueAsGuest":
            MessageLookupByLibrary.simpleMessage("Continue as guest"),
        "continueWithGoogle":
            MessageLookupByLibrary.simpleMessage("Continue with Google"),
        "countryLabel": MessageLookupByLibrary.simpleMessage("Country"),
        "create": MessageLookupByLibrary.simpleMessage("Create"),
        "createAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Create appointment"),
        "cutilage": MessageLookupByLibrary.simpleMessage("Cutilage"),
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "deleteAppointmentBody": MessageLookupByLibrary.simpleMessage(
            "This action cannot be undone."),
        "deleteAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Delete appointment?"),
        "editAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Edit appointment"),
        "errorLoadingServices":
            MessageLookupByLibrary.simpleMessage("Error loading services"),
        "errorLoadingSpecialists":
            MessageLookupByLibrary.simpleMessage("Error loading specialists"),
        "errorWithValue": m1,
        "feet": MessageLookupByLibrary.simpleMessage("feet"),
        "fiberA": MessageLookupByLibrary.simpleMessage("Fiber Aplication"),
        "fiberM": MessageLookupByLibrary.simpleMessage("Fiber Maintenance"),
        "firstNameLabel": MessageLookupByLibrary.simpleMessage("First name"),
        "firstNameRequired":
            MessageLookupByLibrary.simpleMessage("First name is required"),
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
        "instagramOptionalLabel":
            MessageLookupByLibrary.simpleMessage("Instagram (optional)"),
        "intro": MessageLookupByLibrary.simpleMessage(
            "Manicure, Pedicure and Eyebrows and Eyelashes Design"),
        "language": MessageLookupByLibrary.simpleMessage("Language"),
        "lastNameLabel": MessageLookupByLibrary.simpleMessage("Last name"),
        "lastNameRequired":
            MessageLookupByLibrary.simpleMessage("Last name is required"),
        "logout": MessageLookupByLibrary.simpleMessage("Sign out"),
        "mapsTab": MessageLookupByLibrary.simpleMessage("Maps"),
        "modeExisting": MessageLookupByLibrary.simpleMessage("Existing"),
        "modeNew": MessageLookupByLibrary.simpleMessage("New"),
        "mostCommonBadge": MessageLookupByLibrary.simpleMessage("Most common"),
        "nailDecorations": MessageLookupByLibrary.simpleMessage("Decorations"),
        "nailRemove": MessageLookupByLibrary.simpleMessage("Nail Removal"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "noMatches": MessageLookupByLibrary.simpleMessage("No matches"),
        "noPhotos": MessageLookupByLibrary.simpleMessage("No photos yet"),
        "noServicesAssigned":
            MessageLookupByLibrary.simpleMessage("No services assigned"),
        "noServicesFound":
            MessageLookupByLibrary.simpleMessage("No services found"),
        "noSpecialistsFound":
            MessageLookupByLibrary.simpleMessage("No specialists found"),
        "offers": MessageLookupByLibrary.simpleMessage("Offers"),
        "openInMaps":
            MessageLookupByLibrary.simpleMessage("Open in Google Maps"),
        "openInMapsError":
            MessageLookupByLibrary.simpleMessage("Could not open Google Maps"),
        "openUrlError": m2,
        "phoneLabel": MessageLookupByLibrary.simpleMessage("Phone"),
        "phoneOrInstagramRequired": MessageLookupByLibrary.simpleMessage(
            "Phone or Instagram is required"),
        "pickProcedureTitle":
            MessageLookupByLibrary.simpleMessage("Pick a Procedure"),
        "pickTypeTitle": MessageLookupByLibrary.simpleMessage("Pick a Type"),
        "price": m3,
        "priceLabel": m4,
        "priceOnRequest":
            MessageLookupByLibrary.simpleMessage("Price on request"),
        "procedureLabel": MessageLookupByLibrary.simpleMessage("Procedure"),
        "procedureRequired":
            MessageLookupByLibrary.simpleMessage("Procedure is required"),
        "profileTab": MessageLookupByLibrary.simpleMessage("Profile"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "schedule": MessageLookupByLibrary.simpleMessage("Schedule"),
        "searchClientLabel": MessageLookupByLibrary.simpleMessage(
            "Search (name / phone / instagram)"),
        "selectExistingClient":
            MessageLookupByLibrary.simpleMessage("Select an existing client"),
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
        "simplePedicure":
            MessageLookupByLibrary.simpleMessage("Simple Pedicure"),
        "simpleVarnish": MessageLookupByLibrary.simpleMessage("Simple Varnish"),
        "start": MessageLookupByLibrary.simpleMessage("Get Started"),
        "startAdminMode":
            MessageLookupByLibrary.simpleMessage("Start admin mode"),
        "successBooking": MessageLookupByLibrary.simpleMessage(
            "Your appointment is confirmed!"),
        "tabInfo": MessageLookupByLibrary.simpleMessage("Info"),
        "tabPortfolio": MessageLookupByLibrary.simpleMessage("Portfolio"),
        "timeMinutesEmpty": MessageLookupByLibrary.simpleMessage("Time: —"),
        "timeMinutesLabel": m5,
        "timeRequired":
            MessageLookupByLibrary.simpleMessage("Time is required"),
        "title":
            MessageLookupByLibrary.simpleMessage("Geisimara Nail Designer"),
        "typeLabel": MessageLookupByLibrary.simpleMessage("Type"),
        "typeRequired":
            MessageLookupByLibrary.simpleMessage("Type is required"),
        "viewAll": MessageLookupByLibrary.simpleMessage("View all"),
        "viewProfileAndCatalog":
            MessageLookupByLibrary.simpleMessage("View profile & catalog"),
        "website": MessageLookupByLibrary.simpleMessage("website"),
        "workerNotFound":
            MessageLookupByLibrary.simpleMessage("Worker not found")
      };
}
