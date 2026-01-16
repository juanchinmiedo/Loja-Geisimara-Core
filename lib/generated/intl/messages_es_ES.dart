// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a es_ES locale. All the
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
  String get localeName => 'es_ES';

  static String m0(count) =>
      "${Intl.plural(count, zero: 'Sin citas', one: '1 cita', other: '${count} citas')}";

  static String m1(value) => "Error: ${value}";

  static String m2(url) => "NNo se pudo abrir ${url}";

  static String m3(price) => "Precio: ${price}";

  static String m4(value) => "Precio: €${value}";

  static String m5(minutes) => "Tiempo: ${minutes}m";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "Aservices":
            MessageLookupByLibrary.simpleMessage("Todos los Servicios"),
        "Aspecialists":
            MessageLookupByLibrary.simpleMessage("Todos los Especialistas"),
        "Bservices": MessageLookupByLibrary.simpleMessage("Mejores Servicios"),
        "Bspecialists":
            MessageLookupByLibrary.simpleMessage("Mejores Especialistas"),
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
        "aboutMe": MessageLookupByLibrary.simpleMessage("Sobre mí"),
        "acrylicA":
            MessageLookupByLibrary.simpleMessage("Aplicación de Acrílico"),
        "acrylicM":
            MessageLookupByLibrary.simpleMessage("Mantenimiento de Acrílico"),
        "adminModeEnabled":
            MessageLookupByLibrary.simpleMessage("Modo admin activado"),
        "appTitle": MessageLookupByLibrary.simpleMessage("Salón de Manicura"),
        "appointmentCreated":
            MessageLookupByLibrary.simpleMessage("Cita creada"),
        "appointmentDeleted":
            MessageLookupByLibrary.simpleMessage("Cita eliminada"),
        "appointmentUpdated":
            MessageLookupByLibrary.simpleMessage("Cita actualizada"),
        "appointmentsCount": m0,
        "bookNowButton": MessageLookupByLibrary.simpleMessage("Reservar ahora"),
        "bookNowSubtitle": MessageLookupByLibrary.simpleMessage(
            "Programa tu cita en unos segundos"),
        "bookNowTitle": MessageLookupByLibrary.simpleMessage("Agendar Cita"),
        "bookingTab": MessageLookupByLibrary.simpleMessage("Reservas"),
        "bottom_navigationbar": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "category": MessageLookupByLibrary.simpleMessage("Categoría"),
        "clientFallback": MessageLookupByLibrary.simpleMessage("Cliente"),
        "clientsTab": MessageLookupByLibrary.simpleMessage("Clientes"),
        "confirmBooking":
            MessageLookupByLibrary.simpleMessage("Confirmar reserva"),
        "console_firebase_database": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente"),
        "continueAsGuest":
            MessageLookupByLibrary.simpleMessage("Continuar como invitado"),
        "continueWithGoogle":
            MessageLookupByLibrary.simpleMessage("Continuar con Google"),
        "countryLabel": MessageLookupByLibrary.simpleMessage("País"),
        "create": MessageLookupByLibrary.simpleMessage("Crear"),
        "createAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Crear cita"),
        "cutilage": MessageLookupByLibrary.simpleMessage("Cutilaje"),
        "delete": MessageLookupByLibrary.simpleMessage("Eliminar"),
        "deleteAppointmentBody": MessageLookupByLibrary.simpleMessage(
            "Esta acción no se puede deshacer."),
        "deleteAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("¿Eliminar cita?"),
        "editAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Editar cita"),
        "errorLoadingServices":
            MessageLookupByLibrary.simpleMessage("Error al cargar servicios"),
        "errorLoadingSpecialists": MessageLookupByLibrary.simpleMessage(
            "Error al cargar especialistas"),
        "errorWithValue": m1,
        "feet": MessageLookupByLibrary.simpleMessage("pies"),
        "fiberA": MessageLookupByLibrary.simpleMessage("Aplicación de Fibra"),
        "fiberM":
            MessageLookupByLibrary.simpleMessage("Mantenimiento de Fibra"),
        "firstNameLabel": MessageLookupByLibrary.simpleMessage("Nombre"),
        "firstNameRequired":
            MessageLookupByLibrary.simpleMessage("El nombre es obligatorio"),
        "gelA": MessageLookupByLibrary.simpleMessage("Aplicación de Gel"),
        "gelM": MessageLookupByLibrary.simpleMessage("Mantenimiento de Gel"),
        "gelVarnish": MessageLookupByLibrary.simpleMessage(
            "Refuerzo con Esmaltado de Gel"),
        "gelVarnishPedicure": MessageLookupByLibrary.simpleMessage(
            "Pedicura con Esmaltado de Gel"),
        "googleLoginSuccess":
            MessageLookupByLibrary.simpleMessage("Sesión iniciada con Google"),
        "guest": MessageLookupByLibrary.simpleMessage("Invitado"),
        "hands": MessageLookupByLibrary.simpleMessage("manos"),
        "homeTab": MessageLookupByLibrary.simpleMessage("Inicio"),
        "instagramOptionalLabel":
            MessageLookupByLibrary.simpleMessage("Instagram (opcional)"),
        "intro": MessageLookupByLibrary.simpleMessage(
            "Manicura, Pedicura y Design de Cejas y Pestañas"),
        "language": MessageLookupByLibrary.simpleMessage("Idioma"),
        "lastNameLabel": MessageLookupByLibrary.simpleMessage("Apellido"),
        "lastNameRequired":
            MessageLookupByLibrary.simpleMessage("El apellido es obligatorio"),
        "logout": MessageLookupByLibrary.simpleMessage("Cerrar sesión"),
        "mapsTab": MessageLookupByLibrary.simpleMessage("Mapas"),
        "modeExisting": MessageLookupByLibrary.simpleMessage("Existente"),
        "modeNew": MessageLookupByLibrary.simpleMessage("Nuevo"),
        "mostCommonBadge": MessageLookupByLibrary.simpleMessage("Más común"),
        "nailDecorations": MessageLookupByLibrary.simpleMessage("Decoraciones"),
        "nailRemove": MessageLookupByLibrary.simpleMessage("Retirar Uñas"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "noMatches": MessageLookupByLibrary.simpleMessage("Sin resultados"),
        "noPhotos": MessageLookupByLibrary.simpleMessage("Aún no hay fotos"),
        "noServicesAssigned":
            MessageLookupByLibrary.simpleMessage("No hay servicios asignados"),
        "noServicesFound":
            MessageLookupByLibrary.simpleMessage("No se encontraron servicios"),
        "noSpecialistsFound": MessageLookupByLibrary.simpleMessage(
            "No se encontraron especialistas"),
        "offers": MessageLookupByLibrary.simpleMessage("Ofertas"),
        "openInMaps":
            MessageLookupByLibrary.simpleMessage("Abrir en Google Maps"),
        "openInMapsError": MessageLookupByLibrary.simpleMessage(
            "No se pudo abrir Google Maps"),
        "openUrlError": m2,
        "phoneLabel": MessageLookupByLibrary.simpleMessage("Teléfono"),
        "phoneOrInstagramRequired": MessageLookupByLibrary.simpleMessage(
            "Se requiere teléfono o Instagram"),
        "pickProcedureTitle":
            MessageLookupByLibrary.simpleMessage("Selecciona un procedimiento"),
        "pickTypeTitle":
            MessageLookupByLibrary.simpleMessage("Selecciona un tipo"),
        "price": m3,
        "priceLabel": m4,
        "priceOnRequest":
            MessageLookupByLibrary.simpleMessage("Precio a solicitud"),
        "procedureLabel": MessageLookupByLibrary.simpleMessage("Procedimiento"),
        "procedureRequired": MessageLookupByLibrary.simpleMessage(
            "El procedimiento es obligatorio"),
        "profileTab": MessageLookupByLibrary.simpleMessage("Perfil"),
        "save": MessageLookupByLibrary.simpleMessage("Guardar"),
        "schedule": MessageLookupByLibrary.simpleMessage("Horario"),
        "searchClientLabel": MessageLookupByLibrary.simpleMessage(
            "Buscar (nombre / teléfono / instagram)"),
        "selectExistingClient": MessageLookupByLibrary.simpleMessage(
            "Selecciona un cliente existente"),
        "selectProcedureHelper": MessageLookupByLibrary.simpleMessage(
            "Por favor selecciona un procedimiento"),
        "selectProcedurePlaceholder":
            MessageLookupByLibrary.simpleMessage("Seleccionar procedimiento"),
        "selectTimePlaceholder":
            MessageLookupByLibrary.simpleMessage("Seleccionar hora"),
        "selectTypePlaceholder":
            MessageLookupByLibrary.simpleMessage("Seleccionar tipo"),
        "serviceFallback": MessageLookupByLibrary.simpleMessage("Servicio"),
        "services": MessageLookupByLibrary.simpleMessage("servicios"),
        "simplePedicure":
            MessageLookupByLibrary.simpleMessage("Pedicura Simple"),
        "simpleVarnish":
            MessageLookupByLibrary.simpleMessage("Esmaltado Simple"),
        "start": MessageLookupByLibrary.simpleMessage("Comenzar"),
        "startAdminMode":
            MessageLookupByLibrary.simpleMessage("Iniciar modo admin"),
        "successBooking": MessageLookupByLibrary.simpleMessage(
            "¡Tu cita ha sido confirmada!"),
        "tabInfo": MessageLookupByLibrary.simpleMessage("Info"),
        "tabPortfolio": MessageLookupByLibrary.simpleMessage("Portfolio"),
        "timeMinutesEmpty": MessageLookupByLibrary.simpleMessage("Tiempo: —"),
        "timeMinutesLabel": m5,
        "timeRequired":
            MessageLookupByLibrary.simpleMessage("La hora es obligatoria"),
        "title":
            MessageLookupByLibrary.simpleMessage("Geisimara Nail Designer"),
        "typeLabel": MessageLookupByLibrary.simpleMessage("Tipo"),
        "typeRequired":
            MessageLookupByLibrary.simpleMessage("El tipo es obligatorio"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Ver todo"),
        "viewProfileAndCatalog":
            MessageLookupByLibrary.simpleMessage("Ver perfil y catálogo"),
        "website": MessageLookupByLibrary.simpleMessage("sitio web"),
        "workerNotFound":
            MessageLookupByLibrary.simpleMessage("Trabajador no encontrado")
      };
}
