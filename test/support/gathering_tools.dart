import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

/// Equips the starter gathering tools — the stone axe and pickaxe and the
/// simple rod Farmer John sells — so a fixture can chop, mine and fish.
/// Trees, ore and fishing spots refuse to be worked bare-handed; a test
/// about something else that happens to gather on the way calls this.
void equipGatheringTools(SaveGameData save) {
  final tools = save.playerData.equipmentData.equipedTools;
  tools[SkillId.WOODCUTTING] = EquipmentItem(id: ItemId.STONE_AXE);
  tools[SkillId.MINING] = EquipmentItem(id: ItemId.STONE_PICKAXE);
  tools[SkillId.FISHING] = EquipmentItem(id: ItemId.SIMPLE_FISHING_ROD);
}

/// [save] with [equipGatheringTools] applied, for building a session
/// inline.
SaveGameData withGatheringTools(SaveGameData save) {
  equipGatheringTools(save);
  return save;
}
