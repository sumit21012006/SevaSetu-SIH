/// Represents a cited government source or resolution.
class AISource {
  const AISource({
    required this.id,
    required this.title,
    required this.authority,
    this.documentNumber,
    this.issueDate,
    this.url,
    this.category,
    this.serviceId,
    this.summary,
  });

  factory AISource.fromJson(Map<String, dynamic> json) {
    return AISource(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      authority: json['authority'] as String? ?? '',
      documentNumber: json['documentNumber'] as String?,
      issueDate: json['issueDate'] as String?,
      url: json['url'] as String?,
      category: json['category'] as String?,
      serviceId: json['serviceId'] as String?,
      summary: json['summary'] as String?,
    );
  }

  final String id;
  final String title;
  final String authority;
  final String? documentNumber;
  final String? issueDate;
  final String? url;
  final String? category;
  final String? serviceId;
  final String? summary;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'authority': authority,
        if (documentNumber != null) 'documentNumber': documentNumber,
        if (issueDate != null) 'issueDate': issueDate,
        if (url != null) 'url': url,
        if (category != null) 'category': category,
        if (serviceId != null) 'serviceId': serviceId,
        if (summary != null) 'summary': summary,
      };

  @override
  String toString() {
    final docStr = documentNumber != null ? ' ($documentNumber)' : '';
    return '$title$docStr - $authority';
  }
}
