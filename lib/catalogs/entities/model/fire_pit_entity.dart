import 'package:rpg/catalogs/entities/model/crafting_entity.dart';

/// A firepit. Carries no state of its own: what is burning in it, and for how
/// long, is the zone buff keyed to this entity id in [BuffData]. Keeping it
/// stateless is deliberate — firepits are permanent entities, and permanent
/// entities are rebuilt from the catalog on every load, so anything stored
/// here would be lost.
class FirePitEntity extends CraftingEntity {
  FirePitEntity({required super.id});
}
