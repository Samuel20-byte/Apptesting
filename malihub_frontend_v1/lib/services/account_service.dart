import '../models/account.dart';
import 'api_client.dart';

class AccountService {
  final _client = ApiClient.instance;

  Future<List<Account>> getAccounts() async {
    final data = await _client.get('/accounts') as List;
    return data.map((e) => Account.fromJson(e)).toList();
  }

  Future<Account> createAccount({
    required String accountName,
    required String accountType,
    double balance = 0,
  }) async {
    final data = await _client.post('/accounts', body: {
      'account_name': accountName,
      'account_type': accountType,
      'balance': balance,
    });
    return Account.fromJson(data);
  }

  /// The UI doesn't have an "add account" screen yet — the schema requires
  /// every transaction to belong to an account, so we lazily create one
  /// "Main Account" the first time a user needs one (e.g. right after
  /// registering, or before their first transaction). Returns the user's
  /// first account, creating it if the list is empty.
  Future<Account> ensureDefaultAccount() async {
    final accounts = await getAccounts();
    if (accounts.isNotEmpty) return accounts.first;
    return createAccount(accountName: 'Main Account', accountType: 'cash');
  }
}
