"""Combat curve tuning: max hit and hit chance vs attack/defense.

The defaults are the curve the game ships -- EncounterService.chanceToHit and
computeMaxHit in lib/services/encounter_service.dart mirror them, so a bare run
plots live combat. Change them together.

    python3 tools/damage_calc.py                 # plot (matplotlib if present, else terminal)
    python3 tools/damage_calc.py --ascii         # force terminal plots
    python3 tools/damage_calc.py --save out.png  # write a PNG instead of showing a window
    python3 tools/damage_calc.py --table         # the old numeric sweeps
    python3 tools/damage_calc.py --n-max-hit 0.8 --k-hit-chance 3 --defenses 10,50,200
    python3 tools/damage_calc.py --model ratio   # the scale-free alternative
    python3 tools/damage_calc.py --footing 0     # the un-smoothed hit chance
"""

import argparse
import sys


def effective_attack(attack: float, defense: float, k: float, bite: float = 1.0) -> float:
    """"excess" model: defense-adjusted attack. Slope halves once attack passes defense.

    ``s = k / (k + defense)`` scales the whole attack, and the part above the
    target's defense is scaled by ``s`` a second time -- that is the soft cap.

    ``bite`` (0..1) weakens the first scaling to ``s**bite``, which pulls the
    below-parity curve toward the uncapped ``attack**n`` line. It is a trap:
    any value below 1 makes max hit NON-MONOTONE in defense (see --model ratio).
    """
    s = k / (k + defense)
    lead = s ** bite
    return lead * min(attack, defense) + lead * s * max(0.0, attack - defense)


def effective_attack_ratio(attack: float, defense: float, retain: float,
                           knee: float) -> float:
    """"ratio" model: same shape, but defense is measured against attack.

    ``s = 1 / (1 + (defense/attack)**knee / c)``, with ``c`` chosen so that at
    parity ``s == retain``. Because ``s`` depends on the *ratio*, the curve sits
    the same distance below uncapped at every stat level -- retain=0.9 means
    "90% of an undefended hit against an equal-defense target" whether that is
    attack 20 or attack 200 -- and max hit stays monotone in defense.
    """
    c = retain / (1.0 - retain)
    s = 1.0 / (1.0 + (defense / attack) ** knee / c)
    return s * min(attack, defense) + s * s * max(0.0, attack - defense)


def calc_max_hit(attack: float, defense: float, k: float, n: float,
                 bite: float = 1.0) -> float:
    """Max hit = A^n when defense is 0, reduced and soft-capped otherwise."""
    return effective_attack(attack, defense, k, bite) ** n


def make_max_hit(args):
    """The max-hit function the selected model describes: f(attack, defense)."""
    n = args.n_max_hit
    if args.model == "ratio":
        retain, knee = args.parity_retain, args.knee
        return lambda a, d: effective_attack_ratio(a, d, retain, knee) ** n
    k, bite = args.k_max_hit, args.bite
    return lambda a, d: effective_attack(a, d, k, bite) ** n


def calc_hit_chance(attack: float, defense: float, k_hit: float,
                    footing: float = 0.0) -> float:
    """90% at parity, asymptotic to 100%.

    Both stats are read against ``footing`` before their ratio is taken. Adding
    the same value to both sides leaves parity at 90% exactly, but compresses
    the small-integer region, where a bare ratio is violent: at attack 1 one
    extra point is worth up to 16x the hit chance at footing 0, and ~1.5x at
    footing 8.
    """
    return 1.0 / (1.0 + ((defense + footing) / (attack + footing)) ** k_hit / 9.0)


# Categorical series colors, assigned in fixed order (never cycled).
SERIES_COLORS = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4"]
SERIES_MARKS = ["#", "*", "+", "o", "x"]
GRID = "#d8d7d2"
INK = "#0b0b0b"
INK_MUTED = "#52514e"


def frange(start: float, stop: float, step: float):
    xs, x = [], float(start)
    while x <= stop + 1e-9:
        xs.append(x)
        x += step
    return xs


# ---------------------------------------------------------------- series build

def build_panels(args):
    """Four panels: (title, xlabel, ylabel, is_percent, series, reference lines).

    Each series is (label, xs, ys). A reference line is (label, xs, ys) drawn
    dashed in the same slot color -- the unmodified A^n ceiling.
    """
    atk_xs = frange(args.min_attack, args.max_attack, args.attack_step)
    def_xs = frange(args.min_defense, args.max_defense, args.defense_step)
    n, kh, ft = args.n_max_hit, args.k_hit_chance, args.footing
    max_hit = make_max_hit(args)

    hit_vs_atk, max_vs_atk, ceil_vs_atk = [], [], []
    for d in args.defenses:
        label = f"def {d:g}"
        hit_vs_atk.append((label, atk_xs, [calc_hit_chance(a, d, kh, ft) for a in atk_xs]))
        max_vs_atk.append((label, atk_xs, [max_hit(a, d) for a in atk_xs]))
    ceil_vs_atk.append(("uncapped a^n", atk_xs, [a ** n for a in atk_xs]))

    hit_vs_def, max_vs_def, ceil_vs_def = [], [], []
    for a in args.attacks:
        label = f"att {a:g}"
        hit_vs_def.append((label, def_xs, [calc_hit_chance(a, d, kh, ft) for d in def_xs]))
        max_vs_def.append((label, def_xs, [max_hit(a, d) for d in def_xs]))
        ceil_vs_def.append((None, def_xs, [a ** n] * len(def_xs)))

    return [
        ("Hit chance vs attack", "attack", "hit chance", True, hit_vs_atk, []),
        ("Max hit vs attack", "attack", "max hit", False, max_vs_atk, ceil_vs_atk),
        ("Hit chance vs defense", "defense", "hit chance", True, hit_vs_def, []),
        ("Max hit vs defense", "defense", "max hit", False, max_vs_def, ceil_vs_def),
    ]


def subtitle(args):
    shape = (f"parityRetain={args.parity_retain:g}  knee={args.knee:g}"
             if args.model == "ratio"
             else f"k_maxHit={args.k_max_hit:g}  bite={args.bite:g}")
    return (f"model={args.model}  {shape}  n_maxHit={args.n_max_hit:g}  "
            f"k_hitChance={args.k_hit_chance:g}  footing={args.footing:g}")


# ------------------------------------------------------------------ matplotlib

def decollide(ends, ymin: float, ymax: float, gap_frac: float = 0.055):
    """Spread label anchors so none sit closer than gap_frac of the y range."""
    gap = (ymax - ymin) * gap_frac
    ordered = sorted(ends, key=lambda e: e[0])
    out, prev = [], None
    for y, label, color in ordered:
        y = min(max(y, ymin), ymax)
        if prev is not None and y - prev < gap:
            y = prev + gap
        prev = y
        out.append((y, label, color))
    overshoot = out[-1][0] - ymax if out and out[-1][0] > ymax else 0.0
    return [(y - overshoot, label, color) for y, label, color in out]


def plot_matplotlib(panels, args) -> None:
    import matplotlib
    if args.save:
        matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.ticker import PercentFormatter

    fig, axes = plt.subplots(2, 2, figsize=(13, 8.5))
    fig.suptitle("Combat curves", fontsize=14, color=INK, x=0.02, ha="left")
    fig.text(0.02, 0.945, subtitle(args), fontsize=9, color=INK_MUTED, ha="left")

    for ax, (title, xlabel, ylabel, is_pct, series, refs) in zip(axes.flat, panels):
        ends = []
        for i, (label, xs, ys) in enumerate(series):
            color = SERIES_COLORS[i % len(SERIES_COLORS)]
            ax.plot(xs, ys, lw=2, color=color, label=label, solid_capstyle="round")
            ends.append((ys[-1], label, color))
        for i, (label, xs, ys) in enumerate(refs):
            color = INK_MUTED if label else SERIES_COLORS[i % len(SERIES_COLORS)]
            ax.plot(xs, ys, lw=1.2, ls=(0, (4, 3)), color=color, alpha=0.55,
                    label=label, zorder=1)

        ax.set_title(title, fontsize=11, color=INK, loc="left", pad=8)
        ax.set_xlabel(xlabel, fontsize=9, color=INK_MUTED)
        ax.set_ylabel(ylabel, fontsize=9, color=INK_MUTED)
        ax.grid(True, color=GRID, lw=0.8, alpha=0.8)
        ax.set_axisbelow(True)
        for side in ("top", "right"):
            ax.spines[side].set_visible(False)
        for side in ("left", "bottom"):
            ax.spines[side].set_color(GRID)
        ax.tick_params(colors=INK_MUTED, labelsize=8, length=0)
        ax.margins(x=0.12)
        if is_pct:
            ax.yaxis.set_major_formatter(PercentFormatter(xmax=1))
            ax.set_ylim(0, 1.02)
        else:
            ax.set_ylim(bottom=0)

        # Direct labels at the right edge, nudged apart so curves that converge
        # (every hit-chance line at 100%) don't stack their labels on top of
        # each other. Reserve the margin they sit in.
        x0, x1 = ax.get_xlim()
        span = x1 - x0
        ticks = [t for t in ax.get_xticks() if x0 <= t <= x1]
        ax.set_xlim(x0, x1 + 0.20 * span)
        ax.set_xticks(ticks)  # the reserved margin is label space, not data range
        for y, label, color in decollide(ends, *ax.get_ylim()):
            ax.annotate(label, (x1 + 0.03 * span, y), va="center", fontsize=8,
                        color=color, annotation_clip=False)

        ax.legend(fontsize=8, frameon=False, loc="best", labelcolor=INK_MUTED)

    fig.tight_layout(rect=(0, 0, 1, 0.93))
    if args.save:
        fig.savefig(args.save, dpi=140)
        print(f"wrote {args.save}")
    else:
        plt.show()


# ----------------------------------------------------------------- ascii plots

def plot_ascii(panels, args, width: int = 74, height: int = 18) -> None:
    print(f"Combat curves  ({subtitle(args)})")
    for title, xlabel, ylabel, is_pct, series, refs in panels:
        drawn = series + [(lbl, xs, ys) for lbl, xs, ys in refs if lbl]
        xmin = min(min(xs) for _, xs, _ in drawn)
        xmax = max(max(xs) for _, xs, _ in drawn)
        ymin = 0.0
        ymax = max(max(ys) for _, _, ys in drawn) or 1.0

        grid = [[" "] * width for _ in range(height)]
        for i, (_, xs, ys) in enumerate(drawn):
            mark = SERIES_MARKS[i % len(SERIES_MARKS)] if i < len(series) else "."
            for x, y in zip(xs, ys):
                col = int(round((x - xmin) / (xmax - xmin or 1) * (width - 1)))
                row = height - 1 - int(round((y - ymin) / (ymax - ymin or 1) * (height - 1)))
                grid[max(0, min(height - 1, row))][max(0, min(width - 1, col))] = mark

        def fmt_y(v: float) -> str:
            return f"{v:.0%}" if is_pct else f"{v:.0f}"

        print(f"\n  {title}   [y: {ylabel}, x: {xlabel}]")
        for r, row in enumerate(grid):
            tick = ""
            if r == 0:
                tick = fmt_y(ymax)
            elif r == height - 1:
                tick = fmt_y(ymin)
            elif r == height // 2:
                tick = fmt_y((ymax + ymin) / 2)
            print(f"  {tick:>6} |{''.join(row)}")
        print("  " + " " * 6 + " +" + "-" * width)
        left, right = f"{xmin:g}", f"{xmax:g}"
        print("  " + " " * 8 + left + " " * max(1, width - len(left) - len(right)) + right)
        legend = "  ".join(
            f"{SERIES_MARKS[i % len(SERIES_MARKS)]} {lbl}" for i, (lbl, _, _) in enumerate(series))
        if any(lbl for lbl, _, _ in refs):
            legend += "  . " + next(lbl for lbl, _, _ in refs if lbl)
        print(f"  {' ' * 6}  {legend}")


# ----------------------------------------------------------------------- table

def print_tables(args) -> None:
    n, kh, ft = args.n_max_hit, args.k_hit_chance, args.footing
    max_hit = make_max_hit(args)
    for label, defense, attack, sweep in (
        ("attack sweep", args.defenses[len(args.defenses) // 2], None,
         frange(args.min_attack, args.max_attack, args.attack_step)),
        ("defense sweep", None, args.attacks[len(args.attacks) // 2],
         frange(args.min_defense, args.max_defense, args.defense_step)),
    ):
        print(f"----- {label} -----")
        for v in sweep:
            a = attack if attack is not None else v
            d = defense if defense is not None else v
            print(f"att:{a:g} def:{d:g} hit%:{calc_hit_chance(a, d, kh):.1%} "
                  f"maxHit:{max_hit(a, d):.0f} unmodMaxHit:{a ** n:.0f}")


# ------------------------------------------------------------------------ main

def csv_floats(text: str):
    return [float(v) for v in text.split(",") if v.strip()]


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--k-max-hit", type=float, default=75)
    p.add_argument("--n-max-hit", type=float, default=0.75)
    p.add_argument("--k-hit-chance", type=float, default=4)
    p.add_argument("--footing", type=float, default=8,
                   help="added to both attack and defense before their ratio is "
                        "taken, which smooths the low-stat end without moving "
                        "parity. 0 is the bare ratio, and is very swingy early.")
    p.add_argument("--model", choices=("excess", "ratio"), default="excess",
                   help="ratio: defense scaled against attack, hugs uncapped below "
                        "parity at every stat level (default). excess: the k/(k+def) "
                        "form the Dart code uses today.")
    p.add_argument("--parity-retain", type=float, default=0.9, metavar="0..1",
                   help="ratio model: share of an undefended hit kept against an "
                        "equal-defense target (default 0.9)")
    p.add_argument("--knee", type=float, default=2,
                   help="ratio model: how sharply the curve turns down past parity")
    p.add_argument("--bite", type=float, default=1.0, metavar="0..1",
                   help="excess model: how much of the defense reduction applies below "
                        "parity. Below 1 pulls the curve toward uncapped but makes max "
                        "hit non-monotone in defense -- prefer --model ratio.")
    p.add_argument("--defenses", type=csv_floats, default=[1, 10, 50, 100, 200],
                   help="defense values to draw a curve for (default 10,50,100,200)")
    p.add_argument("--attacks", type=csv_floats, default=[1, 10, 50, 100, 200],
                   help="attack values to draw a curve for (default 10,50,100,200)")
    p.add_argument("--min-attack", type=float, default=1)
    p.add_argument("--max-attack", type=float, default=150)
    p.add_argument("--attack-step", type=float, default=2)
    p.add_argument("--min-defense", type=float, default=0)
    p.add_argument("--max-defense", type=float, default=400)
    p.add_argument("--defense-step", type=float, default=5)
    p.add_argument("--table", action="store_true", help="print numeric sweeps instead of plotting")
    p.add_argument("--ascii", action="store_true", help="force terminal plots")
    p.add_argument("--save", metavar="PNG", help="write the figure to a PNG (needs matplotlib)")
    args = p.parse_args(argv)

    if args.min_attack <= 0:
        args.min_attack = 1  # hit chance divides by attack

    if args.table:
        print_tables(args)
        return 0

    panels = build_panels(args)
    if not args.ascii:
        try:
            plot_matplotlib(panels, args)
            return 0
        except ImportError:
            if args.save:
                print("--save needs matplotlib: pip install -r tools/requirements.txt",
                      file=sys.stderr)
                return 1
            print("matplotlib not installed (pip install -r tools/requirements.txt); "
                  "falling back to terminal plots\n", file=sys.stderr)
    plot_ascii(panels, args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
