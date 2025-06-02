import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';

/// Interactive Sudoku board widget with full game functionality
class SudokuBoardWidget extends StatefulWidget {
  final SudokuBoard board;
  final Position? selectedPosition;
  final bool isNotesMode;
  final bool showConflicts;
  final bool showHints;
  final Set<Position> highlightedCells;
  final Set<Position> errorCells;
  final Set<Position> hintCells;
  final Function(Position position) onCellTap;
  final Function(Position position, int value) onCellInput;
  final Function(Position position, Set<int> notes) onNotesUpdate;
  final VoidCallback? onBoardComplete;
  const SudokuBoardWidget({
    super.key,
    required this.board,
    this.selectedPosition,
    this.isNotesMode = false,
    this.showConflicts = true,
    this.showHints = true,
    this.highlightedCells = const {},
    this.errorCells = const {},
    this.hintCells = const {},
    required this.onCellTap,
    required this.onCellInput,
    required this.onNotesUpdate,
    this.onBoardComplete,
  });

  @override
  State<SudokuBoardWidget> createState() => _SudokuBoardWidgetState();
}

class _SudokuBoardWidgetState extends State<SudokuBoardWidget>
    with TickerProviderStateMixin {
  late AnimationController _completionAnimationController;
  late AnimationController _errorAnimationController;
  late Animation<double> _completionAnimation;
  late Animation<double> _errorAnimation;

  @override
  void initState() {
    super.initState();
    
    // Completion animation
    _completionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _completionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _completionAnimationController,
      curve: Curves.elasticOut,
    ));

    // Error animation
    _errorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _errorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _errorAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _completionAnimationController.dispose();
    _errorAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SudokuBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger completion animation if board is complete
    if (widget.board.isComplete && !oldWidget.board.isComplete) {
      _completionAnimationController.forward();
      widget.onBoardComplete?.call();
    }
    
    // Trigger error animation if new errors appeared
    if (widget.errorCells.isNotEmpty && oldWidget.errorCells.isEmpty) {
      _errorAnimationController.forward().then((_) {
        _errorAnimationController.reverse();
      });
    }
  }  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = _calculateBoardSize(constraints);
        final cellSize = boardSize / 9;
        
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: boardSize,
              maxHeight: boardSize,
            ),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedBuilder(
                    animation: _completionAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_completionAnimation.value * 0.05),
                        child: _buildGrid(cellSize),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }  double _calculateBoardSize(BoxConstraints constraints) {
    const minSize = 250.0;
    const maxSize = 380.0; // Reduced max size for better fit
    const padding = 64.0; // Increased padding for more safety
    
    final availableWidth = constraints.maxWidth - padding;
    final availableHeight = constraints.maxHeight - padding;
    
    // Use the smaller dimension to ensure it fits in both directions
    final availableSize = availableWidth < availableHeight ? availableWidth : availableHeight;
    
    // Ensure the size is within bounds and a multiple of 9 for clean cell sizing
    final clampedSize = availableSize.clamp(minSize, maxSize);
    final calculatedSize = (clampedSize ~/ 9) * 9.0;
    
    // Additional safety check to ensure we don't exceed constraints
    return calculatedSize.clamp(minSize, constraints.maxWidth.isFinite ? constraints.maxWidth - padding : maxSize);
  }  Widget _buildGrid(double cellSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(9, (row) {
        return Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(9, (col) {
              final position = Position(row, col);
              final cell = widget.board.getCellAt(position);
              
              return Expanded(
                child: _SudokuCellWidget(
                  cell: cell,
                  position: position,
                  size: cellSize,
                  isSelected: widget.selectedPosition == position,
                  isHighlighted: widget.highlightedCells.contains(position),
                  hasError: widget.errorCells.contains(position),
                  isHinted: widget.hintCells.contains(position),
                  showConflicts: widget.showConflicts,
                  onTap: () => widget.onCellTap(position),
                  errorAnimation: _errorAnimation,
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

/// Individual Sudoku cell widget
class _SudokuCellWidget extends StatelessWidget {
  final SudokuCell cell;
  final Position position;
  final double size;
  final bool isSelected;
  final bool isHighlighted;
  final bool hasError;
  final bool isHinted;
  final bool showConflicts;
  final VoidCallback onTap;
  final Animation<double> errorAnimation;

  const _SudokuCellWidget({
    required this.cell,
    required this.position,
    required this.size,
    required this.isSelected,
    required this.isHighlighted,
    required this.hasError,
    required this.isHinted,
    required this.showConflicts,
    required this.onTap,
    required this.errorAnimation,
  });  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedBuilder(
      animation: errorAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: hasError 
              ? Offset(errorAnimation.value * 5 * (1 - 2 * (errorAnimation.value % 0.5) / 0.5), 0)
              : Offset.zero,
          child: GestureDetector(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: size,
                  maxHeight: size,
                ),
                decoration: BoxDecoration(
                  color: _getCellColor(colorScheme),
                  border: _getCellBorder(theme),
                ),
                child: _buildCellContent(theme),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCellColor(ColorScheme colorScheme) {
    if (hasError && showConflicts) {
      return colorScheme.errorContainer;
    }
    if (isHinted) {
      return colorScheme.secondaryContainer;
    }
    if (isSelected) {
      return colorScheme.primaryContainer;
    }
    if (isHighlighted) {
      return colorScheme.surfaceVariant;
    }
    if (cell.isFixed) {
      return colorScheme.surface;
    }
    return colorScheme.background;
  }

  Border _getCellBorder(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final row = position.row;
    final col = position.col;
    
    return Border(
      top: BorderSide(
        color: row % 3 == 0 
            ? colorScheme.outline 
            : colorScheme.outlineVariant,
        width: row % 3 == 0 ? 2 : 1,
      ),
      left: BorderSide(
        color: col % 3 == 0 
            ? colorScheme.outline 
            : colorScheme.outlineVariant,
        width: col % 3 == 0 ? 2 : 1,
      ),
      right: BorderSide(
        color: (col + 1) % 3 == 0 
            ? colorScheme.outline 
            : colorScheme.outlineVariant,
        width: (col + 1) % 3 == 0 ? 2 : 1,
      ),
      bottom: BorderSide(
        color: (row + 1) % 3 == 0 
            ? colorScheme.outline 
            : colorScheme.outlineVariant,
        width: (row + 1) % 3 == 0 ? 2 : 1,
      ),
    );
  }

  Widget _buildCellContent(ThemeData theme) {
    if (cell.value != 0) {
      return _buildValueDisplay(theme);
    } else if (cell.notes.isNotEmpty) {
      return _buildNotesDisplay(theme);
    } else {
      return const SizedBox.shrink();
    }
  }
  Widget _buildValueDisplay(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          cell.value.toString(),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: size * 0.6, // Make font size relative to cell size
            fontWeight: cell.isFixed ? FontWeight.bold : FontWeight.w500,
            color: hasError && showConflicts
                ? colorScheme.error
                : cell.isFixed
                    ? colorScheme.onSurface
                    : colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesDisplay(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final number = index + 1;
          final hasNote = cell.notes.contains(number);
          
          return Center(
            child: Text(
              hasNote ? number.toString() : '',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: size * 0.12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Number input panel for the Sudoku board
class NumberInputPanel extends StatelessWidget {
  final bool isNotesMode;
  final Function(int number) onNumberSelected;
  final VoidCallback onNotesToggle;
  final VoidCallback onClear;
  final Set<int> availableNumbers;
  final Map<int, int> numberCounts;

  const NumberInputPanel({
    super.key,
    required this.isNotesMode,
    required this.onNumberSelected,
    required this.onNotesToggle,
    required this.onClear,
    this.availableNumbers = const {1, 2, 3, 4, 5, 6, 7, 8, 9},
    this.numberCounts = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
      return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode toggle and clear button
          Row(
            children: [
              Expanded(
                child: _buildModeToggle(theme),
              ),
              const SizedBox(width: 12),
              _buildClearButton(theme),
            ],
          ),
          
          const SizedBox(height: 12),          // Number grid
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final number = index + 1;
                  final count = numberCounts[number] ?? 0;
                  return _NumberButton(
                    number: number,
                    isEnabled: count < 9, // Only disable when all 9 instances are used
                    count: count,
                    onTap: () => onNumberSelected(number),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: onNotesToggle,
      icon: Icon(
        isNotesMode ? Icons.edit : Icons.edit_outlined,
        size: 20,
      ),
      label: Text(
        isNotesMode ? 'Notes Mode' : 'Number Mode',
        style: theme.textTheme.bodyMedium,
      ),      style: OutlinedButton.styleFrom(
        backgroundColor: isNotesMode 
            ? theme.colorScheme.secondaryContainer 
            : null,
        foregroundColor: isNotesMode 
            ? theme.colorScheme.onSecondaryContainer 
            : theme.colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildClearButton(ThemeData theme) {
    return IconButton.outlined(
      onPressed: onClear,
      icon: const Icon(Icons.backspace_outlined),
      tooltip: 'Clear cell',
    );
  }
}

/// Individual number button in the input panel
class _NumberButton extends StatelessWidget {
  final int number;
  final bool isEnabled;
  final int count;
  final VoidCallback onTap;

  const _NumberButton({
    required this.number,
    required this.isEnabled,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isComplete = count >= 9;
    
    return Material(
      color: isComplete 
          ? colorScheme.surfaceVariant 
          : colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isEnabled && !isComplete ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isComplete 
                      ? colorScheme.onSurfaceVariant 
                      : isEnabled 
                          ? colorScheme.onSurface 
                          : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '$count/9',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
