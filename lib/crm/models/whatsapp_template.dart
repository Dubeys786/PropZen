class WhatsAppTemplate {
  final String id;
  final String name;
  final String templateName;
  final String language;
  final String category;
  final String content;
  final String? providerTemplateId;
  final String status;
  final String? variables;

  const WhatsAppTemplate({
    required this.id,
    required this.name,
    required this.templateName,
    this.language = 'en',
    this.category = 'MARKETING',
    required this.content,
    this.providerTemplateId,
    this.status = 'APPROVED',
    this.variables,
  });

  factory WhatsAppTemplate.fromJson(Map<String, dynamic> json) {
    return WhatsAppTemplate(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Template',
      templateName: json['templateName']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      category: json['category']?.toString() ?? 'MARKETING',
      content: json['content']?.toString() ?? '',
      providerTemplateId: json['providerTemplateId']?.toString(),
      status: json['status']?.toString() ?? 'APPROVED',
      variables: json['variables']?.toString(),
    );
  }
}
