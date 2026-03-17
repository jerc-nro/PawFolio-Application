import 'package:flutter_riverpod/flutter_riverpod.dart';

final recordsTypeFilterProvider = StateProvider<String>((ref) => 'ALL');

final recordsBreedFilterProvider = StateProvider<String>((ref) => 'ALL');

final recordsSexFilterProvider = StateProvider<String>((ref) => 'ALL');

final recordsSterilizedFilterProvider = StateProvider<bool?>((ref) => null);