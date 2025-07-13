import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_model.dart';

class FoodSearchService {
  static final CollectionReference<Map<String, dynamic>> _foodsCollection =
      FirebaseFirestore.instance.collection('foods');

  // cache sederhana
  static final List<String> _recentSearches = [];
  static final List<String> _favoriteFoodIds = [];

  /* ───────────────────────── util ─────────────────────────── */

  static double _toDouble(dynamic v) =>
      (v == null) ? 0.0 : (v as num).toDouble();

  static Future<QuerySnapshot<Map<String, dynamic>>> _safeGet(
    Query<Map<String, dynamic>> q,
  ) async {
    try {
      return await q.get();
    } on FirebaseException {
      rethrow;
    }
  }

  /* ───────────────────────── mapper ────────────────────────── */

  static FoodModel _docToFoodModel(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final nutritionInfo = NutritionInfo(
      calories: _toDouble(d['calories']),
      protein: _toDouble(d['proteins']),
      carbs: _toDouble(d['carbohydrate']),
      fat: _toDouble(d['fat']),
      fiber: 0,
      sugar: 0,
      sodium: 0,
    );
    return FoodModel(
      id: doc.id,
      name: d['name'] ?? '',
      brand: d['brand'] ?? '',
      category: d['category'] ?? 'other',
      barcode: d['barcode'],
      imageUrl: (d['image'] as String?)?.isNotEmpty == true ? d['image'] : null,
      nutritionPer100g: nutritionInfo,
      servingSizes:
          (d['servingSizes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['100g'],
      isVerified: d['isVerified'] ?? true,
      isCustom: d['isCustom'] ?? false,
      createdBy: d['createdBy'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /* ───────────────────────── paging ────────────────────────── */

  static Future<(List<FoodModel>, DocumentSnapshot<Map<String, dynamic>>?)>
  fetchFoodsPage({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? last,
  }) async {
    Query<Map<String, dynamic>> q = _foodsCollection
        .orderBy('name')
        .orderBy(FieldPath.documentId)
        .limit(limit);
    if (last != null) q = q.startAfterDocument(last);

    final snap = await _safeGet(q);
    final docs = snap.docs.map(_docToFoodModel).toList();
    final cursor = snap.docs.isEmpty ? null : snap.docs.last;
    return (docs, cursor);
  }

  /* ──────────────────────── search & sug ───────────────────── */

  /// Case-insensitive search on `name` field,
  /// sepenuhnya di client-side (tanpa `name_lowercase`).
  static Future<List<FoodModel>> searchFoods(
    String query, {
    int limit = 20,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return getPopularFoods(limit: limit);
    }

    // ambil semua dokumen, lalu filter case-insensitive
    final snap = await _foodsCollection.get();
    final all = snap.docs.map(_docToFoodModel);
    final filtered = all
        .where((f) => f.name.toLowerCase().contains(q))
        .take(limit)
        .toList();
    return filtered;
  }

  /// Case-insensitive suggestions on `name`
  static Future<List<String>> getSuggestions(
    String query, {
    int limit = 5,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final snap = await _foodsCollection.get();
    final allNames = snap.docs
        .map((d) => (d.data()['name'] ?? '').toString())
        .where((name) => name.toLowerCase().contains(q))
        .toList();

    // unique & take limit
    final seen = <String>{};
    final suggestions = <String>[];
    for (var name in allNames) {
      if (suggestions.length >= limit) break;
      if (seen.add(name.toLowerCase())) {
        suggestions.add(name);
      }
    }
    return suggestions;
  }

  /* ─────────────────── kategori & rekomendasi ───────────────── */

  static Future<List<FoodModel>> getPopularFoods({int limit = 20}) async {
    final snap = await _foodsCollection.orderBy('name').limit(limit).get();
    return snap.docs.map(_docToFoodModel).toList();
  }

  static Future<List<FoodModel>> getHighProteinFoods({int limit = 10}) async {
    final snap = await _foodsCollection
        .orderBy('proteins', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(_docToFoodModel).toList();
  }

  static Future<List<FoodModel>> getLowCalorieFoods({int limit = 10}) async {
    final snap = await _foodsCollection.orderBy('calories').limit(limit).get();
    return snap.docs.map(_docToFoodModel).toList();
  }

  static Future<List<FoodModel>> getMealTimeSuggestions() async {
    final snap = await _foodsCollection.limit(100).get();
    final docs = snap.docs..shuffle();
    return docs.take(10).map(_docToFoodModel).toList();
  }

  /* ───────────── favourite & recent ─────────── */

  static void addToRecentSearches(String foodName) {
    final lower = foodName.toLowerCase();
    _recentSearches.removeWhere((e) => e.toLowerCase() == lower);
    _recentSearches.add(foodName);
    if (_recentSearches.length > 20) _recentSearches.removeAt(0);
  }

  static Future<List<FoodModel>> getRecentFoods() async {
    List<FoodModel> list = [];
    for (final term in _recentSearches.reversed) {
      final f = await getFoodByName(term);
      if (f != null) list.add(f);
    }
    return list.take(10).toList();
  }

  static void addToFavorites(String id) {
    if (!_favoriteFoodIds.contains(id)) _favoriteFoodIds.add(id);
  }

  static void removeFromFavorites(String id) => _favoriteFoodIds.remove(id);
  static bool isFavorite(String id) => _favoriteFoodIds.contains(id);

  static Future<List<FoodModel>> getFavoriteFoods() async {
    if (_favoriteFoodIds.isEmpty) return [];
    final chunks = <List<String>>[];
    for (var i = 0; i < _favoriteFoodIds.length; i += 10) {
      chunks.add(
        _favoriteFoodIds.sublist(
          i,
          i + 10 > _favoriteFoodIds.length ? _favoriteFoodIds.length : i + 10,
        ),
      );
    }
    List<FoodModel> res = [];
    for (final c in chunks) {
      final snap = await _foodsCollection
          .where(FieldPath.documentId, whereIn: c)
          .get();
      res.addAll(snap.docs.map(_docToFoodModel));
    }
    return res;
  }

  /* ─────────────────────── fetch by id/nama ─────────────────── */

  static Future<FoodModel?> getFoodById(String id) async {
    final doc = await _foodsCollection.doc(id).get();
    return doc.exists ? _docToFoodModel(doc) : null;
  }

  static Future<FoodModel?> getFoodByName(String name) async {
    final snap = await _foodsCollection
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : _docToFoodModel(snap.docs.first);
  }

  static Future<List<FoodModel>> getFoodsByNames(List<String> names) async {
    if (names.isEmpty) return [];
    final chunks = <List<String>>[];
    for (var i = 0; i < names.length; i += 10) {
      chunks.add(
        names.sublist(i, i + 10 > names.length ? names.length : i + 10),
      );
    }
    List<FoodModel> res = [];
    for (final c in chunks) {
      final snap = await _foodsCollection.where('name', whereIn: c).get();
      res.addAll(snap.docs.map(_docToFoodModel));
    }
    return res;
  }

  /* ──────────────────────── statistik ───────────────────────── */

  static Future<int?> getTotalFoodsCount() async {
    try {
      final agg = await _foodsCollection.count().get();
      return agg.count;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, int>> getCategoryStats() async {
    final snap = await _foodsCollection.get();
    final Map<String, int> map = {};
    for (var d in snap.docs) {
      final cat = d.data()['category'] ?? 'other';
      map[cat] = (map[cat] ?? 0) + 1;
    }
    return map;
  }

  static Future<Map<String, double>> getNutritionStats() async {
    final snap = await _foodsCollection.get();
    double cal = 0, pro = 0, carb = 0, fat = 0;
    for (var d in snap.docs) {
      final data = d.data();
      cal += _toDouble(data['calories']);
      pro += _toDouble(data['proteins']);
      carb += _toDouble(data['carbohydrate']);
      fat += _toDouble(data['fat']);
    }
    final total = snap.size == 0 ? 1 : snap.size;
    return {
      'avgCalories': cal / total,
      'avgProtein': pro / total,
      'avgCarbs': carb / total,
      'avgFat': fat / total,
    };
  }

  static Future<List<FoodModel>> getRandomFoods({int count = 5}) async {
    final snap = await _foodsCollection.limit(100).get();
    final docs = snap.docs..shuffle();
    return docs.take(count).map(_docToFoodModel).toList();
  }

  /* ───────────────────────── getters ────────────────────────── */

  static List<String> get recentSearches => List.unmodifiable(_recentSearches);
  static List<String> get favoriteFoodIds =>
      List.unmodifiable(_favoriteFoodIds);
}
