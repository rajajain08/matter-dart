/// Creates a region for the body.
class Region {
  late final String id;
  final int startCol;
  final int endCol;
  final int startRow;
  final int endRow;

  Region({
    required this.startCol,
    required this.endCol,
    required this.startRow,
    required this.endRow,
  }) {
    id = '$startCol,$endCol,$startRow,$endRow';
  }
}
