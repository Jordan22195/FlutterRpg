import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/player_data_service.dart';

/// The stamina [player] ends on after [seconds] idle from [from], stepped
/// the way the frame loop recovers: [dt] at a time, at the rate that holds
/// at that instant, recovery training on every step that had room to fill.
/// So a buff lapsing, or recovery levelling and refilling faster, lands
/// where it would live.
///
/// Leaves [player] as it found it, so the settle under test starts from the
/// same place.
double idleRecovery(
  PlayerDataService pds,
  PlayerData player, {
  required DateTime from,
  required double seconds,
  double dt = 0.01,
}) {
  final recovery = player.skillData[SkillId.RECOVERY]!;
  final stamina = player.stamina;
  final xp = recovery.xp;

  final steps = (seconds / dt).round();
  for (var i = 0; i < steps; i++) {
    final at = from.add(Duration(microseconds: (i * dt * 1e6).round()));
    final rate = pds.staminaRecoveryPerSecond(player, at: at);
    final wasBelowMax = player.stamina < pds.getMaxStamina(player, at: at);
    pds.changeStamina(rate * dt, player, at: at);
    if (wasBelowMax && rate > 0) {
      pds.applyXp(player, {SkillId.RECOVERY: rate * dt});
    }
  }

  final end = player.stamina;
  player.stamina = stamina;
  recovery.xp = xp;
  return end;
}
