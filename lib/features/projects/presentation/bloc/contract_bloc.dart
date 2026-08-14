import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

// Events
abstract class ContractEvent extends Equatable {
  const ContractEvent();
  @override
  List<Object?> get props => [];
}

class ContractFetchRequested extends ContractEvent {
  const ContractFetchRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class ContractCreateRequested extends ContractEvent {
  const ContractCreateRequested(this.data);
  final Map<String, dynamic> data;
  @override
  List<Object?> get props => [data];
}

class ContractUpdateRequested extends ContractEvent {
  const ContractUpdateRequested(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  @override
  List<Object?> get props => [id, data];
}

class ContractActionRequested extends ContractEvent {
  const ContractActionRequested(this.id, this.action, this.endpoint);
  final String id;
  final String action;
  final String endpoint;
  @override
  List<Object?> get props => [id, action, endpoint];
}

// States
abstract class ContractState extends Equatable {
  const ContractState();
  @override
  List<Object?> get props => [];
}

class ContractInitial extends ContractState {}

class ContractLoading extends ContractState {}

class ContractLoaded extends ContractState {
  const ContractLoaded(this.contract);
  final Contract contract;
  @override
  List<Object?> get props => [contract];
}

class ContractActionLoading extends ContractState {
  const ContractActionLoading(this.action);
  final String action;
  @override
  List<Object?> get props => [action];
}

class ContractActionSuccess extends ContractState {
  const ContractActionSuccess(this.message, {this.contract});
  final String message;
  final Contract? contract;
  @override
  List<Object?> get props => [message, contract];
}

class ContractActionFailure extends ContractState {
  const ContractActionFailure(this.errorMessage);
  final String errorMessage;
  @override
  List<Object?> get props => [errorMessage];
}

class ContractFailure extends ContractState {
  const ContractFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// Bloc
class ContractBloc extends Bloc<ContractEvent, ContractState> {
  ContractBloc(this._repository) : super(ContractInitial()) {
    on<ContractFetchRequested>(_onFetch);
    on<ContractCreateRequested>(_onCreate);
    on<ContractUpdateRequested>(_onUpdate);
  }

  final ProjectRepository _repository;

  Future<void> _onFetch(
    ContractFetchRequested event,
    Emitter<ContractState> emit,
  ) async {
    emit(ContractLoading());
    final res = await _repository.getContract(event.id);
    res.fold(
      (f) => emit(ContractFailure(f.message)),
      (contract) => emit(ContractLoaded(contract)),
    );
  }

  Future<void> _onCreate(
    ContractCreateRequested event,
    Emitter<ContractState> emit,
  ) async {
    emit(const ContractActionLoading('create'));
    final res = await _repository.createContract(event.data);
    res.fold(
      (f) => emit(ContractActionFailure(f.message)),
      (contract) => emit(
        ContractActionSuccess(
          'Contract created successfully',
          contract: contract,
        ),
      ),
    );
  }

  Future<void> _onUpdate(
    ContractUpdateRequested event,
    Emitter<ContractState> emit,
  ) async {
    emit(const ContractActionLoading('update'));
    final res = await _repository.updateContract(event.id, event.data);
    res.fold(
      (f) => emit(ContractActionFailure(f.message)),
      (contract) => emit(
        ContractActionSuccess(
          'Contract updated successfully',
          contract: contract,
        ),
      ),
    );
  }
}
