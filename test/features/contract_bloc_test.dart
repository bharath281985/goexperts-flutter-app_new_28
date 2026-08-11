import 'package:flutter_test/flutter_test.dart';
import 'package:goexperts_app/features/projects/presentation/bloc/contract_bloc.dart';
import 'package:goexperts_app/features/projects/domain/repositories/project_repository.dart';
import 'package:goexperts_app/core/utils/result.dart';
import 'package:goexperts_app/core/errors/failures.dart';
import 'package:goexperts_app/core/utils/enums.dart';
import 'package:goexperts_app/features/projects/domain/entities/project.dart';

class MockProjectRepository implements ProjectRepository {
  @override
  Future<Result<Contract>> getContract(String id) async {
    if (id == 'invalid') {
      return const Err(ServerFailure('Contract not found'));
    }
    return Success(
      Contract(
        id: id,
        projectTitle: 'Test Contract',
        counterpartyName: 'John Freelancer',
        amount: 50000,
        status: EntityStatus.active,
        startDate: DateTime(2026, 1, 1),
        milestones: const [],
        progress: 0.5,
      ),
    );
  }

  @override
  Future<Result<Contract>> createContract(Map<String, dynamic> data) async {
    return Success(
      Contract(
        id: 'c-101',
        projectTitle: data['title']?.toString() ?? 'Created Contract',
        counterpartyName: data['counterpartyName']?.toString() ?? 'Freelancer',
        amount: (data['amount'] as num?)?.toDouble() ?? 10000,
        status: EntityStatus.draft,
        startDate: DateTime.now(),
        milestones: const [],
        progress: 0.0,
      ),
    );
  }

  @override
  Future<Result<Contract>> updateContract(String id, Map<String, dynamic> data) async {
    return Success(
      Contract(
        id: id,
        projectTitle: data['title']?.toString() ?? 'Updated Contract',
        counterpartyName: 'Freelancer',
        amount: 20000,
        status: EntityStatus.active,
        startDate: DateTime.now(),
        milestones: const [],
        progress: 0.2,
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ContractBloc Unit Tests', () {
    late MockProjectRepository mockRepo;
    late ContractBloc bloc;

    setUp(() {
      mockRepo = MockProjectRepository();
      bloc = ContractBloc(mockRepo);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is ContractInitial', () {
      expect(bloc.state, isA<ContractInitial>());
    });

    test('emits [ContractLoading, ContractLoaded] on successful fetch', () async {
      final expected = [
        isA<ContractLoading>(),
        isA<ContractLoaded>(),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(const ContractFetchRequested('c-1'));
    });

    test('emits [ContractLoading, ContractFailure] on failed fetch', () async {
      final expected = [
        isA<ContractLoading>(),
        isA<ContractFailure>(),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(const ContractFetchRequested('invalid'));
    });

    test('emits [ContractActionLoading, ContractActionSuccess] on create', () async {
      final expected = [
        isA<ContractActionLoading>(),
        isA<ContractActionSuccess>(),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(const ContractCreateRequested({'title': 'New Contract', 'amount': 15000}));
    });
  });
}
