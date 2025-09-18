class Pagination {
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final int? nextPage;
  final int? previousPage;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    required this.nextPage,
    required this.previousPage,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'currentPage': currentPage,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrevious': hasPrevious,
      'nextPage': nextPage,
      'previousPage': previousPage,
    };
  }

  factory Pagination.fromMap(Map<String, dynamic> map) {
    return Pagination(
      currentPage: map['current_page'] as int,
      totalPages: map['total_pages'] as int,
      hasNext: map['has_next'] as bool,
      hasPrevious: map['has_previous'] as bool,
      nextPage: map['next_page'] as int?,
      previousPage: map['previous_page'] as int?,
    );
  }
}
