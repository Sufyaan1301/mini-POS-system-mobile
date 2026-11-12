import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/app_exception.dart';
import '../../../data/models/addon_model.dart';
import '../../../data/repositories/addon_repository.dart';

part 'addon_event.dart';
part 'addon_state.dart';

class AddonBloc extends Bloc<AddonEvent, AddonState> {
  AddonBloc({required AddonRepository repository})
      : _repository = repository,
        super(const AddonState()) {
    on<AddonsLoaded>(_onLoaded);
    on<AddonAdded>(_onAdded);
    on<AddonUpdated>(_onUpdated);
    on<AddonDeleted>(_onDeleted);
  }

  final AddonRepository _repository;

  Future<void> _onLoaded(
    AddonsLoaded event,
    Emitter<AddonState> emit,
  ) async {
    emit(state.copyWith(status: AddonStatus.loading));
    try {
      final list = await _repository.getAddons();
      emit(state.copyWith(status: AddonStatus.loaded, addons: list));
    } on AppException catch (e) {
      emit(
        state.copyWith(
          status: AddonStatus.loaded,
          errorMessage: e.message,
        ),
      );
    }
  }

  Future<void> _onAdded(
    AddonAdded event,
    Emitter<AddonState> emit,
  ) async {
    await _runMutation(
      emit,
      () => _repository.createAddon(
        name: event.name,
        price: event.price,
        stock: event.stock,
      ),
      'Add-on berhasil ditambahkan.',
    );
  }

  Future<void> _onUpdated(
    AddonUpdated event,
    Emitter<AddonState> emit,
  ) async {
    await _runMutation(
      emit,
      () => _repository.updateAddon(
        existing: event.existing,
        name: event.name,
        price: event.price,
        stock: event.stock,
      ),
      'Add-on berhasil diperbarui.',
    );
  }

  Future<void> _onDeleted(
    AddonDeleted event,
    Emitter<AddonState> emit,
  ) async {
    await _runMutation(
      emit,
      () => _repository.deleteAddon(event.id),
      'Add-on berhasil dihapus.',
    );
  }

  Future<void> _runMutation(
    Emitter<AddonState> emit,
    Future<void> Function() action,
    String successMessage,
  ) async {
    emit(state.copyWith(status: AddonStatus.submitting));
    try {
      await action();
      final list = await _repository.getAddons();
      emit(
        state.copyWith(
          status: AddonStatus.loaded,
          addons: list,
          successMessage: successMessage,
        ),
      );
    } on AppException catch (e) {
      emit(
        state.copyWith(
          status: AddonStatus.loaded,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AddonStatus.loaded,
          errorMessage: 'Terjadi kesalahan saat memproses add-on.',
        ),
      );
    }
  }
}
