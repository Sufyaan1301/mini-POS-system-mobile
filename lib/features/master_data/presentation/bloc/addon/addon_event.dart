part of 'addon_bloc.dart';

sealed class AddonEvent extends Equatable {
  const AddonEvent();

  @override
  List<Object?> get props => [];
}

final class AddonsLoaded extends AddonEvent {
  const AddonsLoaded();
}

final class AddonAdded extends AddonEvent {
  const AddonAdded({
    required this.name,
    required this.price,
    required this.stock,
  });

  final String name;
  final double price;
  final int stock;

  @override
  List<Object?> get props => [name, price, stock];
}

final class AddonUpdated extends AddonEvent {
  const AddonUpdated({
    required this.existing,
    required this.name,
    required this.price,
    required this.stock,
  });

  final AddonModel existing;
  final String name;
  final double price;
  final int stock;

  @override
  List<Object?> get props => [existing, name, price, stock];
}

final class AddonDeleted extends AddonEvent {
  const AddonDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
