#!/usr/bin/env python3
"""Write the pixel Wi-Fi glyphs, per signal level and with a VPN lock."""

from pathlib import Path

HERE = Path(__file__).resolve().parent

WIFI = [
    ".#######.",
    "#.......#",
    "..#####..",
    ".#.....#.",
    "...###...",
    "..#...#..",
    ".........",
    "....#....",
]
LEVEL_ROWS = {1: (7,), 2: (4, 5, 7), 3: (2, 3, 4, 5, 7), 4: tuple(range(8))}
LOCK = [".##.", "#..#", "####", "####", "####"]
LOCK_TOP, LOCK_LEFT, WIDTH_LOCKED = 3, 8, 12


def level(rows: tuple[int, ...]) -> list[str]:
    return [row if y in rows else "." * len(row) for y, row in enumerate(WIFI)]


def locked(grid: list[str]) -> list[str]:
    out = []
    for y, row in enumerate(grid):
        cells = list(row.ljust(WIDTH_LOCKED, "."))
        if y >= LOCK_TOP - 1:
            for x in range(LOCK_LEFT - 1, WIDTH_LOCKED):
                cells[x] = "."
        if y >= LOCK_TOP:
            lock = LOCK[y - LOCK_TOP]
            cells[LOCK_LEFT : LOCK_LEFT + len(lock)] = lock
        out.append("".join(cells))
    return out


def svg(grid: list[str]) -> str:
    runs = []
    for y, row in enumerate(grid):
        x = 0
        while x < len(row):
            if row[x] == "#":
                start = x
                while x < len(row) and row[x] == "#":
                    x += 1
                runs.append(f"M{start} {y}h{x - start}v1h-{x - start}z")
            else:
                x += 1
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {len(grid[0])} {len(grid)}">'
        f'<path fill="#000" d="{"".join(runs)}"/></svg>\n'
    )


def main() -> None:
    frames = {"wifi-full": WIFI} | {
        f"wifi-{n}": level(rows) for n, rows in LEVEL_ROWS.items()
    }
    for name, grid in frames.items():
        (HERE / f"{name}.svg").write_text(svg(grid))
        (HERE / f"{name}-locked.svg").write_text(svg(locked(grid)))


if __name__ == "__main__":
    main()
