import '../../../../core/errors/failures.dart';
import '../../../../core/auth/token_role_helper.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/enums.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl([this._api, this._tokenRoleHelper]);

  final ApiClientHelper? _api;
  final TokenRoleHelper? _tokenRoleHelper;

  Future<UserRole?> _role() async => await _tokenRoleHelper?.resolve();

  @override
  Future<Result<WalletSummary>> getSummary() async {
    if (_api == null) return _apiNotConfigured();

    final role = await _role();
    final path = role != null
        ? ApiEndpoints.roleWallet(role)
        : ApiEndpoints.wallet;

    WalletSummary parseWallet(dynamic data) {
      final map = Map<String, dynamic>.from(data as Map);
      final balance = (map['availableBalance'] as num?)?.toDouble() ??
          (map['available'] as num?)?.toDouble() ??
          (map['balance'] as num?)?.toDouble() ??
          0;
      final pending = (map['pendingBalance'] as num?)?.toDouble() ??
          (map['pending'] as num?)?.toDouble() ??
          0;
      final lifetime = (map['totalEarnings'] as num?)?.toDouble() ??
          (map['lifetime'] as num?)?.toDouble() ??
          balance;
      return WalletSummary(
        available: balance,
        pending: pending,
        lifetime: lifetime,
        escrow: (map['escrow'] as num?)?.toDouble() ?? 0,
      );
    }

    var result = await _api.get<WalletSummary>(
      path,
      parser: parseWallet,
    );
    if (result.isFailure && role == UserRole.freelancer) {
      final summaryRes = await _api.get<WalletSummary>(
        '/freelancer/wallet/summary',
        parser: parseWallet,
      );
      if (summaryRes.isSuccess) result = summaryRes;
    }
    return result;
  }

  @override
  Future<Result<Paginated<WalletTransaction>>> getTransactions(
    QueryParams params,
  ) async {
    if (_api == null) return _apiNotConfigured();

    final role = await _role();
    final path = role != null
        ? '${ApiEndpoints.roleWallet(role)}/transactions'
        : ApiEndpoints.walletTransactions;

    final result = await _api.getEnvelope<Paginated<WalletTransaction>>(
      path,
      query: params.toApiQuery(),
      parser: (envelope) => ApiResponse.parsePaginated(
        envelope.data,
        envelope.meta,
        _transactionFromJson,
        fallbackPage: params.page,
      ),
    );
    return result;
  }

  @override
  Future<Result<Paginated<Invoice>>> getInvoices(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();

    final role = await _role();
    final path = role == UserRole.freelancer
        ? ApiEndpoints.freelancerWalletPaymentHistory
        : role != null
        ? '/${ApiEndpoints.rolePath(role)}/invoices'
        : ApiEndpoints.invoices;

    final result = await _api.getEnvelope<Paginated<Invoice>>(
      path,
      query: params.toApiQuery(),
      parser: (envelope) => ApiResponse.parsePaginated(
        envelope.data,
        envelope.meta,
        _invoiceFromJson,
        fallbackPage: params.page,
      ),
    );
    return result;
  }

  @override
  Future<Result<WalletTransaction>> getTransaction(String id) async {
    if (_api == null) return _apiNotConfigured();
    final role = await _role();
    final path = role != null
        ? '${ApiEndpoints.roleWallet(role)}/transactions/$id'
        : '${ApiEndpoints.walletTransactions}/$id';
    return _api.get<WalletTransaction>(
      path,
      parser: (data) =>
          _transactionFromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<Result<Invoice>> getInvoice(String id) async {
    if (_api == null) return _apiNotConfigured();

    final role = await _role();
    if (role == UserRole.freelancer) {
      final listRes = await getInvoices(
        const QueryParams(page: 1, pageSize: 100),
      );
      return listRes.fold((failure) => Err(failure), (page) {
        final match = page.items.where((i) => i.id == id);
        if (match.isEmpty) return const Err(NotFoundFailure());
        return Success(match.first);
      });
    }
    final path = role != null
        ? '/${ApiEndpoints.rolePath(role)}/invoices/$id'
        : '${ApiEndpoints.invoices}/$id';
    final result = await _api.get<Invoice>(
      path,
      parser: (data) =>
          _invoiceFromJson(Map<String, dynamic>.from(data as Map)),
    );
    return result;
  }

  @override
  Future<Result<String>> requestWithdrawal({
    required double amount,
    required String method,
    Map<String, dynamic>? bankDetails,
    Map<String, dynamic>? upiDetails,
  }) async {
    if (_api == null) return _apiNotConfigured();
    final role = await _role();
    final path = role != null
        ? '/${ApiEndpoints.rolePath(role)}/wallet/withdraw'
        : ApiEndpoints.freelancerWalletWithdraw;

    final body = <String, dynamic>{
      'amount': amount,
      'payoutMethod': method == 'bank' ? 'bank_transfer' : method,
      'method': method,
      if (method == 'bank' && bankDetails != null) ...{
        'bankDetails': bankDetails,
        'accountDetails': {
          'accountNumber':
              bankDetails['accountNumber'] ??
              bankDetails['account_number'] ??
              '',
          'ifscCode': bankDetails['ifscCode'] ?? bankDetails['ifsc'] ?? '',
          'accountHolderName':
              bankDetails['accountHolderName'] ??
              bankDetails['holderName'] ??
              '',
        },
      },
      if (method == 'upi' && upiDetails != null) 'upiDetails': upiDetails,
    };

    var res = await _api.postEnvelopeAcceptingHttpSuccess<String>(
      path,
      body: body,
      parser: (envelope) => envelope.message?.trim().isNotEmpty == true
          ? envelope.message!.trim()
          : 'Withdrawal requested',
    );
    if (res.isFailure && path != ApiEndpoints.freelancerWalletWithdraw) {
      final fallback = await _api.postEnvelopeAcceptingHttpSuccess<String>(
        ApiEndpoints.freelancerWalletWithdraw,
        body: body,
        parser: (envelope) => envelope.message?.trim().isNotEmpty == true
            ? envelope.message!.trim()
            : 'Withdrawal requested',
      );
      if (fallback.isSuccess) res = fallback;
    }
    return res;
  }

  @override
  Future<Result<String>> addMoney({
    required double amount,
    required String gateway,
    required String currency,
    required String purpose,
  }) async {
    if (_api == null) return _apiNotConfigured();
    return _api.postEnvelopeAcceptingHttpSuccess<String>(
      ApiEndpoints.clientPaymentsInitiate,
      body: {
        'amount': amount,
        'gateway': gateway,
        'currency': currency,
        'purpose': purpose,
      },
      parser: (envelope) => envelope.message?.trim().isNotEmpty == true
          ? envelope.message!.trim()
          : 'Payment initiated successfully',
    );
  }

  static WalletTransaction _transactionFromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      title:
          json['title'] as String? ??
          json['description'] as String? ??
          json['reason'] as String? ??
          'Transaction',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: _parseType(json['type'] as String?),
      date:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      reference: json['reference'] as String? ?? '',
      status: _capitalize(
        json['status'] as String? ??
            json['transactionStatus'] as String? ??
            json['transaction_status'] as String? ??
            json['paymentStatus'] as String? ??
            'Completed',
      ),
      direction: json['direction'] as String? ?? '',
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static Invoice _invoiceFromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id']?.toString() ?? '',
      number:
          json['number'] as String? ?? json['invoiceNumber'] as String? ?? '',
      party: json['party'] as String? ?? json['clientName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      issuedAt:
          DateTime.tryParse(json['issuedAt'] as String? ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? 'Pending',
    );
  }

  static TransactionType _parseType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'credit':
        return TransactionType.credit;
      case 'debit':
        return TransactionType.debit;
      case 'withdrawal':
        return TransactionType.withdrawal;
      case 'escrow':
        return TransactionType.escrow;
      case 'refund':
        return TransactionType.refund;
      default:
        return TransactionType.credit;
    }
  }

  Future<Result<T>> _apiNotConfigured<T>() async =>
      const Err(ServerFailure('Live API client is not configured.'));
}
