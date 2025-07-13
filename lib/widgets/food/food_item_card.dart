import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/food_model.dart';
import '../../themes/color_constants.dart';

class FoodItemCard extends StatefulWidget {
  final FoodModel food;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool showNutrition;
  final bool isCompact;

  const FoodItemCard({
    super.key,
    required this.food,
    this.onTap,
    this.onFavoriteToggle,
    this.showNutrition = true,
    this.isCompact = false,
  });

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  bool _isFavorite = false;

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onFavoriteToggle?.call();
  }

  /* ───────────────────────── category helpers ─────────────────────────── */

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'grains':
        return Icons.rice_bowl;
      case 'protein':
        return Icons.set_meal;
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'dairy':
        return Icons.local_drink;
      case 'snacks':
        return Icons.cookie;
      case 'beverages':
        return Icons.local_cafe;
      default:
        return Icons.restaurant;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'grains':
        return Colors.amber;
      case 'protein':
        return Colors.red[400]!;
      case 'vegetables':
        return Colors.green;
      case 'fruits':
        return Colors.orange;
      case 'dairy':
        return Colors.blue;
      case 'snacks':
        return Colors.purple;
      case 'beverages':
        return Colors.cyan;
      default:
        return AppColors.primaryGreen;
    }
  }

  String _getCategoryDisplayName(String cat) {
    switch (cat) {
      case 'grains':
        return 'Karbohidrat';
      case 'protein':
        return 'Protein';
      case 'vegetables':
        return 'Sayuran';
      case 'fruits':
        return 'Buah';
      case 'dairy':
        return 'Dairy';
      case 'snacks':
        return 'Snack';
      case 'beverages':
        return 'Minuman';
      default:
        return 'Makanan';
    }
  }

  /* ────────────────────────────── UI ─────────────────────────────────── */

  @override
  Widget build(BuildContext context) =>
      widget.isCompact ? _buildCompactCard() : _buildFullCard();

  /// ── Kartu versi “mini” untuk carousel horizontal
  Widget _buildCompactCard() {
    final n = widget.food.nutritionPer100g;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      widget.food.category,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    _getCategoryIcon(widget.food.category),
                    color: _getCategoryColor(widget.food.category),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.food.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.showNutrition) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${n.calories.toInt()} kcal',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ── Kartu versi penuh (list vertikal)
  Widget _buildFullCard() {
    final n = widget.food.nutritionPer100g;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              /* ---------- avatar ---------- */
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                    widget.food.category,
                  ).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  _getCategoryIcon(widget.food.category),
                  color: _getCategoryColor(widget.food.category),
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              /* ---------- name + info ---------- */
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.food.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          widget.food.category,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getCategoryDisplayName(widget.food.category),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getCategoryColor(widget.food.category),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.showNutrition) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${n.calories.toStringAsFixed(0)} kcal per 100g',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildMacroChip(
                            'P',
                            '${n.protein.toStringAsFixed(1)}g',
                            Colors.red[400]!,
                          ),
                          const SizedBox(width: 6),
                          _buildMacroChip(
                            'C',
                            '${n.carbs.toStringAsFixed(1)}g',
                            Colors.amber[600]!,
                          ),
                          const SizedBox(width: 6),
                          _buildMacroChip(
                            'F',
                            '${n.fat.toStringAsFixed(1)}g',
                            Colors.blue[400]!,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              /* ---------- favourite + add ---------- */
              Column(
                children: [
                  IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.grey,
                          size: 22,
                        ),
                        onPressed: _toggleFavorite,
                      )
                      .animate(target: _isFavorite ? 1 : 0)
                      .scale(duration: 200.ms),
                  Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ---------- util chip ---------- */
  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
