// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente`
  String get console_firebase_database {
    return Intl.message(
      'Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente',
      name: 'console_firebase_database',
      desc: '',
      args: [],
    );
  }

  /// `Aplicação de Gel`
  String get gelA {
    return Intl.message(
      'Aplicação de Gel',
      name: 'gelA',
      desc: '',
      args: [],
    );
  }

  /// `Aplicação de Acrílico`
  String get acrylicA {
    return Intl.message(
      'Aplicação de Acrílico',
      name: 'acrylicA',
      desc: '',
      args: [],
    );
  }

  /// `Aplicação de Fibra`
  String get fiberA {
    return Intl.message(
      'Aplicação de Fibra',
      name: 'fiberA',
      desc: '',
      args: [],
    );
  }

  /// `Manutenção de Gel`
  String get gelM {
    return Intl.message(
      'Manutenção de Gel',
      name: 'gelM',
      desc: '',
      args: [],
    );
  }

  /// `Manutenção de Acrílico`
  String get acrylicM {
    return Intl.message(
      'Manutenção de Acrílico',
      name: 'acrylicM',
      desc: '',
      args: [],
    );
  }

  /// `Manutenção de Fibra`
  String get fiberM {
    return Intl.message(
      'Manutenção de Fibra',
      name: 'fiberM',
      desc: '',
      args: [],
    );
  }

  /// `Verniz Simples`
  String get simpleVarnish {
    return Intl.message(
      'Verniz Simples',
      name: 'simpleVarnish',
      desc: '',
      args: [],
    );
  }

  /// `Remover Unhas`
  String get nailRemove {
    return Intl.message(
      'Remover Unhas',
      name: 'nailRemove',
      desc: '',
      args: [],
    );
  }

  /// `Verniz de Gel com Reforço`
  String get gelVarnish {
    return Intl.message(
      'Verniz de Gel com Reforço',
      name: 'gelVarnish',
      desc: '',
      args: [],
    );
  }

  /// `Cutilagem`
  String get cutilage {
    return Intl.message(
      'Cutilagem',
      name: 'cutilage',
      desc: '',
      args: [],
    );
  }

  /// `Pedicure com Verniz de Gel`
  String get gelVarnishPedicure {
    return Intl.message(
      'Pedicure com Verniz de Gel',
      name: 'gelVarnishPedicure',
      desc: '',
      args: [],
    );
  }

  /// `Pedicure Simples`
  String get simplePedicure {
    return Intl.message(
      'Pedicure Simples',
      name: 'simplePedicure',
      desc: '',
      args: [],
    );
  }

  /// `Decorações`
  String get nailDecorations {
    return Intl.message(
      'Decorações',
      name: 'nailDecorations',
      desc: '',
      args: [],
    );
  }

  /// `Desconhecido`
  String get unknown {
    return Intl.message(
      'Desconhecido',
      name: 'unknown',
      desc: '',
      args: [],
    );
  }

  /// `Recomposição de Unhas`
  String get nailRecomposition {
    return Intl.message(
      'Recomposição de Unhas',
      name: 'nailRecomposition',
      desc: '',
      args: [],
    );
  }

  /// `Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente`
  String get bottom_navigationbar {
    return Intl.message(
      'Esto es un comentario sobre el lugar de donde vienen estos textos para editarlos correctamente',
      name: 'bottom_navigationbar',
      desc: '',
      args: [],
    );
  }

  /// `Inicio`
  String get homeTab {
    return Intl.message(
      'Inicio',
      name: 'homeTab',
      desc: '',
      args: [],
    );
  }

  /// `Mapas`
  String get mapsTab {
    return Intl.message(
      'Mapas',
      name: 'mapsTab',
      desc: '',
      args: [],
    );
  }

  /// `Clientes`
  String get clientsTab {
    return Intl.message(
      'Clientes',
      name: 'clientsTab',
      desc: '',
      args: [],
    );
  }

  /// `Agendamento`
  String get bookingTab {
    return Intl.message(
      'Agendamento',
      name: 'bookingTab',
      desc: '',
      args: [],
    );
  }

  /// `Perfil`
  String get profileTab {
    return Intl.message(
      'Perfil',
      name: 'profileTab',
      desc: '',
      args: [],
    );
  }

  /// `Esto es un comentario sobre el lugar donde estan estos textos`
  String get _carrousel_dart {
    return Intl.message(
      'Esto es un comentario sobre el lugar donde estan estos textos',
      name: '_carrousel_dart',
      desc: '',
      args: [],
    );
  }

  /// `Reservar agora`
  String get bookNowButton {
    return Intl.message(
      'Reservar agora',
      name: 'bookNowButton',
      desc: '',
      args: [],
    );
  }

  /// `Agendar Marcação`
  String get bookNowTitle {
    return Intl.message(
      'Agendar Marcação',
      name: 'bookNowTitle',
      desc: '',
      args: [],
    );
  }

  /// `Agende sua consulta em poucos segundos`
  String get bookNowSubtitle {
    return Intl.message(
      'Agende sua consulta em poucos segundos',
      name: 'bookNowSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Esto es un comentario sobre el lugar donde estan estos textos`
  String get _onboarding_screenn {
    return Intl.message(
      'Esto es un comentario sobre el lugar donde estan estos textos',
      name: '_onboarding_screenn',
      desc: '',
      args: [],
    );
  }

  /// `Geisimara Nail Designer`
  String get title {
    return Intl.message(
      'Geisimara Nail Designer',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `Manicure, Pedicure e Design de Sobrancelhas e Cilios`
  String get intro {
    return Intl.message(
      'Manicure, Pedicure e Design de Sobrancelhas e Cilios',
      name: 'intro',
      desc: '',
      args: [],
    );
  }

  /// `Começar`
  String get start {
    return Intl.message(
      'Começar',
      name: 'start',
      desc: '',
      args: [],
    );
  }

  /// `Continuar com Google`
  String get continueWithGoogle {
    return Intl.message(
      'Continuar com Google',
      name: 'continueWithGoogle',
      desc: '',
      args: [],
    );
  }

  /// `Iniciar modo admin`
  String get startAdminMode {
    return Intl.message(
      'Iniciar modo admin',
      name: 'startAdminMode',
      desc: '',
      args: [],
    );
  }

  /// `Modo admin ativado`
  String get adminModeEnabled {
    return Intl.message(
      'Modo admin ativado',
      name: 'adminModeEnabled',
      desc: '',
      args: [],
    );
  }

  /// `Continuar como convidado`
  String get continueAsGuest {
    return Intl.message(
      'Continuar como convidado',
      name: 'continueAsGuest',
      desc: '',
      args: [],
    );
  }

  /// `Fechar sessão`
  String get logout {
    return Intl.message(
      'Fechar sessão',
      name: 'logout',
      desc: '',
      args: [],
    );
  }

  /// `Idioma`
  String get language {
    return Intl.message(
      'Idioma',
      name: 'language',
      desc: '',
      args: [],
    );
  }

  /// `Categoria`
  String get category {
    return Intl.message(
      'Categoria',
      name: 'category',
      desc: '',
      args: [],
    );
  }

  /// `mãos`
  String get hands {
    return Intl.message(
      'mãos',
      name: 'hands',
      desc: '',
      args: [],
    );
  }

  /// `pés`
  String get feet {
    return Intl.message(
      'pés',
      name: 'feet',
      desc: '',
      args: [],
    );
  }

  /// `serviços`
  String get services {
    return Intl.message(
      'serviços',
      name: 'services',
      desc: '',
      args: [],
    );
  }

  /// `Não foi possível abrir {url}`
  String openUrlError(String url) {
    return Intl.message(
      'Não foi possível abrir $url',
      name: 'openUrlError',
      desc: 'Erro genérico ao abrir um URL',
      args: [url],
    );
  }

  /// `Nenhum serviço encontrado`
  String get noServicesFound {
    return Intl.message(
      'Nenhum serviço encontrado',
      name: 'noServicesFound',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum especialista encontrado`
  String get noSpecialistsFound {
    return Intl.message(
      'Nenhum especialista encontrado',
      name: 'noSpecialistsFound',
      desc: '',
      args: [],
    );
  }

  /// `Sessão iniciada com Google`
  String get googleLoginSuccess {
    return Intl.message(
      'Sessão iniciada com Google',
      name: 'googleLoginSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Convidado`
  String get guest {
    return Intl.message(
      'Convidado',
      name: 'guest',
      desc: '',
      args: [],
    );
  }

  // skipped getter for the '_all_services/workers/worker_detail_screenns' key

  /// `Info`
  String get tabInfo {
    return Intl.message(
      'Info',
      name: 'tabInfo',
      desc: '',
      args: [],
    );
  }

  /// `Portfolio`
  String get tabPortfolio {
    return Intl.message(
      'Portfolio',
      name: 'tabPortfolio',
      desc: '',
      args: [],
    );
  }

  /// `Sobre mim`
  String get aboutMe {
    return Intl.message(
      'Sobre mim',
      name: 'aboutMe',
      desc: '',
      args: [],
    );
  }

  /// `Trabalhador não encontrado`
  String get workerNotFound {
    return Intl.message(
      'Trabalhador não encontrado',
      name: 'workerNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Ainda não há fotos`
  String get noPhotos {
    return Intl.message(
      'Ainda não há fotos',
      name: 'noPhotos',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum serviço atribuído`
  String get noServicesAssigned {
    return Intl.message(
      'Nenhum serviço atribuído',
      name: 'noServicesAssigned',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao carregar especialistas`
  String get errorLoadingSpecialists {
    return Intl.message(
      'Erro ao carregar especialistas',
      name: 'errorLoadingSpecialists',
      desc: '',
      args: [],
    );
  }

  /// `Erro ao carregar serviços`
  String get errorLoadingServices {
    return Intl.message(
      'Erro ao carregar serviços',
      name: 'errorLoadingServices',
      desc: '',
      args: [],
    );
  }

  /// `Preço sob consulta`
  String get priceOnRequest {
    return Intl.message(
      'Preço sob consulta',
      name: 'priceOnRequest',
      desc: '',
      args: [],
    );
  }

  /// `Ver perfil e catálogo`
  String get viewProfileAndCatalog {
    return Intl.message(
      'Ver perfil e catálogo',
      name: 'viewProfileAndCatalog',
      desc: '',
      args: [],
    );
  }

  /// `Texts used in create/edit appointment dialogs`
  String get _booking_admin_dialogs {
    return Intl.message(
      'Texts used in create/edit appointment dialogs',
      name: '_booking_admin_dialogs',
      desc: '',
      args: [],
    );
  }

  /// `Criar marcação`
  String get createAppointmentTitle {
    return Intl.message(
      'Criar marcação',
      name: 'createAppointmentTitle',
      desc: '',
      args: [],
    );
  }

  /// `Editar marcação`
  String get editAppointmentTitle {
    return Intl.message(
      'Editar marcação',
      name: 'editAppointmentTitle',
      desc: '',
      args: [],
    );
  }

  /// `Existente`
  String get modeExisting {
    return Intl.message(
      'Existente',
      name: 'modeExisting',
      desc: '',
      args: [],
    );
  }

  /// `Novo`
  String get modeNew {
    return Intl.message(
      'Novo',
      name: 'modeNew',
      desc: '',
      args: [],
    );
  }

  /// `Pesquisar (nome / telefone / instagram)`
  String get searchClientLabel {
    return Intl.message(
      'Pesquisar (nome / telefone / instagram)',
      name: 'searchClientLabel',
      desc: '',
      args: [],
    );
  }

  /// `Sem resultados`
  String get noMatches {
    return Intl.message(
      'Sem resultados',
      name: 'noMatches',
      desc: '',
      args: [],
    );
  }

  /// `Nome`
  String get firstNameLabel {
    return Intl.message(
      'Nome',
      name: 'firstNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Apelido`
  String get lastNameLabel {
    return Intl.message(
      'Apelido',
      name: 'lastNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `País`
  String get countryLabel {
    return Intl.message(
      'País',
      name: 'countryLabel',
      desc: '',
      args: [],
    );
  }

  /// `Telefone`
  String get phoneLabel {
    return Intl.message(
      'Telefone',
      name: 'phoneLabel',
      desc: '',
      args: [],
    );
  }

  /// `Instagram (opcional)`
  String get instagramOptionalLabel {
    return Intl.message(
      'Instagram (opcional)',
      name: 'instagramOptionalLabel',
      desc: '',
      args: [],
    );
  }

  /// `O nome é obrigatório`
  String get firstNameRequired {
    return Intl.message(
      'O nome é obrigatório',
      name: 'firstNameRequired',
      desc: '',
      args: [],
    );
  }

  /// `O apelido é obrigatório`
  String get lastNameRequired {
    return Intl.message(
      'O apelido é obrigatório',
      name: 'lastNameRequired',
      desc: '',
      args: [],
    );
  }

  /// `Procedimento`
  String get procedureLabel {
    return Intl.message(
      'Procedimento',
      name: 'procedureLabel',
      desc: '',
      args: [],
    );
  }

  /// `O procedimento é obrigatório`
  String get procedureRequired {
    return Intl.message(
      'O procedimento é obrigatório',
      name: 'procedureRequired',
      desc: '',
      args: [],
    );
  }

  /// `Tipo`
  String get typeLabel {
    return Intl.message(
      'Tipo',
      name: 'typeLabel',
      desc: '',
      args: [],
    );
  }

  /// `O tipo é obrigatório`
  String get typeRequired {
    return Intl.message(
      'O tipo é obrigatório',
      name: 'typeRequired',
      desc: '',
      args: [],
    );
  }

  /// `Mais comum`
  String get mostCommonBadge {
    return Intl.message(
      'Mais comum',
      name: 'mostCommonBadge',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar hora`
  String get selectTimePlaceholder {
    return Intl.message(
      'Selecionar hora',
      name: 'selectTimePlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `A hora é obrigatória`
  String get timeRequired {
    return Intl.message(
      'A hora é obrigatória',
      name: 'timeRequired',
      desc: '',
      args: [],
    );
  }

  /// `Preço: €{value}`
  String priceLabel(String value) {
    return Intl.message(
      'Preço: €$value',
      name: 'priceLabel',
      desc: '',
      args: [value],
    );
  }

  /// `Tempo: {minutes}m`
  String timeMinutesLabel(int minutes) {
    return Intl.message(
      'Tempo: ${minutes}m',
      name: 'timeMinutesLabel',
      desc: '',
      args: [minutes],
    );
  }

  /// `Tempo: —`
  String get timeMinutesEmpty {
    return Intl.message(
      'Tempo: —',
      name: 'timeMinutesEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Selecione um cliente existente`
  String get selectExistingClient {
    return Intl.message(
      'Selecione um cliente existente',
      name: 'selectExistingClient',
      desc: '',
      args: [],
    );
  }

  /// `É necessário telefone ou Instagram`
  String get phoneOrInstagramRequired {
    return Intl.message(
      'É necessário telefone ou Instagram',
      name: 'phoneOrInstagramRequired',
      desc: '',
      args: [],
    );
  }

  /// `Marcação criada`
  String get appointmentCreated {
    return Intl.message(
      'Marcação criada',
      name: 'appointmentCreated',
      desc: '',
      args: [],
    );
  }

  /// `Marcação atualizada`
  String get appointmentUpdated {
    return Intl.message(
      'Marcação atualizada',
      name: 'appointmentUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Marcação eliminada`
  String get appointmentDeleted {
    return Intl.message(
      'Marcação eliminada',
      name: 'appointmentDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Eliminar marcação?`
  String get deleteAppointmentTitle {
    return Intl.message(
      'Eliminar marcação?',
      name: 'deleteAppointmentTitle',
      desc: '',
      args: [],
    );
  }

  /// `Esta ação não pode ser desfeita.`
  String get deleteAppointmentBody {
    return Intl.message(
      'Esta ação não pode ser desfeita.',
      name: 'deleteAppointmentBody',
      desc: '',
      args: [],
    );
  }

  /// `Eliminar`
  String get delete {
    return Intl.message(
      'Eliminar',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Não`
  String get no {
    return Intl.message(
      'Não',
      name: 'no',
      desc: '',
      args: [],
    );
  }

  /// `Guardar`
  String get save {
    return Intl.message(
      'Guardar',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Criar`
  String get create {
    return Intl.message(
      'Criar',
      name: 'create',
      desc: '',
      args: [],
    );
  }

  /// `Erro: {value}`
  String errorWithValue(String value) {
    return Intl.message(
      'Erro: $value',
      name: 'errorWithValue',
      desc: '',
      args: [value],
    );
  }

  /// `Cliente`
  String get clientFallback {
    return Intl.message(
      'Cliente',
      name: 'clientFallback',
      desc: '',
      args: [],
    );
  }

  /// `Serviço`
  String get serviceFallback {
    return Intl.message(
      'Serviço',
      name: 'serviceFallback',
      desc: '',
      args: [],
    );
  }

  /// `Common app strings`
  String get _app_common {
    return Intl.message(
      'Common app strings',
      name: '_app_common',
      desc: '',
      args: [],
    );
  }

  /// `Salão de Manicure`
  String get appTitle {
    return Intl.message(
      'Salão de Manicure',
      name: 'appTitle',
      desc: '',
      args: [],
    );
  }

  /// `Agenda`
  String get schedule {
    return Intl.message(
      'Agenda',
      name: 'schedule',
      desc: '',
      args: [],
    );
  }

  /// `Preço: {price}`
  String price(Object price) {
    return Intl.message(
      'Preço: $price',
      name: 'price',
      desc: '',
      args: [price],
    );
  }

  /// `{count, plural, =0{Sem agendamentos} =1{1 agendamento} other{{count} agendamentos}}`
  String appointmentsCount(num count) {
    return Intl.plural(
      count,
      zero: 'Sem agendamentos',
      one: '1 agendamento',
      other: '$count agendamentos',
      name: 'appointmentsCount',
      desc: '',
      args: [count],
    );
  }

  /// `Confirmar agendamento`
  String get confirmBooking {
    return Intl.message(
      'Confirmar agendamento',
      name: 'confirmBooking',
      desc: '',
      args: [],
    );
  }

  /// `Cancelar`
  String get cancel {
    return Intl.message(
      'Cancelar',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Seu agendamento foi confirmado!`
  String get successBooking {
    return Intl.message(
      'Seu agendamento foi confirmado!',
      name: 'successBooking',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Procedimento`
  String get selectProcedurePlaceholder {
    return Intl.message(
      'Selecionar Procedimento',
      name: 'selectProcedurePlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Por favor selecione um procedimento`
  String get selectProcedureHelper {
    return Intl.message(
      'Por favor selecione um procedimento',
      name: 'selectProcedureHelper',
      desc: '',
      args: [],
    );
  }

  /// `Selecione um procedimento`
  String get pickProcedureTitle {
    return Intl.message(
      'Selecione um procedimento',
      name: 'pickProcedureTitle',
      desc: '',
      args: [],
    );
  }

  /// `Selecionar Tipo`
  String get selectTypePlaceholder {
    return Intl.message(
      'Selecionar Tipo',
      name: 'selectTypePlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Selecione um tipo`
  String get pickTypeTitle {
    return Intl.message(
      'Selecione um tipo',
      name: 'pickTypeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Ver perfil`
  String get tapToViewProfile {
    return Intl.message(
      'Ver perfil',
      name: 'tapToViewProfile',
      desc: '',
      args: [],
    );
  }

  /// `Próximas marcações`
  String get upcomingAppointments {
    return Intl.message(
      'Próximas marcações',
      name: 'upcomingAppointments',
      desc: '',
      args: [],
    );
  }

  /// `Sem próximas marcações`
  String get noUpcomingAppointments {
    return Intl.message(
      'Sem próximas marcações',
      name: 'noUpcomingAppointments',
      desc: '',
      args: [],
    );
  }

  /// `Sem marcações passadas`
  String get noPastAppointments {
    return Intl.message(
      'Sem marcações passadas',
      name: 'noPastAppointments',
      desc: '',
      args: [],
    );
  }

  /// `Pedidos de marcação ativos`
  String get activeBookingRequests {
    return Intl.message(
      'Pedidos de marcação ativos',
      name: 'activeBookingRequests',
      desc: '',
      args: [],
    );
  }

  /// `Nova marcação`
  String get newAppointment {
    return Intl.message(
      'Nova marcação',
      name: 'newAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Novo pedido de marcação`
  String get newBookingRequest {
    return Intl.message(
      'Novo pedido de marcação',
      name: 'newBookingRequest',
      desc: '',
      args: [],
    );
  }

  /// `Editar cliente`
  String get editClient {
    return Intl.message(
      'Editar cliente',
      name: 'editClient',
      desc: '',
      args: [],
    );
  }

  /// `Editar pedido`
  String get editRequest {
    return Intl.message(
      'Editar pedido',
      name: 'editRequest',
      desc: '',
      args: [],
    );
  }

  /// `Guardar cliente`
  String get saveClient {
    return Intl.message(
      'Guardar cliente',
      name: 'saveClient',
      desc: '',
      args: [],
    );
  }

  /// `Pedido atualizado`
  String get requestUpdated {
    return Intl.message(
      'Pedido atualizado',
      name: 'requestUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Clientes perdidos`
  String get lostClients {
    return Intl.message(
      'Clientes perdidos',
      name: 'lostClients',
      desc: '',
      args: [],
    );
  }

  /// `Clientes sem visita recente`
  String get clientsNoVisitRecently {
    return Intl.message(
      'Clientes sem visita recente',
      name: 'clientsNoVisitRecently',
      desc: '',
      args: [],
    );
  }

  /// `Em risco (30–45d)`
  String get atRiskClients {
    return Intl.message(
      'Em risco (30–45d)',
      name: 'atRiskClients',
      desc: '',
      args: [],
    );
  }

  /// `Perdidos (45d+)`
  String get lostClientsTab {
    return Intl.message(
      'Perdidos (45d+)',
      name: 'lostClientsTab',
      desc: '',
      args: [],
    );
  }

  /// `Sem clientes em risco agora`
  String get noAtRiskClients {
    return Intl.message(
      'Sem clientes em risco agora',
      name: 'noAtRiskClients',
      desc: '',
      args: [],
    );
  }

  /// `Sem clientes perdidos agora`
  String get noLostClients {
    return Intl.message(
      'Sem clientes perdidos agora',
      name: 'noLostClients',
      desc: '',
      args: [],
    );
  }

  /// `Eliminar cliente?`
  String get deleteClientTitle {
    return Intl.message(
      'Eliminar cliente?',
      name: 'deleteClientTitle',
      desc: '',
      args: [],
    );
  }

  /// `Eliminar pedido?`
  String get deleteRequestTitle {
    return Intl.message(
      'Eliminar pedido?',
      name: 'deleteRequestTitle',
      desc: '',
      args: [],
    );
  }

  /// `Pedido de marcação`
  String get bookingRequest {
    return Intl.message(
      'Pedido de marcação',
      name: 'bookingRequest',
      desc: '',
      args: [],
    );
  }

  /// `À procura de marcação`
  String get lookingForAppointment {
    return Intl.message(
      'À procura de marcação',
      name: 'lookingForAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Sem procura activa`
  String get notLooking {
    return Intl.message(
      'Sem procura activa',
      name: 'notLooking',
      desc: '',
      args: [],
    );
  }

  /// `Início Admin`
  String get adminHome {
    return Intl.message(
      'Início Admin',
      name: 'adminHome',
      desc: '',
      args: [],
    );
  }

  /// `Clientes à procura de marcação`
  String get subtitleLooking {
    return Intl.message(
      'Clientes à procura de marcação',
      name: 'subtitleLooking',
      desc: '',
      args: [],
    );
  }

  /// `Mais cancelamentos (depois mais assistidos)`
  String get subtitleCancelled {
    return Intl.message(
      'Mais cancelamentos (depois mais assistidos)',
      name: 'subtitleCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Mais faltas (depois mais assistidos)`
  String get subtitleNoShow {
    return Intl.message(
      'Mais faltas (depois mais assistidos)',
      name: 'subtitleNoShow',
      desc: '',
      args: [],
    );
  }

  /// `À procura`
  String get modeLooking {
    return Intl.message(
      'À procura',
      name: 'modeLooking',
      desc: '',
      args: [],
    );
  }

  /// `Cancelados`
  String get modeCancelled {
    return Intl.message(
      'Cancelados',
      name: 'modeCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Faltou`
  String get modeNoShow {
    return Intl.message(
      'Faltou',
      name: 'modeNoShow',
      desc: '',
      args: [],
    );
  }

  /// `Clientes perdidos  (30d+ / 45d+)`
  String get lostClientsButton {
    return Intl.message(
      'Clientes perdidos  (30d+ / 45d+)',
      name: 'lostClientsButton',
      desc: '',
      args: [],
    );
  }

  /// `Resultados`
  String get results {
    return Intl.message(
      'Resultados',
      name: 'results',
      desc: '',
      args: [],
    );
  }

  /// `Sem pedidos de marcação ativos agora.`
  String get noActiveBookingRequests {
    return Intl.message(
      'Sem pedidos de marcação ativos agora.',
      name: 'noActiveBookingRequests',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum cliente corresponde ao filtro.`
  String get noClientsMatchFilter {
    return Intl.message(
      'Nenhum cliente corresponde ao filtro.',
      name: 'noClientsMatchFilter',
      desc: '',
      args: [],
    );
  }

  /// `Compareceu`
  String get attended {
    return Intl.message(
      'Compareceu',
      name: 'attended',
      desc: '',
      args: [],
    );
  }

  /// `Última visita`
  String get lastVisit {
    return Intl.message(
      'Última visita',
      name: 'lastVisit',
      desc: '',
      args: [],
    );
  }

  /// `Criar cliente`
  String get createClient {
    return Intl.message(
      'Criar cliente',
      name: 'createClient',
      desc: '',
      args: [],
    );
  }

  /// `Cliente criado`
  String get clientCreated {
    return Intl.message(
      'Cliente criado',
      name: 'clientCreated',
      desc: '',
      args: [],
    );
  }

  /// `Telefone ou Instagram é obrigatório`
  String get phoneOrInstagramRequiredMsg {
    return Intl.message(
      'Telefone ou Instagram é obrigatório',
      name: 'phoneOrInstagramRequiredMsg',
      desc: '',
      args: [],
    );
  }

  /// `Obrigatório`
  String get required {
    return Intl.message(
      'Obrigatório',
      name: 'required',
      desc: '',
      args: [],
    );
  }

  /// `Código do país`
  String get countryCode {
    return Intl.message(
      'Código do país',
      name: 'countryCode',
      desc: '',
      args: [],
    );
  }

  /// `Pesquisar`
  String get searchHint {
    return Intl.message(
      'Pesquisar',
      name: 'searchHint',
      desc: '',
      args: [],
    );
  }

  /// `Seg`
  String get weekdayMon {
    return Intl.message(
      'Seg',
      name: 'weekdayMon',
      desc: '',
      args: [],
    );
  }

  /// `Ter`
  String get weekdayTue {
    return Intl.message(
      'Ter',
      name: 'weekdayTue',
      desc: '',
      args: [],
    );
  }

  /// `Qua`
  String get weekdayWed {
    return Intl.message(
      'Qua',
      name: 'weekdayWed',
      desc: '',
      args: [],
    );
  }

  /// `Qui`
  String get weekdayThu {
    return Intl.message(
      'Qui',
      name: 'weekdayThu',
      desc: '',
      args: [],
    );
  }

  /// `Sex`
  String get weekdayFri {
    return Intl.message(
      'Sex',
      name: 'weekdayFri',
      desc: '',
      args: [],
    );
  }

  /// `Sáb`
  String get weekdaySat {
    return Intl.message(
      'Sáb',
      name: 'weekdaySat',
      desc: '',
      args: [],
    );
  }

  /// `Dom`
  String get weekdaySun {
    return Intl.message(
      'Dom',
      name: 'weekdaySun',
      desc: '',
      args: [],
    );
  }

  /// `Cliente atualizado`
  String get clientUpdated {
    return Intl.message(
      'Cliente atualizado',
      name: 'clientUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Cliente eliminado`
  String get clientDeleted {
    return Intl.message(
      'Cliente eliminado',
      name: 'clientDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Isto irá eliminar o cliente. Continuar?`
  String get deleteClientConfirm {
    return Intl.message(
      'Isto irá eliminar o cliente. Continuar?',
      name: 'deleteClientConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Pedido de marcação criado`
  String get bookingRequestCreated {
    return Intl.message(
      'Pedido de marcação criado',
      name: 'bookingRequestCreated',
      desc: '',
      args: [],
    );
  }

  /// `Desativar pedidos de marcação?`
  String get disableBookingRequests {
    return Intl.message(
      'Desativar pedidos de marcação?',
      name: 'disableBookingRequests',
      desc: '',
      args: [],
    );
  }

  /// `Desativar 'À procura de marcação'. Continuar?`
  String get disableBookingConfirmNone {
    return Intl.message(
      'Desativar \'À procura de marcação\'. Continuar?',
      name: 'disableBookingConfirmNone',
      desc: '',
      args: [],
    );
  }

  /// `Eliminar todos os {count} pedidos ativos e desativar?`
  String disableBookingConfirmMany(int count) {
    return Intl.message(
      'Eliminar todos os $count pedidos ativos e desativar?',
      name: 'disableBookingConfirmMany',
      desc: '',
      args: [count],
    );
  }

  /// `Selecione primeiro um procedimento`
  String get selectProcedureFirst {
    return Intl.message(
      'Selecione primeiro um procedimento',
      name: 'selectProcedureFirst',
      desc: '',
      args: [],
    );
  }

  /// `Instagram`
  String get instagram {
    return Intl.message(
      'Instagram',
      name: 'instagram',
      desc: '',
      args: [],
    );
  }

  /// `Próximas`
  String get upcoming {
    return Intl.message(
      'Próximas',
      name: 'upcoming',
      desc: '',
      args: [],
    );
  }

  /// `Passadas`
  String get past {
    return Intl.message(
      'Passadas',
      name: 'past',
      desc: '',
      args: [],
    );
  }

  /// `Confirmar`
  String get confirm {
    return Intl.message(
      'Confirmar',
      name: 'confirm',
      desc: '',
      args: [],
    );
  }

  /// `Eliminar cliente`
  String get deleteClient {
    return Intl.message(
      'Eliminar cliente',
      name: 'deleteClient',
      desc: '',
      args: [],
    );
  }

  /// `Eliminar pedido`
  String get deleteRequest {
    return Intl.message(
      'Eliminar pedido',
      name: 'deleteRequest',
      desc: '',
      args: [],
    );
  }

  /// `O intervalo deve ter pelo menos {dur} min`
  String rangeMustBeAtLeast(int dur) {
    return Intl.message(
      'O intervalo deve ter pelo menos $dur min',
      name: 'rangeMustBeAtLeast',
      desc: '',
      args: [dur],
    );
  }

  /// `Agenda Admin`
  String get adminSchedule {
    return Intl.message(
      'Agenda Admin',
      name: 'adminSchedule',
      desc: '',
      args: [],
    );
  }

  /// `Marcações`
  String get appointments {
    return Intl.message(
      'Marcações',
      name: 'appointments',
      desc: '',
      args: [],
    );
  }

  /// `Sem marcações para este dia`
  String get noAppointmentsForDay {
    return Intl.message(
      'Sem marcações para este dia',
      name: 'noAppointmentsForDay',
      desc: '',
      args: [],
    );
  }

  /// `Confirmação pendente`
  String get pendingConfirmation {
    return Intl.message(
      'Confirmação pendente',
      name: 'pendingConfirmation',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar`
  String get add {
    return Intl.message(
      'Adicionar',
      name: 'add',
      desc: '',
      args: [],
    );
  }

  /// `Os serviços ainda estão a carregar...`
  String get servicesStillLoading {
    return Intl.message(
      'Os serviços ainda estão a carregar...',
      name: 'servicesStillLoading',
      desc: '',
      args: [],
    );
  }

  /// `Bloquear este horário`
  String get blockThisTime {
    return Intl.message(
      'Bloquear este horário',
      name: 'blockThisTime',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar novo bloqueio`
  String get addNewBlock {
    return Intl.message(
      'Adicionar novo bloqueio',
      name: 'addNewBlock',
      desc: '',
      args: [],
    );
  }

  /// `Bloqueios existentes`
  String get existingBlocks {
    return Intl.message(
      'Bloqueios existentes',
      name: 'existingBlocks',
      desc: '',
      args: [],
    );
  }

  /// `Remover bloqueio?`
  String get removeBlock {
    return Intl.message(
      'Remover bloqueio?',
      name: 'removeBlock',
      desc: '',
      args: [],
    );
  }

  /// `Remover`
  String get remove {
    return Intl.message(
      'Remover',
      name: 'remove',
      desc: '',
      args: [],
    );
  }

  /// `De`
  String get from {
    return Intl.message(
      'De',
      name: 'from',
      desc: '',
      args: [],
    );
  }

  /// `Nenhum`
  String get none {
    return Intl.message(
      'Nenhum',
      name: 'none',
      desc: '',
      args: [],
    );
  }

  /// `O fim deve ser depois do início`
  String get endMustBeAfterStart {
    return Intl.message(
      'O fim deve ser depois do início',
      name: 'endMustBeAfterStart',
      desc: '',
      args: [],
    );
  }

  /// `Motivo (opcional)`
  String get reasonOptional {
    return Intl.message(
      'Motivo (opcional)',
      name: 'reasonOptional',
      desc: '',
      args: [],
    );
  }

  /// `Bloquear horário – {date}`
  String blockTimeDateLabel(String date) {
    return Intl.message(
      'Bloquear horário – $date',
      name: 'blockTimeDateLabel',
      desc: '',
      args: [date],
    );
  }

  /// `Qualquer`
  String get any {
    return Intl.message(
      'Qualquer',
      name: 'any',
      desc: '',
      args: [],
    );
  }

  /// `Qualquer hora`
  String get anyTime {
    return Intl.message(
      'Qualquer hora',
      name: 'anyTime',
      desc: '',
      args: [],
    );
  }

  /// `Cliente cancelou a marcação`
  String get clientCancelledAppointment {
    return Intl.message(
      'Cliente cancelou a marcação',
      name: 'clientCancelledAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Cliente não compareceu`
  String get clientDidNotAttend {
    return Intl.message(
      'Cliente não compareceu',
      name: 'clientDidNotAttend',
      desc: '',
      args: [],
    );
  }

  /// `Faltou`
  String get noShow {
    return Intl.message(
      'Faltou',
      name: 'noShow',
      desc: '',
      args: [],
    );
  }

  /// `Erro meu`
  String get myError {
    return Intl.message(
      'Erro meu',
      name: 'myError',
      desc: '',
      args: [],
    );
  }

  /// `Remover marcação`
  String get removeAppointment {
    return Intl.message(
      'Remover marcação',
      name: 'removeAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Remover permanentemente (reserva errada)`
  String get removePermanently {
    return Intl.message(
      'Remover permanentemente (reserva errada)',
      name: 'removePermanently',
      desc: '',
      args: [],
    );
  }

  /// `Eliminado permanentemente`
  String get deletedPermanently {
    return Intl.message(
      'Eliminado permanentemente',
      name: 'deletedPermanently',
      desc: '',
      args: [],
    );
  }

  /// `Marcado como marcação confirmada.`
  String get markedAsConfirmed {
    return Intl.message(
      'Marcado como marcação confirmada.',
      name: 'markedAsConfirmed',
      desc: '',
      args: [],
    );
  }

  /// `Marcado como reserva: confirmação pendente.`
  String get markedAsReservation {
    return Intl.message(
      'Marcado como reserva: confirmação pendente.',
      name: 'markedAsReservation',
      desc: '',
      args: [],
    );
  }

  /// `Marcado como faltou`
  String get markedAsNoShow {
    return Intl.message(
      'Marcado como faltou',
      name: 'markedAsNoShow',
      desc: '',
      args: [],
    );
  }

  /// `Eliminar pedido(s) de marcação?`
  String get deleteBookingRequests {
    return Intl.message(
      'Eliminar pedido(s) de marcação?',
      name: 'deleteBookingRequests',
      desc: '',
      args: [],
    );
  }

  /// `Manter`
  String get keep {
    return Intl.message(
      'Manter',
      name: 'keep',
      desc: '',
      args: [],
    );
  }

  /// `Pedido`
  String get request {
    return Intl.message(
      'Pedido',
      name: 'request',
      desc: '',
      args: [],
    );
  }

  /// `Nome duplicado`
  String get duplicateName {
    return Intl.message(
      'Nome duplicado',
      name: 'duplicateName',
      desc: '',
      args: [],
    );
  }

  /// `Preço final inválido`
  String get invalidFinalPrice {
    return Intl.message(
      'Preço final inválido',
      name: 'invalidFinalPrice',
      desc: '',
      args: [],
    );
  }

  /// `Preço final (opcional)`
  String get finalPriceOptional {
    return Intl.message(
      'Preço final (opcional)',
      name: 'finalPriceOptional',
      desc: '',
      args: [],
    );
  }

  /// `A verificar…`
  String get checking {
    return Intl.message(
      'A verificar…',
      name: 'checking',
      desc: '',
      args: [],
    );
  }

  /// `Sem disponibilidade`
  String get noAvailability {
    return Intl.message(
      'Sem disponibilidade',
      name: 'noAvailability',
      desc: '',
      args: [],
    );
  }

  /// `Isto irá eliminar este pedido de marcação.`
  String get deleteRequestConfirm {
    return Intl.message(
      'Isto irá eliminar este pedido de marcação.',
      name: 'deleteRequestConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Trabalhadora`
  String get worker {
    return Intl.message(
      'Trabalhadora',
      name: 'worker',
      desc: '',
      args: [],
    );
  }

  /// `Criar pedido`
  String get createRequest {
    return Intl.message(
      'Criar pedido',
      name: 'createRequest',
      desc: '',
      args: [],
    );
  }

  /// `Adicionar dia`
  String get addDay {
    return Intl.message(
      'Adicionar dia',
      name: 'addDay',
      desc: '',
      args: [],
    );
  }

  /// `Dias`
  String get days {
    return Intl.message(
      'Dias',
      name: 'days',
      desc: '',
      args: [],
    );
  }

  /// `Intervalos`
  String get ranges {
    return Intl.message(
      'Intervalos',
      name: 'ranges',
      desc: '',
      args: [],
    );
  }

  /// `+ Adicionar intervalo`
  String get addRange {
    return Intl.message(
      '+ Adicionar intervalo',
      name: 'addRange',
      desc: '',
      args: [],
    );
  }

  /// `Escolher dia preferido`
  String get pickPreferredDay {
    return Intl.message(
      'Escolher dia preferido',
      name: 'pickPreferredDay',
      desc: '',
      args: [],
    );
  }

  /// `Escolher hora de início`
  String get pickStartTime {
    return Intl.message(
      'Escolher hora de início',
      name: 'pickStartTime',
      desc: '',
      args: [],
    );
  }

  /// `Escolher hora de fim`
  String get pickEndTime {
    return Intl.message(
      'Escolher hora de fim',
      name: 'pickEndTime',
      desc: '',
      args: [],
    );
  }

  /// `Dica: adicione um ou mais dias e, opcionalmente, intervalos de tempo.`
  String get tipAddDays {
    return Intl.message(
      'Dica: adicione um ou mais dias e, opcionalmente, intervalos de tempo.',
      name: 'tipAddDays',
      desc: '',
      args: [],
    );
  }

  /// `Dia`
  String get viewDay {
    return Intl.message(
      'Dia',
      name: 'viewDay',
      desc: '',
      args: [],
    );
  }

  /// `Semana`
  String get viewWeek {
    return Intl.message(
      'Semana',
      name: 'viewWeek',
      desc: '',
      args: [],
    );
  }

  /// `Todos`
  String get all {
    return Intl.message(
      'Todos',
      name: 'all',
      desc: '',
      args: [],
    );
  }

  /// `Notificações`
  String get notifications {
    return Intl.message(
      'Notificações',
      name: 'notifications',
      desc: '',
      args: [],
    );
  }

  /// `Sem notificações.`
  String get noNotifications {
    return Intl.message(
      'Sem notificações.',
      name: 'noNotifications',
      desc: '',
      args: [],
    );
  }

  /// `Toque para abrir o cliente`
  String get tapToOpenClient {
    return Intl.message(
      'Toque para abrir o cliente',
      name: 'tapToOpenClient',
      desc: '',
      args: [],
    );
  }

  /// `Dispensar`
  String get dismiss {
    return Intl.message(
      'Dispensar',
      name: 'dismiss',
      desc: '',
      args: [],
    );
  }

  /// `Fechar`
  String get close {
    return Intl.message(
      'Fechar',
      name: 'close',
      desc: '',
      args: [],
    );
  }

  /// `PENDENTE`
  String get pendingConfirmationLabel {
    return Intl.message(
      'PENDENTE',
      name: 'pendingConfirmationLabel',
      desc: '',
      args: [],
    );
  }

  /// `O cliente ainda precisa de confirmar este horário.`
  String get pendingConfirmationMsg {
    return Intl.message(
      'O cliente ainda precisa de confirmar este horário.',
      name: 'pendingConfirmationMsg',
      desc: '',
      args: [],
    );
  }

  /// `Horário confirmado.`
  String get timeIsConfirmed {
    return Intl.message(
      'Horário confirmado.',
      name: 'timeIsConfirmed',
      desc: '',
      args: [],
    );
  }

  /// `Reserva (confirmação pendente)`
  String get reservationPending {
    return Intl.message(
      'Reserva (confirmação pendente)',
      name: 'reservationPending',
      desc: '',
      args: [],
    );
  }

  /// `À procura`
  String get seeking {
    return Intl.message(
      'À procura',
      name: 'seeking',
      desc: '',
      args: [],
    );
  }

  /// `Pesquisar...`
  String get searchEllipsis {
    return Intl.message(
      'Pesquisar...',
      name: 'searchEllipsis',
      desc: '',
      args: [],
    );
  }

  /// `Funções`
  String get roles {
    return Intl.message(
      'Funções',
      name: 'roles',
      desc: '',
      args: [],
    );
  }

  /// `Sem funções atribuídas`
  String get noRolesAssigned {
    return Intl.message(
      'Sem funções atribuídas',
      name: 'noRolesAssigned',
      desc: '',
      args: [],
    );
  }

  /// `Admin`
  String get adminRole {
    return Intl.message(
      'Admin',
      name: 'adminRole',
      desc: '',
      args: [],
    );
  }

  /// `Admin + Trabalhadora`
  String get adminWorkerRole {
    return Intl.message(
      'Admin + Trabalhadora',
      name: 'adminWorkerRole',
      desc: '',
      args: [],
    );
  }

  /// `Utilizador`
  String get userRole {
    return Intl.message(
      'Utilizador',
      name: 'userRole',
      desc: '',
      args: [],
    );
  }

  /// `Trabalhadora`
  String get workerRole {
    return Intl.message(
      'Trabalhadora',
      name: 'workerRole',
      desc: '',
      args: [],
    );
  }

  /// `ID da Trabalhadora`
  String get workerId {
    return Intl.message(
      'ID da Trabalhadora',
      name: 'workerId',
      desc: '',
      args: [],
    );
  }

  /// `Acesso`
  String get access {
    return Intl.message(
      'Acesso',
      name: 'access',
      desc: '',
      args: [],
    );
  }

  /// `Sem acesso`
  String get noAccess {
    return Intl.message(
      'Sem acesso',
      name: 'noAccess',
      desc: '',
      args: [],
    );
  }

  /// `Inicie sessão para gerir as suas marcações`
  String get signInToManage {
    return Intl.message(
      'Inicie sessão para gerir as suas marcações',
      name: 'signInToManage',
      desc: '',
      args: [],
    );
  }

  /// `Marcado como cancelado`
  String get markedAsCancelled {
    return Intl.message(
      'Marcado como cancelado',
      name: 'markedAsCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Agendado`
  String get statusScheduled {
    return Intl.message(
      'Agendado',
      name: 'statusScheduled',
      desc: '',
      args: [],
    );
  }

  /// `Concluído`
  String get statusDone {
    return Intl.message(
      'Concluído',
      name: 'statusDone',
      desc: '',
      args: [],
    );
  }

  /// `Compareceu`
  String get statusAttended {
    return Intl.message(
      'Compareceu',
      name: 'statusAttended',
      desc: '',
      args: [],
    );
  }

  /// `Cancelado`
  String get statusCancelled {
    return Intl.message(
      'Cancelado',
      name: 'statusCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Faltou`
  String get statusNoShow {
    return Intl.message(
      'Faltou',
      name: 'statusNoShow',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'es', countryCode: 'ES'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
