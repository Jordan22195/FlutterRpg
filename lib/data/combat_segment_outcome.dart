/// What the enemy's side of a fight came to over one stretch of time.
///
/// Produced by [EncounterService.resolveIncomingDamage], which walks the
/// stretch swing by swing rather than averaging it: the mean says a fight is
/// survivable long after a single unlucky roll has ended it.
class CombatSegmentOutcome {
  /// Enemy swings actually resolved. Short of the window's worth only when
  /// the player died partway.
  final int swings;

  /// Seconds the swings covered - the whole window when the player lived.
  final double elapsed;

  /// The player's hp at the end. Zero when they died.
  final int hitpoints;

  /// Food the auto-eater got through.
  final int foodEaten;

  /// Swings that missed. Nothing is paid for them - defence trains from
  /// damage dealt in the defensive stance - but the walk counts them for
  /// free and they are the clearest read on how a fight actually went.
  final int blocks;

  final bool died;

  const CombatSegmentOutcome({
    required this.swings,
    required this.elapsed,
    required this.hitpoints,
    required this.foodEaten,
    required this.blocks,
    required this.died,
  });
}
