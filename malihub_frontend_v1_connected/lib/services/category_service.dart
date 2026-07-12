import '../models/category.dart';
import 'api_client.dart';

class CategoryService {
  final _client = ApiClient.instance;

  Future<List<Category>> getCategories() async {
    final data = await _client.get('/categories') as List;
    return data.map((e) => Category.fromJson(e)).toList();
  }

  /// [categoryType] must be 'income' or 'expense' — the backend now
  /// requires this on every custom category, matching the same rule
  /// applied to the built-in defaults.
  Future<Category> createCategory({
    required String categoryName,
    required String categoryType,
    String? icon,
  }) async {
    final data = await _client.post('/categories', body: {
      'category_name': categoryName,
      'category_type': categoryType,
      if (icon != null) 'icon': icon,
    });
    return Category.fromJson(data);
  }
}
