class WsapTemplate {
  String? id;
  String language;
  String content;
  String category;

  WsapTemplate({
    this.id,
    required this.category,
    required this.content,
    required this.language,
  });

  factory WsapTemplate.fromMap({id, map}) {
    return WsapTemplate(
      id: id,
      category: map['category'],
      content: map['content'],
      language: map['language'],
    );
  }
}
