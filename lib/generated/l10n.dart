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

  /// `Reforço com Verniz de Gel`
  String get gelVarnish {
    return Intl.message(
      'Reforço com Verniz de Gel',
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

  /// `Abrir no Google Maps`
  String get openInMaps {
    return Intl.message(
      'Abrir no Google Maps',
      name: 'openInMaps',
      desc: '',
      args: [],
    );
  }

  /// `Não foi possível abrir o Google Maps`
  String get openInMapsError {
    return Intl.message(
      'Não foi possível abrir o Google Maps',
      name: 'openInMapsError',
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

  /// `Ver todo`
  String get viewAll {
    return Intl.message(
      'Ver todo',
      name: 'viewAll',
      desc: '',
      args: [],
    );
  }

  /// `Ofertas`
  String get offers {
    return Intl.message(
      'Ofertas',
      name: 'offers',
      desc: '',
      args: [],
    );
  }

  /// `site web`
  String get website {
    return Intl.message(
      'site web',
      name: 'website',
      desc: '',
      args: [],
    );
  }

  /// `Melhores Especialistas`
  String get Bspecialists {
    return Intl.message(
      'Melhores Especialistas',
      name: 'Bspecialists',
      desc: '',
      args: [],
    );
  }

  /// `Melhores Serviços`
  String get Bservices {
    return Intl.message(
      'Melhores Serviços',
      name: 'Bservices',
      desc: '',
      args: [],
    );
  }

  /// `Todos os Serviços`
  String get Aservices {
    return Intl.message(
      'Todos os Serviços',
      name: 'Aservices',
      desc: '',
      args: [],
    );
  }

  /// `Todos os Especialistas`
  String get Aspecialists {
    return Intl.message(
      'Todos os Especialistas',
      name: 'Aspecialists',
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
