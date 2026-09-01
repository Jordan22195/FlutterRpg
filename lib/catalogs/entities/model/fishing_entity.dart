import 'package:rpg/catalogs/entities/model/encounter_entity.dart';

// A fishing spot. Unlike trees/ore it never depletes and it doesn't
// fight back: the fishing action rolls against its difficulty (defence)
// for a catch and the spot stays put. That makes it a permanent feature
// of the zone rather than a resource node, so the explore screen lists
// it with the structures.
class FishingEntity extends EncounterEntity {
  FishingEntity({required super.id, super.count, super.hitpoints});
}
