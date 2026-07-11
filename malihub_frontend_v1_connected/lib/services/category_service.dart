import '../models/category.dart';
import 'api_client.dart';

class CategoryService {
  final _client = ApiClient.instance;

  Future<List<Category>> getCategories() async {
    final data = await _client.get('/categories') as List;
    return data.map((e) => Category.fromJson(e)).toList();
  }

  Future<Category> createCategory({required String categoryName, String? icon}) async {
    final data = await _client.post('/categories', body: {
      'category_name': categoryName,
      if (icon != null) 'icon': icon,
    });
    return Category.fromJson(data);
  }
}
