class WsapTemplate {
  String? id;
  bool usepng;
  String language;
  String content;
  String category;

  WsapTemplate({
    this.id,
    this.usepng = true,
    required this.category,
    required this.content,
    required this.language,
  });

  factory WsapTemplate.fromMap({id, map}) {
    return WsapTemplate(
      id: id,
      usepng: (map?.containsKey('usepng') ?? false) ? map!['usepng'] : true,
      category: map['category'],
      content: map['content'],
      language: map['language'],
    );
  }
}
