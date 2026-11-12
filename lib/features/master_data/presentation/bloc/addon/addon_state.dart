part of 'addon_bloc.dart';

enum AddonStatus { initial, loading, loaded, submitting }

class AddonState extends Equatable {
  const AddonState({
    this.status = AddonStatus.initial,
    this.addons = const [],
    this.errorMessage,
    this.successMessage,
  });

  final AddonStatus status;
  final List<AddonModel> addons;
  final String? errorMessage;
  final String? successMessage;

  AddonState copyWith({
    AddonStatus? status,
    List<AddonModel>? addons,
    String? errorMessage,
    String? successMessage,
  }) {
    return AddonState(
      status: status ?? this.status,
      addons: addons ?? this.addons,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, addons, errorMessage, successMessage];
}
