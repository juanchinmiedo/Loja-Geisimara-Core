// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a pt_BR locale. All the
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
  String get localeName => 'pt_BR';

  static String m0(count) =>
      "${Intl.plural(count, zero: 'Sem agendamentos', one: '1 agendamento', other: '${count} agendamentos')}";

  static String m1(date) => "Bloquear horário – ${date}";

  static String m2(count) =>
      "Eliminar todos os ${count} pedidos ativos e desativar?";

  static String m3(value) => "Erro: ${value}";

  static String m4(url) => "Não foi possível abrir ${url}";

  static String m5(price) => "Preço: ${price}";

  static String m6(value) => "Preço: €${value}";

  static String m7(dur) => "O intervalo deve ter pelo menos ${dur} min";

  static String m8(minutes) => "Tempo: ${minutes}m";

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
        "aboutMe": MessageLookupByLibrary.simpleMessage("Sobre mim"),
        "access": MessageLookupByLibrary.simpleMessage("Acesso"),
        "acrylicA":
            MessageLookupByLibrary.simpleMessage("Aplicação de Acrílico"),
        "acrylicM":
            MessageLookupByLibrary.simpleMessage("Manutenção de Acrílico"),
        "activeBookingRequests":
            MessageLookupByLibrary.simpleMessage("Pedidos de marcação ativos"),
        "add": MessageLookupByLibrary.simpleMessage("Adicionar"),
        "addDay": MessageLookupByLibrary.simpleMessage("Adicionar dia"),
        "addNewBlock":
            MessageLookupByLibrary.simpleMessage("Adicionar novo bloqueio"),
        "addRange":
            MessageLookupByLibrary.simpleMessage("+ Adicionar intervalo"),
        "adminHome": MessageLookupByLibrary.simpleMessage("Início Admin"),
        "adminModeEnabled":
            MessageLookupByLibrary.simpleMessage("Modo admin ativado"),
        "adminRole": MessageLookupByLibrary.simpleMessage("Admin"),
        "adminSchedule": MessageLookupByLibrary.simpleMessage("Agenda Admin"),
        "adminWorkerRole":
            MessageLookupByLibrary.simpleMessage("Admin + Trabalhadora"),
        "all": MessageLookupByLibrary.simpleMessage("Todos"),
        "any": MessageLookupByLibrary.simpleMessage("Qualquer"),
        "anyTime": MessageLookupByLibrary.simpleMessage("Qualquer hora"),
        "appTitle": MessageLookupByLibrary.simpleMessage("Salão de Manicure"),
        "appointmentCreated":
            MessageLookupByLibrary.simpleMessage("Marcação criada"),
        "appointmentDeleted":
            MessageLookupByLibrary.simpleMessage("Marcação eliminada"),
        "appointmentUpdated":
            MessageLookupByLibrary.simpleMessage("Marcação atualizada"),
        "appointments": MessageLookupByLibrary.simpleMessage("Marcações"),
        "appointmentsCount": m0,
        "atRiskClients":
            MessageLookupByLibrary.simpleMessage("Em risco (30–45d)"),
        "attended": MessageLookupByLibrary.simpleMessage("Compareceu"),
        "blockThisTime":
            MessageLookupByLibrary.simpleMessage("Bloquear este horário"),
        "blockTimeDateLabel": m1,
        "bookNowButton": MessageLookupByLibrary.simpleMessage("Reservar agora"),
        "bookNowSubtitle": MessageLookupByLibrary.simpleMessage(
            "Agende sua consulta em poucos segundos"),
        "bookNowTitle":
            MessageLookupByLibrary.simpleMessage("Agendar Marcação"),
        "bookingRequest":
            MessageLookupByLibrary.simpleMessage("Pedido de marcação"),
        "bookingRequestCreated":
            MessageLookupByLibrary.simpleMessage("Pedido de marcação criado"),
        "bookingTab": MessageLookupByLibrary.simpleMessage("Agendamento"),
        "bottom_navigationbar": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "category": MessageLookupByLibrary.simpleMessage("Categoria"),
        "checking": MessageLookupByLibrary.simpleMessage("A verificar…"),
        "clientCancelledAppointment":
            MessageLookupByLibrary.simpleMessage("Cliente cancelou a marcação"),
        "clientCreated": MessageLookupByLibrary.simpleMessage("Cliente criado"),
        "clientDeleted":
            MessageLookupByLibrary.simpleMessage("Cliente eliminado"),
        "clientDidNotAttend":
            MessageLookupByLibrary.simpleMessage("Cliente não compareceu"),
        "clientFallback": MessageLookupByLibrary.simpleMessage("Cliente"),
        "clientUpdated":
            MessageLookupByLibrary.simpleMessage("Cliente atualizado"),
        "clientsNoVisitRecently":
            MessageLookupByLibrary.simpleMessage("Clientes sem visita recente"),
        "clientsTab": MessageLookupByLibrary.simpleMessage("Clientes"),
        "close": MessageLookupByLibrary.simpleMessage("Fechar"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
        "confirmBooking":
            MessageLookupByLibrary.simpleMessage("Confirmar agendamento"),
        "console_firebase_database": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente"),
        "continueAsGuest":
            MessageLookupByLibrary.simpleMessage("Continuar como convidado"),
        "continueWithGoogle":
            MessageLookupByLibrary.simpleMessage("Continuar com Google"),
        "countryCode": MessageLookupByLibrary.simpleMessage("Código do país"),
        "countryLabel": MessageLookupByLibrary.simpleMessage("País"),
        "create": MessageLookupByLibrary.simpleMessage("Criar"),
        "createAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Criar marcação"),
        "createClient": MessageLookupByLibrary.simpleMessage("Criar cliente"),
        "createRequest": MessageLookupByLibrary.simpleMessage("Criar pedido"),
        "cutilage": MessageLookupByLibrary.simpleMessage("Cutilagem"),
        "days": MessageLookupByLibrary.simpleMessage("Dias"),
        "delete": MessageLookupByLibrary.simpleMessage("Eliminar"),
        "deleteAppointmentBody": MessageLookupByLibrary.simpleMessage(
            "Esta ação não pode ser desfeita."),
        "deleteAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Eliminar marcação?"),
        "deleteBookingRequests": MessageLookupByLibrary.simpleMessage(
            "Eliminar pedido(s) de marcação?"),
        "deleteClient":
            MessageLookupByLibrary.simpleMessage("Eliminar cliente"),
        "deleteClientConfirm": MessageLookupByLibrary.simpleMessage(
            "Isto irá eliminar o cliente. Continuar?"),
        "deleteClientTitle":
            MessageLookupByLibrary.simpleMessage("Eliminar cliente?"),
        "deleteRequest":
            MessageLookupByLibrary.simpleMessage("Eliminar pedido"),
        "deleteRequestConfirm": MessageLookupByLibrary.simpleMessage(
            "Isto irá eliminar este pedido de marcação."),
        "deleteRequestTitle":
            MessageLookupByLibrary.simpleMessage("Eliminar pedido?"),
        "deletedPermanently":
            MessageLookupByLibrary.simpleMessage("Eliminado permanentemente"),
        "disableBookingConfirmMany": m2,
        "disableBookingConfirmNone": MessageLookupByLibrary.simpleMessage(
            "Desativar \'À procura de marcação\'. Continuar?"),
        "disableBookingRequests": MessageLookupByLibrary.simpleMessage(
            "Desativar pedidos de marcação?"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Dispensar"),
        "duplicateName": MessageLookupByLibrary.simpleMessage("Nome duplicado"),
        "editAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Editar marcação"),
        "editClient": MessageLookupByLibrary.simpleMessage("Editar cliente"),
        "editRequest": MessageLookupByLibrary.simpleMessage("Editar pedido"),
        "endMustBeAfterStart": MessageLookupByLibrary.simpleMessage(
            "O fim deve ser depois do início"),
        "errorLoadingServices":
            MessageLookupByLibrary.simpleMessage("Erro ao carregar serviços"),
        "errorLoadingSpecialists": MessageLookupByLibrary.simpleMessage(
            "Erro ao carregar especialistas"),
        "errorWithValue": m3,
        "existingBlocks":
            MessageLookupByLibrary.simpleMessage("Bloqueios existentes"),
        "feet": MessageLookupByLibrary.simpleMessage("pés"),
        "fiberA": MessageLookupByLibrary.simpleMessage("Aplicação de Fibra"),
        "fiberM": MessageLookupByLibrary.simpleMessage("Manutenção de Fibra"),
        "finalPriceOptional":
            MessageLookupByLibrary.simpleMessage("Preço final (opcional)"),
        "firstNameLabel": MessageLookupByLibrary.simpleMessage("Nome"),
        "firstNameRequired":
            MessageLookupByLibrary.simpleMessage("O nome é obrigatório"),
        "from": MessageLookupByLibrary.simpleMessage("De"),
        "gelA": MessageLookupByLibrary.simpleMessage("Aplicação de Gel"),
        "gelM": MessageLookupByLibrary.simpleMessage("Manutenção de Gel"),
        "gelVarnish":
            MessageLookupByLibrary.simpleMessage("Verniz de Gel com Reforço"),
        "gelVarnishPedicure":
            MessageLookupByLibrary.simpleMessage("Pedicure com Verniz de Gel"),
        "googleLoginSuccess":
            MessageLookupByLibrary.simpleMessage("Sessão iniciada com Google"),
        "guest": MessageLookupByLibrary.simpleMessage("Convidado"),
        "hands": MessageLookupByLibrary.simpleMessage("mãos"),
        "homeTab": MessageLookupByLibrary.simpleMessage("Inicio"),
        "instagram": MessageLookupByLibrary.simpleMessage("Instagram"),
        "instagramOptionalLabel":
            MessageLookupByLibrary.simpleMessage("Instagram (opcional)"),
        "intro": MessageLookupByLibrary.simpleMessage(
            "Manicure, Pedicure e Design de Sobrancelhas e Cilios"),
        "invalidFinalPrice":
            MessageLookupByLibrary.simpleMessage("Preço final inválido"),
        "keep": MessageLookupByLibrary.simpleMessage("Manter"),
        "language": MessageLookupByLibrary.simpleMessage("Idioma"),
        "lastNameLabel": MessageLookupByLibrary.simpleMessage("Apelido"),
        "lastNameRequired":
            MessageLookupByLibrary.simpleMessage("O apelido é obrigatório"),
        "lastVisit": MessageLookupByLibrary.simpleMessage("Última visita"),
        "logout": MessageLookupByLibrary.simpleMessage("Fechar sessão"),
        "lookingForAppointment":
            MessageLookupByLibrary.simpleMessage("À procura de marcação"),
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
            "Marcado como marcação confirmada."),
        "markedAsNoShow":
            MessageLookupByLibrary.simpleMessage("Marcado como faltou"),
        "markedAsReservation": MessageLookupByLibrary.simpleMessage(
            "Marcado como reserva: confirmação pendente."),
        "modeCancelled": MessageLookupByLibrary.simpleMessage("Cancelados"),
        "modeExisting": MessageLookupByLibrary.simpleMessage("Existente"),
        "modeLooking": MessageLookupByLibrary.simpleMessage("À procura"),
        "modeNew": MessageLookupByLibrary.simpleMessage("Novo"),
        "modeNoShow": MessageLookupByLibrary.simpleMessage("Faltou"),
        "mostCommonBadge": MessageLookupByLibrary.simpleMessage("Mais comum"),
        "myError": MessageLookupByLibrary.simpleMessage("Erro meu"),
        "nailDecorations": MessageLookupByLibrary.simpleMessage("Decorações"),
        "nailRecomposition":
            MessageLookupByLibrary.simpleMessage("Recomposição de Unhas"),
        "nailRemove": MessageLookupByLibrary.simpleMessage("Remover Unhas"),
        "newAppointment": MessageLookupByLibrary.simpleMessage("Nova marcação"),
        "newBookingRequest":
            MessageLookupByLibrary.simpleMessage("Novo pedido de marcação"),
        "no": MessageLookupByLibrary.simpleMessage("Não"),
        "noAccess": MessageLookupByLibrary.simpleMessage("Sem acesso"),
        "noActiveBookingRequests": MessageLookupByLibrary.simpleMessage(
            "Sem pedidos de marcação ativos agora."),
        "noAppointmentsForDay":
            MessageLookupByLibrary.simpleMessage("Sem marcações para este dia"),
        "noAtRiskClients":
            MessageLookupByLibrary.simpleMessage("Sem clientes em risco agora"),
        "noAvailability":
            MessageLookupByLibrary.simpleMessage("Sem disponibilidade"),
        "noClientsMatchFilter": MessageLookupByLibrary.simpleMessage(
            "Nenhum cliente corresponde ao filtro."),
        "noLostClients":
            MessageLookupByLibrary.simpleMessage("Sem clientes perdidos agora"),
        "noMatches": MessageLookupByLibrary.simpleMessage("Sem resultados"),
        "noNotifications":
            MessageLookupByLibrary.simpleMessage("Sem notificações."),
        "noPastAppointments":
            MessageLookupByLibrary.simpleMessage("Sem marcações passadas"),
        "noPhotos": MessageLookupByLibrary.simpleMessage("Ainda não há fotos"),
        "noRolesAssigned":
            MessageLookupByLibrary.simpleMessage("Sem funções atribuídas"),
        "noServicesAssigned":
            MessageLookupByLibrary.simpleMessage("Nenhum serviço atribuído"),
        "noServicesFound":
            MessageLookupByLibrary.simpleMessage("Nenhum serviço encontrado"),
        "noShow": MessageLookupByLibrary.simpleMessage("Faltou"),
        "noSpecialistsFound": MessageLookupByLibrary.simpleMessage(
            "Nenhum especialista encontrado"),
        "noUpcomingAppointments":
            MessageLookupByLibrary.simpleMessage("Sem próximas marcações"),
        "none": MessageLookupByLibrary.simpleMessage("Nenhum"),
        "notLooking":
            MessageLookupByLibrary.simpleMessage("Sem procura activa"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notificações"),
        "openUrlError": m4,
        "past": MessageLookupByLibrary.simpleMessage("Passadas"),
        "pendingConfirmation":
            MessageLookupByLibrary.simpleMessage("Confirmação pendente"),
        "pendingConfirmationLabel":
            MessageLookupByLibrary.simpleMessage("PENDENTE"),
        "pendingConfirmationMsg": MessageLookupByLibrary.simpleMessage(
            "O cliente ainda precisa de confirmar este horário."),
        "phoneLabel": MessageLookupByLibrary.simpleMessage("Telefone"),
        "phoneOrInstagramRequired": MessageLookupByLibrary.simpleMessage(
            "É necessário telefone ou Instagram"),
        "phoneOrInstagramRequiredMsg": MessageLookupByLibrary.simpleMessage(
            "Telefone ou Instagram é obrigatório"),
        "pickEndTime":
            MessageLookupByLibrary.simpleMessage("Escolher hora de fim"),
        "pickPreferredDay":
            MessageLookupByLibrary.simpleMessage("Escolher dia preferido"),
        "pickProcedureTitle":
            MessageLookupByLibrary.simpleMessage("Selecione um procedimento"),
        "pickStartTime":
            MessageLookupByLibrary.simpleMessage("Escolher hora de início"),
        "pickTypeTitle":
            MessageLookupByLibrary.simpleMessage("Selecione um tipo"),
        "price": m5,
        "priceLabel": m6,
        "priceOnRequest":
            MessageLookupByLibrary.simpleMessage("Preço sob consulta"),
        "procedureLabel": MessageLookupByLibrary.simpleMessage("Procedimento"),
        "procedureRequired": MessageLookupByLibrary.simpleMessage(
            "O procedimento é obrigatório"),
        "profileTab": MessageLookupByLibrary.simpleMessage("Perfil"),
        "rangeMustBeAtLeast": m7,
        "ranges": MessageLookupByLibrary.simpleMessage("Intervalos"),
        "reasonOptional":
            MessageLookupByLibrary.simpleMessage("Motivo (opcional)"),
        "remove": MessageLookupByLibrary.simpleMessage("Remover"),
        "removeAppointment":
            MessageLookupByLibrary.simpleMessage("Remover marcação"),
        "removeBlock":
            MessageLookupByLibrary.simpleMessage("Remover bloqueio?"),
        "removePermanently": MessageLookupByLibrary.simpleMessage(
            "Remover permanentemente (reserva errada)"),
        "request": MessageLookupByLibrary.simpleMessage("Pedido"),
        "requestUpdated":
            MessageLookupByLibrary.simpleMessage("Pedido atualizado"),
        "required": MessageLookupByLibrary.simpleMessage("Obrigatório"),
        "reservationPending": MessageLookupByLibrary.simpleMessage(
            "Reserva (confirmação pendente)"),
        "results": MessageLookupByLibrary.simpleMessage("Resultados"),
        "roles": MessageLookupByLibrary.simpleMessage("Funções"),
        "save": MessageLookupByLibrary.simpleMessage("Guardar"),
        "saveClient": MessageLookupByLibrary.simpleMessage("Guardar cliente"),
        "schedule": MessageLookupByLibrary.simpleMessage("Agenda"),
        "searchClientLabel": MessageLookupByLibrary.simpleMessage(
            "Pesquisar (nome / telefone / instagram)"),
        "searchEllipsis": MessageLookupByLibrary.simpleMessage("Pesquisar..."),
        "searchHint": MessageLookupByLibrary.simpleMessage("Pesquisar"),
        "seeking": MessageLookupByLibrary.simpleMessage("À procura"),
        "selectExistingClient": MessageLookupByLibrary.simpleMessage(
            "Selecione um cliente existente"),
        "selectProcedureFirst": MessageLookupByLibrary.simpleMessage(
            "Selecione primeiro um procedimento"),
        "selectProcedureHelper": MessageLookupByLibrary.simpleMessage(
            "Por favor selecione um procedimento"),
        "selectProcedurePlaceholder":
            MessageLookupByLibrary.simpleMessage("Selecionar Procedimento"),
        "selectTimePlaceholder":
            MessageLookupByLibrary.simpleMessage("Selecionar hora"),
        "selectTypePlaceholder":
            MessageLookupByLibrary.simpleMessage("Selecionar Tipo"),
        "serviceFallback": MessageLookupByLibrary.simpleMessage("Serviço"),
        "services": MessageLookupByLibrary.simpleMessage("serviços"),
        "servicesStillLoading": MessageLookupByLibrary.simpleMessage(
            "Os serviços ainda estão a carregar..."),
        "signInToManage": MessageLookupByLibrary.simpleMessage(
            "Inicie sessão para gerir as suas marcações"),
        "simplePedicure":
            MessageLookupByLibrary.simpleMessage("Pedicure Simples"),
        "simpleVarnish": MessageLookupByLibrary.simpleMessage("Verniz Simples"),
        "start": MessageLookupByLibrary.simpleMessage("Começar"),
        "startAdminMode":
            MessageLookupByLibrary.simpleMessage("Iniciar modo admin"),
        "subtitleCancelled": MessageLookupByLibrary.simpleMessage(
            "Mais cancelamentos (depois mais assistidos)"),
        "subtitleLooking": MessageLookupByLibrary.simpleMessage(
            "Clientes à procura de marcação"),
        "subtitleNoShow": MessageLookupByLibrary.simpleMessage(
            "Mais faltas (depois mais assistidos)"),
        "successBooking": MessageLookupByLibrary.simpleMessage(
            "Seu agendamento foi confirmado!"),
        "tabInfo": MessageLookupByLibrary.simpleMessage("Info"),
        "tabPortfolio": MessageLookupByLibrary.simpleMessage("Portfolio"),
        "tapToOpenClient":
            MessageLookupByLibrary.simpleMessage("Toque para abrir o cliente"),
        "tapToViewProfile": MessageLookupByLibrary.simpleMessage("Ver perfil"),
        "timeIsConfirmed":
            MessageLookupByLibrary.simpleMessage("Horário confirmado."),
        "timeMinutesEmpty": MessageLookupByLibrary.simpleMessage("Tempo: —"),
        "timeMinutesLabel": m8,
        "timeRequired":
            MessageLookupByLibrary.simpleMessage("A hora é obrigatória"),
        "tipAddDays": MessageLookupByLibrary.simpleMessage(
            "Dica: adicione um ou mais dias e, opcionalmente, intervalos de tempo."),
        "title":
            MessageLookupByLibrary.simpleMessage("Geisimara Nail Designer"),
        "typeLabel": MessageLookupByLibrary.simpleMessage("Tipo"),
        "typeRequired":
            MessageLookupByLibrary.simpleMessage("O tipo é obrigatório"),
        "unknown": MessageLookupByLibrary.simpleMessage("Desconhecido"),
        "upcoming": MessageLookupByLibrary.simpleMessage("Próximas"),
        "upcomingAppointments":
            MessageLookupByLibrary.simpleMessage("Próximas marcações"),
        "userRole": MessageLookupByLibrary.simpleMessage("Utilizador"),
        "viewDay": MessageLookupByLibrary.simpleMessage("Dia"),
        "viewProfileAndCatalog":
            MessageLookupByLibrary.simpleMessage("Ver perfil e catálogo"),
        "viewWeek": MessageLookupByLibrary.simpleMessage("Semana"),
        "weekdayFri": MessageLookupByLibrary.simpleMessage("Sex"),
        "weekdayMon": MessageLookupByLibrary.simpleMessage("Seg"),
        "weekdaySat": MessageLookupByLibrary.simpleMessage("Sáb"),
        "weekdaySun": MessageLookupByLibrary.simpleMessage("Dom"),
        "weekdayThu": MessageLookupByLibrary.simpleMessage("Qui"),
        "weekdayTue": MessageLookupByLibrary.simpleMessage("Ter"),
        "weekdayWed": MessageLookupByLibrary.simpleMessage("Qua"),
        "worker": MessageLookupByLibrary.simpleMessage("Trabalhadora"),
        "workerId": MessageLookupByLibrary.simpleMessage("ID da Trabalhadora"),
        "workerNotFound":
            MessageLookupByLibrary.simpleMessage("Trabalhador não encontrado"),
        "workerRole": MessageLookupByLibrary.simpleMessage("Trabalhadora")
      };
}
