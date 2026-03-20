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

  static String m1(date) => "Bloquear horario – ${date}";

  static String m2(count) =>
      "¿Eliminar todas las ${count} solicitudes activas y desactivar?";

  static String m3(value) => "Error: ${value}";

  static String m4(url) => "NNo se pudo abrir ${url}";

  static String m5(price) => "Precio: ${price}";

  static String m6(value) => "Precio: €${value}";

  static String m7(dur) => "El intervalo debe ser al menos ${dur} min";

  static String m8(minutes) => "Tiempo: ${minutes}m";

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
        "aboutMe": MessageLookupByLibrary.simpleMessage("Sobre mí"),
        "access": MessageLookupByLibrary.simpleMessage("Acceso"),
        "acrylicA":
            MessageLookupByLibrary.simpleMessage("Aplicación de Acrílico"),
        "acrylicM":
            MessageLookupByLibrary.simpleMessage("Mantenimiento de Acrílico"),
        "activeBookingRequests":
            MessageLookupByLibrary.simpleMessage("Solicitudes activas"),
        "add": MessageLookupByLibrary.simpleMessage("Añadir"),
        "addDay": MessageLookupByLibrary.simpleMessage("Añadir día"),
        "addNewBlock":
            MessageLookupByLibrary.simpleMessage("Añadir nuevo bloqueo"),
        "addRange": MessageLookupByLibrary.simpleMessage("+ Añadir intervalo"),
        "adminHome": MessageLookupByLibrary.simpleMessage("Inicio Admin"),
        "adminModeEnabled":
            MessageLookupByLibrary.simpleMessage("Modo admin activado"),
        "adminRole": MessageLookupByLibrary.simpleMessage("Admin"),
        "adminSchedule": MessageLookupByLibrary.simpleMessage("Agenda Admin"),
        "adminWorkerRole":
            MessageLookupByLibrary.simpleMessage("Admin + Trabajadora"),
        "agoNow": MessageLookupByLibrary.simpleMessage("ahora"),
        "all": MessageLookupByLibrary.simpleMessage("Todos"),
        "any": MessageLookupByLibrary.simpleMessage("Cualquiera"),
        "anyTime": MessageLookupByLibrary.simpleMessage("Cualquier hora"),
        "appTitle": MessageLookupByLibrary.simpleMessage("Salón de Manicura"),
        "appointmentCreated":
            MessageLookupByLibrary.simpleMessage("Cita creada"),
        "appointmentDeleted":
            MessageLookupByLibrary.simpleMessage("Cita eliminada"),
        "appointmentUpdated":
            MessageLookupByLibrary.simpleMessage("Cita actualizada"),
        "appointments": MessageLookupByLibrary.simpleMessage("Citas"),
        "appointmentsCount": m0,
        "atRiskClients":
            MessageLookupByLibrary.simpleMessage("En riesgo (30–45d)"),
        "attended": MessageLookupByLibrary.simpleMessage("Asistió"),
        "blockThisTime":
            MessageLookupByLibrary.simpleMessage("Bloquear este horario"),
        "blockTimeDateLabel": m1,
        "bookNowButton": MessageLookupByLibrary.simpleMessage("Reservar ahora"),
        "bookNowSubtitle": MessageLookupByLibrary.simpleMessage(
            "Programa tu cita en unos segundos"),
        "bookNowTitle": MessageLookupByLibrary.simpleMessage("Agendar Cita"),
        "bookingRequest":
            MessageLookupByLibrary.simpleMessage("Solicitud de reserva"),
        "bookingRequestCreated":
            MessageLookupByLibrary.simpleMessage("Solicitud de reserva creada"),
        "bookingTab": MessageLookupByLibrary.simpleMessage("Reservas"),
        "bottom_navigationbar": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente"),
        "byProcedure":
            MessageLookupByLibrary.simpleMessage("Por procedimiento"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "category": MessageLookupByLibrary.simpleMessage("Categoría"),
        "checking": MessageLookupByLibrary.simpleMessage("Verificando…"),
        "clientCancelledAppointment":
            MessageLookupByLibrary.simpleMessage("El cliente canceló la cita"),
        "clientCreated": MessageLookupByLibrary.simpleMessage("Cliente creado"),
        "clientDeleted":
            MessageLookupByLibrary.simpleMessage("Cliente eliminado"),
        "clientDidNotAttend":
            MessageLookupByLibrary.simpleMessage("El cliente no asistió"),
        "clientFallback": MessageLookupByLibrary.simpleMessage("Cliente"),
        "clientUpdated":
            MessageLookupByLibrary.simpleMessage("Cliente actualizado"),
        "clientsNoVisitRecently": MessageLookupByLibrary.simpleMessage(
            "Clientes sin visita reciente"),
        "clientsTab": MessageLookupByLibrary.simpleMessage("Clientes"),
        "close": MessageLookupByLibrary.simpleMessage("Cerrar"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
        "confirmBooking":
            MessageLookupByLibrary.simpleMessage("Confirmar reserva"),
        "console_firebase_database": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente"),
        "continueAsGuest":
            MessageLookupByLibrary.simpleMessage("Continuar como invitado"),
        "continueWithGoogle":
            MessageLookupByLibrary.simpleMessage("Continuar con Google"),
        "countryCode": MessageLookupByLibrary.simpleMessage("Código de país"),
        "countryLabel": MessageLookupByLibrary.simpleMessage("País"),
        "create": MessageLookupByLibrary.simpleMessage("Crear"),
        "createAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Crear cita"),
        "createClient": MessageLookupByLibrary.simpleMessage("Crear cliente"),
        "createRequest":
            MessageLookupByLibrary.simpleMessage("Crear solicitud"),
        "cutilage": MessageLookupByLibrary.simpleMessage("Cutilaje"),
        "days": MessageLookupByLibrary.simpleMessage("Días"),
        "delete": MessageLookupByLibrary.simpleMessage("Eliminar"),
        "deleteAppointmentBody": MessageLookupByLibrary.simpleMessage(
            "Esta acción no se puede deshacer."),
        "deleteAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("¿Eliminar cita?"),
        "deleteBookingRequests": MessageLookupByLibrary.simpleMessage(
            "¿Eliminar solicitud(es) de reserva?"),
        "deleteClient":
            MessageLookupByLibrary.simpleMessage("Eliminar cliente"),
        "deleteClientConfirm": MessageLookupByLibrary.simpleMessage(
            "Esto eliminará el cliente. ¿Continuar?"),
        "deleteClientTitle":
            MessageLookupByLibrary.simpleMessage("¿Eliminar cliente?"),
        "deleteRequest":
            MessageLookupByLibrary.simpleMessage("Eliminar solicitud"),
        "deleteRequestConfirm": MessageLookupByLibrary.simpleMessage(
            "Esto eliminará esta solicitud de reserva."),
        "deleteRequestTitle":
            MessageLookupByLibrary.simpleMessage("¿Eliminar solicitud?"),
        "deletedPermanently":
            MessageLookupByLibrary.simpleMessage("Eliminado permanentemente"),
        "disableBookingConfirmMany": m2,
        "disableBookingConfirmNone": MessageLookupByLibrary.simpleMessage(
            "Desactivar \'Buscando cita\'. ¿Continuar?"),
        "disableBookingRequests": MessageLookupByLibrary.simpleMessage(
            "¿Desactivar solicitudes de reserva?"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Descartar"),
        "duplicateName":
            MessageLookupByLibrary.simpleMessage("Nombre duplicado"),
        "editAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Editar cita"),
        "editClient": MessageLookupByLibrary.simpleMessage("Editar cliente"),
        "editRequest": MessageLookupByLibrary.simpleMessage("Editar solicitud"),
        "endMustBeAfterStart": MessageLookupByLibrary.simpleMessage(
            "El fin debe ser después del inicio"),
        "errorLoadingServices":
            MessageLookupByLibrary.simpleMessage("Error al cargar servicios"),
        "errorLoadingSpecialists": MessageLookupByLibrary.simpleMessage(
            "Error al cargar especialistas"),
        "errorWithValue": m3,
        "existingBlocks":
            MessageLookupByLibrary.simpleMessage("Bloqueos existentes"),
        "feet": MessageLookupByLibrary.simpleMessage("pies"),
        "fiberA": MessageLookupByLibrary.simpleMessage("Aplicación de Fibra"),
        "fiberM":
            MessageLookupByLibrary.simpleMessage("Mantenimiento de Fibra"),
        "finalPriceOptional":
            MessageLookupByLibrary.simpleMessage("Precio final (opcional)"),
        "firstNameLabel": MessageLookupByLibrary.simpleMessage("Nombre"),
        "firstNameRequired":
            MessageLookupByLibrary.simpleMessage("El nombre es obligatorio"),
        "from": MessageLookupByLibrary.simpleMessage("Desde"),
        "gelA": MessageLookupByLibrary.simpleMessage("Aplicación de Gel"),
        "gelM": MessageLookupByLibrary.simpleMessage("Mantenimiento de Gel"),
        "gelVarnish": MessageLookupByLibrary.simpleMessage(
            "Esmaltado de Gel con Refuerzo"),
        "gelVarnishPedicure": MessageLookupByLibrary.simpleMessage(
            "Pedicura con Esmaltado de Gel"),
        "googleLoginSuccess":
            MessageLookupByLibrary.simpleMessage("Sesión iniciada con Google"),
        "guest": MessageLookupByLibrary.simpleMessage("Invitado"),
        "hands": MessageLookupByLibrary.simpleMessage("manos"),
        "homeTab": MessageLookupByLibrary.simpleMessage("Inicio"),
        "instagram": MessageLookupByLibrary.simpleMessage("Instagram"),
        "instagramOptionalLabel":
            MessageLookupByLibrary.simpleMessage("Instagram (opcional)"),
        "intro": MessageLookupByLibrary.simpleMessage(
            "Manicura, Pedicura y Design de Cejas y Pestañas"),
        "invalidFinalPrice":
            MessageLookupByLibrary.simpleMessage("Precio final inválido"),
        "keep": MessageLookupByLibrary.simpleMessage("Mantener"),
        "language": MessageLookupByLibrary.simpleMessage("Idioma"),
        "lastNameLabel": MessageLookupByLibrary.simpleMessage("Apellido"),
        "lastNameRequired":
            MessageLookupByLibrary.simpleMessage("El apellido es obligatorio"),
        "lastVisit": MessageLookupByLibrary.simpleMessage("Última visita"),
        "logout": MessageLookupByLibrary.simpleMessage("Cerrar sesión"),
        "lookingForAppointment":
            MessageLookupByLibrary.simpleMessage("Buscando cita"),
        "lostClients":
            MessageLookupByLibrary.simpleMessage("Clientes perdidos"),
        "lostClientsButton": MessageLookupByLibrary.simpleMessage(
            "Clientes perdidos  (30d+ / 45d+)"),
        "lostClientsTab":
            MessageLookupByLibrary.simpleMessage("Perdidos (45d+)"),
        "mapsTab": MessageLookupByLibrary.simpleMessage("Mapas"),
        "markedAsCancelled":
            MessageLookupByLibrary.simpleMessage("Marcado como cancelado"),
        "markedAsConfirmed": MessageLookupByLibrary.simpleMessage(
            "Marcado como cita confirmada."),
        "markedAsNoShow":
            MessageLookupByLibrary.simpleMessage("Marcado como no se presentó"),
        "markedAsReservation": MessageLookupByLibrary.simpleMessage(
            "Marcado como reserva: confirmación pendiente."),
        "modeCancelled": MessageLookupByLibrary.simpleMessage("Cancelados"),
        "modeExisting": MessageLookupByLibrary.simpleMessage("Existente"),
        "modeLooking": MessageLookupByLibrary.simpleMessage("Buscando"),
        "modeNew": MessageLookupByLibrary.simpleMessage("Nuevo"),
        "modeNoShow": MessageLookupByLibrary.simpleMessage("No vino"),
        "monthApr": MessageLookupByLibrary.simpleMessage("Abr"),
        "monthAug": MessageLookupByLibrary.simpleMessage("Ago"),
        "monthDec": MessageLookupByLibrary.simpleMessage("Dic"),
        "monthFeb": MessageLookupByLibrary.simpleMessage("Feb"),
        "monthJan": MessageLookupByLibrary.simpleMessage("Ene"),
        "monthJul": MessageLookupByLibrary.simpleMessage("Jul"),
        "monthJun": MessageLookupByLibrary.simpleMessage("Jun"),
        "monthMar": MessageLookupByLibrary.simpleMessage("Mar"),
        "monthMay": MessageLookupByLibrary.simpleMessage("May"),
        "monthNov": MessageLookupByLibrary.simpleMessage("Nov"),
        "monthOct": MessageLookupByLibrary.simpleMessage("Oct"),
        "monthSep": MessageLookupByLibrary.simpleMessage("Sep"),
        "mostCommonBadge": MessageLookupByLibrary.simpleMessage("Más común"),
        "myError": MessageLookupByLibrary.simpleMessage("Mi error"),
        "myStats": MessageLookupByLibrary.simpleMessage("Mis estadísticas"),
        "nailDecorations": MessageLookupByLibrary.simpleMessage("Decoraciones"),
        "nailRecomposition":
            MessageLookupByLibrary.simpleMessage("Recomposición de Uñas"),
        "nailRemove": MessageLookupByLibrary.simpleMessage("Retirar Uñas"),
        "newAppointment": MessageLookupByLibrary.simpleMessage("Nueva cita"),
        "newBookingRequest":
            MessageLookupByLibrary.simpleMessage("Nueva solicitud de reserva"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "noAccess": MessageLookupByLibrary.simpleMessage("Sin acceso"),
        "noActiveBookingRequests": MessageLookupByLibrary.simpleMessage(
            "Sin solicitudes activas ahora."),
        "noAppointmentsForDay":
            MessageLookupByLibrary.simpleMessage("Sin citas para este día"),
        "noAtRiskClients": MessageLookupByLibrary.simpleMessage(
            "Sin clientes en riesgo ahora"),
        "noAvailability":
            MessageLookupByLibrary.simpleMessage("Sin disponibilidad"),
        "noClientsMatchFilter": MessageLookupByLibrary.simpleMessage(
            "Ningún cliente coincide con el filtro."),
        "noLostClients":
            MessageLookupByLibrary.simpleMessage("Sin clientes perdidos ahora"),
        "noMatches": MessageLookupByLibrary.simpleMessage("Sin resultados"),
        "noNotifications":
            MessageLookupByLibrary.simpleMessage("Sin notificaciones."),
        "noPastAppointments":
            MessageLookupByLibrary.simpleMessage("Sin citas pasadas"),
        "noPhotos": MessageLookupByLibrary.simpleMessage("Aún no hay fotos"),
        "noRolesAssigned":
            MessageLookupByLibrary.simpleMessage("Sin roles asignados"),
        "noServicesAssigned":
            MessageLookupByLibrary.simpleMessage("No hay servicios asignados"),
        "noServicesFound":
            MessageLookupByLibrary.simpleMessage("No se encontraron servicios"),
        "noShow": MessageLookupByLibrary.simpleMessage("No se presentó"),
        "noSpecialistsFound": MessageLookupByLibrary.simpleMessage(
            "No se encontraron especialistas"),
        "noUpcomingAppointments":
            MessageLookupByLibrary.simpleMessage("Sin próximas citas"),
        "none": MessageLookupByLibrary.simpleMessage("Ninguno"),
        "notLooking":
            MessageLookupByLibrary.simpleMessage("Sin búsqueda activa"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notificaciones"),
        "openUrlError": m4,
        "past": MessageLookupByLibrary.simpleMessage("Pasadas"),
        "pendingConfirmation":
            MessageLookupByLibrary.simpleMessage("Confirmación pendiente"),
        "pendingConfirmationLabel":
            MessageLookupByLibrary.simpleMessage("PENDIENTE"),
        "pendingConfirmationMsg": MessageLookupByLibrary.simpleMessage(
            "El cliente aún necesita confirmar este horario."),
        "phoneLabel": MessageLookupByLibrary.simpleMessage("Teléfono"),
        "phoneOrInstagramRequired": MessageLookupByLibrary.simpleMessage(
            "Se requiere teléfono o Instagram"),
        "phoneOrInstagramRequiredMsg": MessageLookupByLibrary.simpleMessage(
            "Se requiere teléfono o Instagram"),
        "pickEndTime":
            MessageLookupByLibrary.simpleMessage("Elegir hora de fin"),
        "pickPreferredDay":
            MessageLookupByLibrary.simpleMessage("Elegir día preferido"),
        "pickProcedureTitle":
            MessageLookupByLibrary.simpleMessage("Selecciona un procedimiento"),
        "pickStartTime":
            MessageLookupByLibrary.simpleMessage("Elegir hora de inicio"),
        "pickTypeTitle":
            MessageLookupByLibrary.simpleMessage("Selecciona un tipo"),
        "price": m5,
        "priceLabel": m6,
        "priceOnRequest":
            MessageLookupByLibrary.simpleMessage("Precio a solicitud"),
        "procedureLabel": MessageLookupByLibrary.simpleMessage("Procedimiento"),
        "procedureRequired": MessageLookupByLibrary.simpleMessage(
            "El procedimiento es obligatorio"),
        "procedures": MessageLookupByLibrary.simpleMessage("procedimientos"),
        "profileTab": MessageLookupByLibrary.simpleMessage("Perfil"),
        "rangeMustBeAtLeast": m7,
        "ranges": MessageLookupByLibrary.simpleMessage("Intervalos"),
        "reasonOptional":
            MessageLookupByLibrary.simpleMessage("Motivo (opcional)"),
        "remove": MessageLookupByLibrary.simpleMessage("Eliminar"),
        "removeAppointment":
            MessageLookupByLibrary.simpleMessage("Eliminar cita"),
        "removeBlock":
            MessageLookupByLibrary.simpleMessage("¿Eliminar bloqueo?"),
        "removePermanently": MessageLookupByLibrary.simpleMessage(
            "Eliminar permanentemente (reserva incorrecta)"),
        "request": MessageLookupByLibrary.simpleMessage("Solicitud"),
        "requestUpdated":
            MessageLookupByLibrary.simpleMessage("Solicitud actualizada"),
        "required": MessageLookupByLibrary.simpleMessage("Obligatorio"),
        "reservationPending": MessageLookupByLibrary.simpleMessage(
            "Reserva (confirmación pendiente)"),
        "results": MessageLookupByLibrary.simpleMessage("Resultados"),
        "revenue": MessageLookupByLibrary.simpleMessage("ingresos"),
        "roles": MessageLookupByLibrary.simpleMessage("Roles"),
        "save": MessageLookupByLibrary.simpleMessage("Guardar"),
        "saveClient": MessageLookupByLibrary.simpleMessage("Guardar cliente"),
        "schedule": MessageLookupByLibrary.simpleMessage("Horario"),
        "searchClientLabel": MessageLookupByLibrary.simpleMessage(
            "Buscar (nombre / teléfono / instagram)"),
        "searchEllipsis": MessageLookupByLibrary.simpleMessage("Buscar..."),
        "searchHint": MessageLookupByLibrary.simpleMessage("Buscar"),
        "seeking": MessageLookupByLibrary.simpleMessage("Buscando"),
        "selectExistingClient": MessageLookupByLibrary.simpleMessage(
            "Selecciona un cliente existente"),
        "selectProcedureFirst": MessageLookupByLibrary.simpleMessage(
            "Selecciona primero un procedimiento"),
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
        "servicesStillLoading": MessageLookupByLibrary.simpleMessage(
            "Los servicios aún están cargando..."),
        "signInToManage": MessageLookupByLibrary.simpleMessage(
            "Inicia sesión para gestionar tus citas"),
        "simplePedicure":
            MessageLookupByLibrary.simpleMessage("Pedicura Simple"),
        "simpleVarnish":
            MessageLookupByLibrary.simpleMessage("Esmaltado Simple"),
        "start": MessageLookupByLibrary.simpleMessage("Comenzar"),
        "startAdminMode":
            MessageLookupByLibrary.simpleMessage("Iniciar modo admin"),
        "statAttended": MessageLookupByLibrary.simpleMessage("Asistió"),
        "statCancelled": MessageLookupByLibrary.simpleMessage("Cancelada"),
        "statLastAppt": MessageLookupByLibrary.simpleMessage("Última visita"),
        "statNoShow": MessageLookupByLibrary.simpleMessage("No se presentó"),
        "statRequested": MessageLookupByLibrary.simpleMessage("Solicitadas"),
        "statusAttended": MessageLookupByLibrary.simpleMessage("Asistió"),
        "statusCancelled": MessageLookupByLibrary.simpleMessage("Cancelada"),
        "statusDone": MessageLookupByLibrary.simpleMessage("Realizada"),
        "statusNoShow": MessageLookupByLibrary.simpleMessage("No se presentó"),
        "statusScheduled": MessageLookupByLibrary.simpleMessage("Programada"),
        "subtitleCancelled": MessageLookupByLibrary.simpleMessage(
            "Más cancelaciones (después más asistidos)"),
        "subtitleLooking":
            MessageLookupByLibrary.simpleMessage("Clientes buscando cita"),
        "subtitleNoShow": MessageLookupByLibrary.simpleMessage(
            "Más ausencias (después más asistidos)"),
        "successBooking": MessageLookupByLibrary.simpleMessage(
            "¡Tu cita ha sido confirmada!"),
        "tabInfo": MessageLookupByLibrary.simpleMessage("Info"),
        "tabPortfolio": MessageLookupByLibrary.simpleMessage("Portfolio"),
        "tapToOpenClient":
            MessageLookupByLibrary.simpleMessage("Toca para abrir el cliente"),
        "tapToViewProfile": MessageLookupByLibrary.simpleMessage("Ver perfil"),
        "timeIsConfirmed":
            MessageLookupByLibrary.simpleMessage("Horario confirmado."),
        "timeMinutesEmpty": MessageLookupByLibrary.simpleMessage("Tiempo: —"),
        "timeMinutesLabel": m8,
        "timeRequired":
            MessageLookupByLibrary.simpleMessage("La hora es obligatoria"),
        "tipAddDays": MessageLookupByLibrary.simpleMessage(
            "Tip: añade uno o más días y, opcionalmente, intervalos de tiempo."),
        "title":
            MessageLookupByLibrary.simpleMessage("Geisimara Nail Designer"),
        "typeLabel": MessageLookupByLibrary.simpleMessage("Tipo"),
        "typeRequired":
            MessageLookupByLibrary.simpleMessage("El tipo es obligatorio"),
        "unknown": MessageLookupByLibrary.simpleMessage("Desconocido"),
        "upcoming": MessageLookupByLibrary.simpleMessage("Próximas"),
        "upcomingAppointments":
            MessageLookupByLibrary.simpleMessage("Próximas citas"),
        "userRole": MessageLookupByLibrary.simpleMessage("Usuario"),
        "viewDay": MessageLookupByLibrary.simpleMessage("Día"),
        "viewProfileAndCatalog":
            MessageLookupByLibrary.simpleMessage("Ver perfil y catálogo"),
        "viewWeek": MessageLookupByLibrary.simpleMessage("Semana"),
        "weekdayFri": MessageLookupByLibrary.simpleMessage("Vie"),
        "weekdayMon": MessageLookupByLibrary.simpleMessage("Lun"),
        "weekdaySat": MessageLookupByLibrary.simpleMessage("Sáb"),
        "weekdaySun": MessageLookupByLibrary.simpleMessage("Dom"),
        "weekdayThu": MessageLookupByLibrary.simpleMessage("Jue"),
        "weekdayTue": MessageLookupByLibrary.simpleMessage("Mar"),
        "weekdayWed": MessageLookupByLibrary.simpleMessage("Mié"),
        "worker": MessageLookupByLibrary.simpleMessage("Trabajadora"),
        "workerId": MessageLookupByLibrary.simpleMessage("ID de Trabajadora"),
        "workerNotFound":
            MessageLookupByLibrary.simpleMessage("Trabajador no encontrado"),
        "workerRole": MessageLookupByLibrary.simpleMessage("Trabajadora")
      };
}
