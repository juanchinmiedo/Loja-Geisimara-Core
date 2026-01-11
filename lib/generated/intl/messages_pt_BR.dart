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

  static String m1(value) => "Erro: ${value}";

  static String m2(url) => "Não foi possível abrir ${url}";

  static String m3(price) => "Preço: ${price}";

  static String m4(value) => "Preço: €${value}";

  static String m5(minutes) => "Tempo: ${minutes}m";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "Aservices": MessageLookupByLibrary.simpleMessage("Todos os Serviços"),
        "Aspecialists":
            MessageLookupByLibrary.simpleMessage("Todos os Especialistas"),
        "Bservices": MessageLookupByLibrary.simpleMessage("Melhores Serviços"),
        "Bspecialists":
            MessageLookupByLibrary.simpleMessage("Melhores Especialistas"),
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
        "aboutMe": MessageLookupByLibrary.simpleMessage("Sobre mim"),
        "acrylicA":
            MessageLookupByLibrary.simpleMessage("Aplicação de Acrílico"),
        "acrylicM":
            MessageLookupByLibrary.simpleMessage("Manutenção de Acrílico"),
        "adminModeEnabled":
            MessageLookupByLibrary.simpleMessage("Modo admin ativado"),
        "appTitle": MessageLookupByLibrary.simpleMessage("Salão de Manicure"),
        "appointmentCreated":
            MessageLookupByLibrary.simpleMessage("Marcação criada"),
        "appointmentDeleted":
            MessageLookupByLibrary.simpleMessage("Marcação eliminada"),
        "appointmentUpdated":
            MessageLookupByLibrary.simpleMessage("Marcação atualizada"),
        "appointmentsCount": m0,
        "bookNowButton": MessageLookupByLibrary.simpleMessage("Reservar agora"),
        "bookNowSubtitle": MessageLookupByLibrary.simpleMessage(
            "Agende sua consulta em poucos segundos"),
        "bookNowTitle":
            MessageLookupByLibrary.simpleMessage("Agendar Marcação"),
        "bookingTab": MessageLookupByLibrary.simpleMessage("Agendamento"),
        "bottom_navigationbar": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
        "category": MessageLookupByLibrary.simpleMessage("Categoria"),
        "clientFallback": MessageLookupByLibrary.simpleMessage("Cliente"),
        "clientsTab": MessageLookupByLibrary.simpleMessage("Clientes"),
        "confirmBooking":
            MessageLookupByLibrary.simpleMessage("Confirmar agendamento"),
        "console_firebase_database": MessageLookupByLibrary.simpleMessage(
            "Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente"),
        "continueAsGuest":
            MessageLookupByLibrary.simpleMessage("Continuar como convidado"),
        "continueWithGoogle":
            MessageLookupByLibrary.simpleMessage("Continuar com Google"),
        "countryLabel": MessageLookupByLibrary.simpleMessage("País"),
        "create": MessageLookupByLibrary.simpleMessage("Criar"),
        "createAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Criar marcação"),
        "cutilage": MessageLookupByLibrary.simpleMessage("Cutilagem"),
        "delete": MessageLookupByLibrary.simpleMessage("Eliminar"),
        "deleteAppointmentBody": MessageLookupByLibrary.simpleMessage(
            "Esta ação não pode ser desfeita."),
        "deleteAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Eliminar marcação?"),
        "editAppointmentTitle":
            MessageLookupByLibrary.simpleMessage("Editar marcação"),
        "errorLoadingServices":
            MessageLookupByLibrary.simpleMessage("Erro ao carregar serviços"),
        "errorLoadingSpecialists": MessageLookupByLibrary.simpleMessage(
            "Erro ao carregar especialistas"),
        "errorWithValue": m1,
        "feet": MessageLookupByLibrary.simpleMessage("pés"),
        "fiberA": MessageLookupByLibrary.simpleMessage("Aplicação de Fibra"),
        "fiberM": MessageLookupByLibrary.simpleMessage("Manutenção de Fibra"),
        "firstNameLabel": MessageLookupByLibrary.simpleMessage("Nome"),
        "firstNameRequired":
            MessageLookupByLibrary.simpleMessage("O nome é obrigatório"),
        "gelA": MessageLookupByLibrary.simpleMessage("Aplicação de Gel"),
        "gelM": MessageLookupByLibrary.simpleMessage("Manutenção de Gel"),
        "gelVarnish":
            MessageLookupByLibrary.simpleMessage("Reforço com Verniz de Gel"),
        "gelVarnishPedicure":
            MessageLookupByLibrary.simpleMessage("Pedicure com Verniz de Gel"),
        "googleLoginSuccess":
            MessageLookupByLibrary.simpleMessage("Sessão iniciada com Google"),
        "guest": MessageLookupByLibrary.simpleMessage("Convidado"),
        "hands": MessageLookupByLibrary.simpleMessage("mãos"),
        "homeTab": MessageLookupByLibrary.simpleMessage("Inicio"),
        "instagramOptionalLabel":
            MessageLookupByLibrary.simpleMessage("Instagram (opcional)"),
        "intro": MessageLookupByLibrary.simpleMessage(
            "Manicure, Pedicure e Design de Sobrancelhas e Cilios"),
        "language": MessageLookupByLibrary.simpleMessage("Idioma"),
        "lastNameLabel": MessageLookupByLibrary.simpleMessage("Apelido"),
        "lastNameRequired":
            MessageLookupByLibrary.simpleMessage("O apelido é obrigatório"),
        "logout": MessageLookupByLibrary.simpleMessage("Fechar sessão"),
        "mapsTab": MessageLookupByLibrary.simpleMessage("Mapas"),
        "modeExisting": MessageLookupByLibrary.simpleMessage("Existente"),
        "modeNew": MessageLookupByLibrary.simpleMessage("Novo"),
        "mostCommonBadge": MessageLookupByLibrary.simpleMessage("Mais comum"),
        "nailDecorations": MessageLookupByLibrary.simpleMessage("Decorações"),
        "no": MessageLookupByLibrary.simpleMessage("Não"),
        "noMatches": MessageLookupByLibrary.simpleMessage("Sem resultados"),
        "noPhotos": MessageLookupByLibrary.simpleMessage("Ainda não há fotos"),
        "noServicesAssigned":
            MessageLookupByLibrary.simpleMessage("Nenhum serviço atribuído"),
        "noServicesFound":
            MessageLookupByLibrary.simpleMessage("Nenhum serviço encontrado"),
        "noSpecialistsFound": MessageLookupByLibrary.simpleMessage(
            "Nenhum especialista encontrado"),
        "offers": MessageLookupByLibrary.simpleMessage("Ofertas"),
        "openInMaps":
            MessageLookupByLibrary.simpleMessage("Abrir no Google Maps"),
        "openInMapsError": MessageLookupByLibrary.simpleMessage(
            "Não foi possível abrir o Google Maps"),
        "openUrlError": m2,
        "phoneLabel": MessageLookupByLibrary.simpleMessage("Telefone"),
        "phoneOrInstagramRequired": MessageLookupByLibrary.simpleMessage(
            "É necessário telefone ou Instagram"),
        "pickProcedureTitle":
            MessageLookupByLibrary.simpleMessage("Selecione um procedimento"),
        "pickTypeTitle":
            MessageLookupByLibrary.simpleMessage("Selecione um tipo"),
        "price": m3,
        "priceLabel": m4,
        "priceOnRequest":
            MessageLookupByLibrary.simpleMessage("Preço sob consulta"),
        "procedureLabel": MessageLookupByLibrary.simpleMessage("Procedimento"),
        "procedureRequired": MessageLookupByLibrary.simpleMessage(
            "O procedimento é obrigatório"),
        "profileTab": MessageLookupByLibrary.simpleMessage("Perfil"),
        "save": MessageLookupByLibrary.simpleMessage("Guardar"),
        "schedule": MessageLookupByLibrary.simpleMessage("Agenda"),
        "searchClientLabel": MessageLookupByLibrary.simpleMessage(
            "Pesquisar (nome / telefone / instagram)"),
        "selectExistingClient": MessageLookupByLibrary.simpleMessage(
            "Selecione um cliente existente"),
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
        "simplePedicure":
            MessageLookupByLibrary.simpleMessage("Pedicure Simples"),
        "simpleVarnish": MessageLookupByLibrary.simpleMessage("Verniz Simples"),
        "start": MessageLookupByLibrary.simpleMessage("Começar"),
        "startAdminMode":
            MessageLookupByLibrary.simpleMessage("Iniciar modo admin"),
        "successBooking": MessageLookupByLibrary.simpleMessage(
            "Seu agendamento foi confirmado!"),
        "tabInfo": MessageLookupByLibrary.simpleMessage("Info"),
        "tabPortfolio": MessageLookupByLibrary.simpleMessage("Portfolio"),
        "timeMinutesEmpty": MessageLookupByLibrary.simpleMessage("Tempo: —"),
        "timeMinutesLabel": m5,
        "timeRequired":
            MessageLookupByLibrary.simpleMessage("A hora é obrigatória"),
        "title":
            MessageLookupByLibrary.simpleMessage("Geisimara Nail Designer"),
        "typeLabel": MessageLookupByLibrary.simpleMessage("Tipo"),
        "typeRequired":
            MessageLookupByLibrary.simpleMessage("O tipo é obrigatório"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Ver todo"),
        "viewProfileAndCatalog":
            MessageLookupByLibrary.simpleMessage("Ver perfil e catálogo"),
        "website": MessageLookupByLibrary.simpleMessage("site web"),
        "workerNotFound":
            MessageLookupByLibrary.simpleMessage("Trabalhador não encontrado")
      };
}
