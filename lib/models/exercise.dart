class Exercise {
  final int? id;
  final String name;
  final String? source; // e.g. "Hanon", "Czerny", "Scales"
  final String? notes;
  final String? book;
  final int? page;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Exercise({
    this.id,
    required this.name,
    this.source,
    this.notes,
    this.book,
    this.page,
    required this.createdAt,
    required this.updatedAt,
  });

  Exercise copyWith({
    int? id,
    String? name,
    String? source,
    String? notes,
    String? book,
    int? page,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearSource = false,
    bool clearNotes = false,
    bool clearBook = false,
    bool clearPage = false,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      source: clearSource ? null : (source ?? this.source),
      notes: clearNotes ? null : (notes ?? this.notes),
      book: clearBook ? null : (book ?? this.book),
      page: clearPage ? null : (page ?? this.page),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'source': source,
        'notes': notes,
        'book': book,
        'page': page,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as int?,
        name: map['name'] as String,
        source: map['source'] as String?,
        notes: map['notes'] as String?,
        book: map['book'] as String?,
        page: map['page'] as int?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  @override
  String toString() => 'Exercise(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
