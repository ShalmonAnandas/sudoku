import 'package:equatable/equatable.dart';

/// Represents a single cell in the Sudoku grid
class SudokuCell extends Equatable {
  /// The value in the cell (1-9), or 0 if empty
  final int value;

  /// Whether this cell contains a fixed clue (given at puzzle start)
  final bool isFixed;

  /// Notes/pencil marks for this cell (possible values)
  final Set<int> notes;

  /// Whether the current value is valid (no conflicts)
  final bool isValid;

  /// Whether this cell is currently selected
  final bool isSelected;

  /// Whether this cell is highlighted (same number as selected cell)
  final bool isHighlighted;

  const SudokuCell({
    this.value = 0,
    this.isFixed = false,
    this.notes = const {},
    this.isValid = true,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  /// Creates an empty cell
  const SudokuCell.empty() : this();

  /// Creates a fixed clue cell
  const SudokuCell.clue(int value) : this(value: value, isFixed: true);

  /// Whether the cell is empty (has no value)
  bool get isEmpty => value == 0;

  /// Whether the cell has a value
  bool get hasValue => value != 0;

  /// Whether the cell can be edited (not a fixed clue)
  bool get isEditable => !isFixed;

  /// Whether the cell has notes
  bool get hasNotes => notes.isNotEmpty;

  /// Copy this cell with updated properties
  SudokuCell copyWith({
    int? value,
    bool? isFixed,
    Set<int>? notes,
    bool? isValid,
    bool? isSelected,
    bool? isHighlighted,
  }) {
    return SudokuCell(
      value: value ?? this.value,
      isFixed: isFixed ?? this.isFixed,
      notes: notes ?? this.notes,
      isValid: isValid ?? this.isValid,
      isSelected: isSelected ?? this.isSelected,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  /// Create a copy with a new value and clear notes
  SudokuCell setValue(int newValue) {
    return copyWith(
      value: newValue,
      notes: const {},
    );
  }

  /// Create a copy with cleared value
  SudokuCell clearValue() {
    return copyWith(value: 0);
  }

  /// Create a copy with updated notes
  SudokuCell updateNotes(Set<int> newNotes) {
    return copyWith(notes: newNotes);
  }

  /// Add a note to this cell
  SudokuCell addNote(int note) {
    final newNotes = Set<int>.from(notes)..add(note);
    return copyWith(notes: newNotes);
  }

  /// Remove a note from this cell
  SudokuCell removeNote(int note) {
    final newNotes = Set<int>.from(notes)..remove(note);
    return copyWith(notes: newNotes);
  }

  /// Toggle a note in this cell
  SudokuCell toggleNote(int note) {
    return notes.contains(note) ? removeNote(note) : addNote(note);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'value': value,
        'isFixed': isFixed,
        'notes': notes.toList(),
        'isValid': isValid,
        'isSelected': isSelected,
        'isHighlighted': isHighlighted,
      };

  /// Create from JSON
  factory SudokuCell.fromJson(Map<String, dynamic> json) => SudokuCell(
        value: json['value'] as int,
        isFixed: json['isFixed'] as bool,
        notes: Set<int>.from(json['notes'] as List),
        isValid: json['isValid'] as bool,
        isSelected: json['isSelected'] as bool,
        isHighlighted: json['isHighlighted'] as bool,
      );

  @override
  List<Object?> get props => [
        value,
        isFixed,
        notes,
        isValid,
        isSelected,
        isHighlighted,
      ];

  @override
  String toString() {
    return 'SudokuCell(value: $value, isFixed: $isFixed, notes: $notes, '
        'isValid: $isValid, isSelected: $isSelected, isHighlighted: $isHighlighted)';
  }
}
