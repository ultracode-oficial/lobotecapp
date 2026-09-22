class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://lobotec.ultracode.com.br/api';
  static const String platform = 'mobile';

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String mfaVerify = '/auth/mfa/verify';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyCode = '/auth/verify-code';
  static const String resetPassword = '/auth/reset-password';

  static const String profile = '/profile';
  static const String profilePhoto = '/profile/photo';

  static const String notifications = '/notifications';
  static String notificationRead(int id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  static const String clientes = '/clientes';
  static String clienteDetail(int id) => '/clientes/$id';

  static const String equipes = '/equipes';
  static String equipeDetail(int id) => '/equipes/$id';

  static const String rolesOptions = '/roles-options';
  static const String especializacoesOptions = '/especializacoes-options';
  static const String tipoServicosOptions = '/tipoServicos-options';
  static const String tipoEquipamentosOptions = '/tipoEquipamentos-options';

  // --- Rotas de Execução do Técnico (/api/executar/*) ---
  static const String executarDashboard = '/executar/dashboard';
  static const String executarServicos = '/executar/servicos';
  static String executarServicoDetail(dynamic id) => '/executar/servicos/$id';
  static String executarServicoEtapas(dynamic id) => '/executar/servicos/$id/etapas';
  static String executarServicoFinalizar(dynamic id) => '/executar/servicos/$id/finalizar';

  static const String executarAgenda = '/executar/agenda';
  static const String executarAgendaOcupacao = '/executar/agenda/ocupacao';

  static String executarEtapaDetail(dynamic etapaId) => '/executar/etapas/$etapaId';
  static String executarEtapaCheckIn(dynamic etapaId) => '/executar/etapas/$etapaId/check-in';
  static String executarEtapaAssinatura(dynamic etapaId) => '/executar/etapas/$etapaId/assinatura';
  static String executarEtapaFinalizar(dynamic etapaId) => '/executar/etapas/$etapaId/finalizar';
  static String executarEtapaEquipamentos(dynamic etapaId) => '/executar/etapas/$etapaId/equipamentos';

  static String executarEquipamentoDetail(dynamic etapaId, dynamic eqServicoId) =>
      '/executar/etapas/$etapaId/equipamentos/$eqServicoId';
  static String executarEquipamentoIniciar(dynamic etapaId, dynamic eqServicoId) =>
      '/executar/etapas/$etapaId/equipamentos/$eqServicoId/iniciar';
  static String executarEquipamentoRegistro(dynamic etapaId, dynamic eqServicoId) =>
      '/executar/etapas/$etapaId/equipamentos/$eqServicoId/registro';
  static String executarEquipamentoChecklist(dynamic etapaId, dynamic eqServicoId) =>
      '/executar/etapas/$etapaId/equipamentos/$eqServicoId/checklist';
  static String executarEquipamentoChecklistFoto(dynamic etapaId, dynamic eqServicoId) =>
      '/executar/etapas/$etapaId/equipamentos/$eqServicoId/checklist/foto';
  static String executarEquipamentoFinalizar(dynamic etapaId, dynamic eqServicoId) =>
      '/executar/etapas/$etapaId/equipamentos/$eqServicoId/finalizar';

  static String executarTarefaToggle(dynamic tarefaId) =>
      '/executar/tarefas/$tarefaId/toggle-status';
  static String executarTarefaFormulario(dynamic tarefaId) =>
      '/executar/tarefas/$tarefaId/formulario';
  static String executarFormularioAnexo(dynamic respostaId) =>
      '/executar/formulario-respostas/$respostaId/anexos';
}
