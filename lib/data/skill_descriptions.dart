import 'skill_data.dart';

const Map<SkillId, String> kSkillDescriptions = {
  SkillId.STAMINA:
      'Determines your maximum stamina. Each point of stamina spent while acting grants xp.',
  SkillId.SPEED:
      'Raises your top action speed, reducing the minimum time between actions. Trains from acting near your top speed.',
  SkillId.RECOVERY:
      'Governs how quickly stamina refills over time. Trains passively while stamina is being restored.',
  SkillId.EXPLORATION:
      'Reflects your familiarity with the world. Trains from discovering and traveling to new zones.',
  SkillId.HITPOINTS:
      'Determines your maximum health. Trains from taking damage in combat.',
  SkillId.ATTACK:
      'Governs melee accuracy and damage. Trains from landing melee hits in combat.',
  SkillId.RANGED:
      'Governs ranged weapon accuracy and damage. Trains from landing ranged hits in combat.',
  SkillId.MAGIC: 'Governs spell accuracy and damage. Trains from casting spells in combat.',
  SkillId.DEFENCE:
      'Reduces the damage you take. Trains from surviving hits in combat.',
  SkillId.WOODCUTTING:
      'Lets you fell trees for logs. Trains from chopping trees out in the world.',
  SkillId.MINING:
      'Lets you mine rock for ore and gems. Trains from working mineral deposits.',
  SkillId.FISHING:
      'Lets you catch fish for cooking. Trains from fishing at water sources.',
  SkillId.HERBALISM:
      'Lets you gather herbs for alchemy. Trains from picking herb nodes; higher levels unlock rarer herbs and better yields.',
  SkillId.FIREMAKING:
      'Lets you build fires for cooking and buffs, without needing a crafting station. Trains from lighting fires.',
  SkillId.LEATHERWORKING:
      'Lets you craft leather armor for ranged combat at a leatherworking station. Trains from crafting leather gear.',
  SkillId.BLACKSMITHING:
      'Lets you smelt ore and forge metal armor and weapons for melee combat at a blacksmith station. Trains from smithing.',
  SkillId.TAILORING:
      'Lets you weave cloth armor for magic combat at a loom. Trains from crafting cloth gear.',
  SkillId.ENCHANTING:
      'Lets you enhance gear with magical properties at an enchanting station, using gear and enchantment materials. Trains from enchanting.',
  SkillId.JEWELCRAFTING:
      'Lets you craft jewelry at a jewelcrafting station, using gems and metal bars. Trains from crafting jewelry.',
  SkillId.FLETCHING:
      'Lets you craft ranged weapons and staves at a fletching station, using logs. Trains from fletching.',
  SkillId.COOKING:
      'Lets you cook food for healing and buffs at a fire. Trains from cooking.',
  SkillId.ALCHEMY:
      'Lets you brew potions for buffs and healing at an alchemy station, using herbs and water. Trains from brewing potions.',
};
