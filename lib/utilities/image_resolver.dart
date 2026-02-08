import 'package:flutter/material.dart';

/// Generic ImageProvider lookup for enum ids.
///
/// Register a resolver per enum type (e.g. Items, Skills), then call [resolve]
/// with any enum value to get the ImageProvider.
///
/// Example (during app init):
/// ```dart
/// EnumImageProviderLookup.register<Items>(ItemController.imageProviderFor);
/// EnumImageProviderLookup.register<Skills>(SkillController.imageProviderFor);
/// ```
///
/// Usage:
/// ```dart
/// final img = EnumImageProviderLookup.resolve(Items.copperOre);
/// ```
class EnumImageProviderLookup {
  EnumImageProviderLookup._();

  /// Backing store of resolvers keyed by enum Type.
  ///
  /// We store a dynamic function and cast on read. This keeps the public API
  /// strongly typed while supporting multiple enum types.
  static final Map<Type, dynamic> _resolvers = <Type, dynamic>{};

  /// Registers a resolver for enum type [T].
  ///
  /// Call this once during startup for each enum type you want to support.
  static void register<T extends Enum>(ImageProvider? Function(T id) resolver) {
    _resolvers[T] = resolver;
  }

  /// Unregisters a resolver for enum type [T].
  static void unregister<T extends Enum>() {
    _resolvers.remove(T);
  }

  /// Returns true if a resolver is registered for enum type [T].
  static bool isRegistered<T extends Enum>() => _resolvers.containsKey(T);

  /// Resolve an [ImageProvider] for a specific enum value [id].
  ///
  /// Returns null if no resolver is registered for that enum type or if the
  /// resolver returns null.
  static ImageProvider? resolve<T extends Enum>(T id) {
    final dynamic resolver = _resolvers[T];
    if (resolver == null) return null;

    // Safe as long as [register<T>] was used to store the resolver.
    return (resolver as ImageProvider? Function(T)).call(id);
  }

  /// Resolve an [ImageProvider] for a dynamically-typed enum value.
  ///
  /// Useful when you only have `Enum` at the call site (e.g., data-driven UI).
  /// Returns null if no resolver is registered for `id.runtimeType`.
  static ImageProvider? resolveDynamic(Enum id) {
    final dynamic resolver = _resolvers[id.runtimeType];
    if (resolver == null) return null;

    // Resolver was registered for this exact enum type.
    return (resolver as ImageProvider? Function(Enum)).call(id);
  }
}
