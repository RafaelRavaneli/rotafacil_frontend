class ProfessionalDocument {
  const ProfessionalDocument({
    required this.id,
    required this.userId,
    required this.userType,
    required this.documentType,
    required this.fileName,
    required this.contentType,
    required this.size,
    required this.status,
    required this.reviewNote,
    required this.createdAt,
    this.userName = '',
    this.userEmail = '',
    this.cadasturNumber = '',
    this.cadasturValidUntil = '',
  });

  final String id;
  final String userId;
  final String userType;
  final String documentType;
  final String fileName;
  final String contentType;
  final int size;
  final String status;
  final String reviewNote;
  final DateTime? createdAt;
  final String userName;
  final String userEmail;
  final String cadasturNumber;
  final String cadasturValidUntil;

  factory ProfessionalDocument.fromJson(Map<String, dynamic> json) {
    return ProfessionalDocument(
      id: json['id']?.toString() ?? '',
      userId: json['id_usuario']?.toString() ?? '',
      userType: json['tipo_usuario']?.toString() ?? '',
      documentType: json['tipo_documento']?.toString() ?? '',
      fileName: json['nome_arquivo']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? '',
      size: int.tryParse(json['tamanho']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'pendente',
      reviewNote: json['observacao_analise']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['criado_em']?.toString() ?? ''),
      userName: json['nome_usuario']?.toString() ?? '',
      userEmail: json['email_usuario']?.toString() ?? '',
      cadasturNumber: json['cadastur_numero']?.toString() ?? '',
      cadasturValidUntil: json['cadastur_validade']?.toString() ?? '',
    );
  }
}
