import 'package:flutter/material.dart';

/// A page route with solid ground under it.
///
/// The shell owns the only Scaffold in the app — a tab screen is a bare
/// column pushed onto that tab's nested navigator, so nothing inside a
/// pushed route paints a background of its own. A [MaterialPageRoute] is
/// opaque as a *route* but transparent as a *picture*: for the length of a
/// push or a pop both screens are on screen at once, and with no canvas
/// between them the one sliding out is read straight through the one sliding
/// in. It only shows during the transition, which is exactly when the eye is
/// following the movement.
///
/// So the page gets the ground the missing Scaffold would have given it —
/// [ThemeData.scaffoldBackgroundColor], the same colour the shell's own
/// Scaffold is painting underneath, so the seam is invisible once the
/// animation settles.
///
/// A colour and nothing else. A real Scaffold here would nest a second one
/// inside the shell's, with its own app bar slot, its own bottom inset and
/// its own idea of where the safe area is.
///
/// Every route pushed onto a tab navigator should be one of these, including
/// the ones whose screen does carry a Scaffold — painting the same colour
/// twice costs a rectangle, and the rule is worth more than the rectangle.
class ShellPageRoute<T> extends MaterialPageRoute<T> {
  ShellPageRoute({required super.builder, super.settings});

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: super.buildPage(context, animation, secondaryAnimation),
    );
  }
}
