#!/usr/bin/env python3
"""Dart import/export edge extractor for geiger's xray.py --edges.

Replaces lakos for edge extraction: lakos 2.0.7 silently drops any
import/export directive whose show/hide clause wraps to the next line
(dart format wraps at 80 cols, so strictly-formatted repos lose edges
everywhere). The directive URI is always on the keyword's own line, so a
line regex is sufficient and wrapping-proof. Also resolves package: URIs
across a melos/workspace monorepo — cross-package edges lakos can't see.

Usage: dart_edges.py <repo_root> > edges.json   (madge-format JSON)
"""

import json
import re
import subprocess
import sys
from pathlib import Path

DIRECTIVE = re.compile(r"""^\s*(import|export)\s+['"]([^'"]+)['"]""")
# conditional imports: import 'a.dart' if (dart.library.io) 'b.dart';
CONDITIONAL = re.compile(r"""if\s*\([^)]*\)\s*['"]([^'"]+)['"]""")
LINE_COMMENT = re.compile(r"//.*")
BLOCK_COMMENT = re.compile(r"/\*.*?\*/", re.DOTALL)


def workspace_packages(root: Path) -> dict[str, Path]:
    """package name -> lib dir, for every pubspec.yaml under root."""
    pkgs = {}
    for pubspec in root.rglob("pubspec.yaml"):
        if any(p in (".dart_tool", "build") for p in pubspec.parts):
            continue
        m = re.search(r"^name:\s*(\S+)", pubspec.read_text(), re.MULTILINE)
        if m:
            pkgs[m.group(1)] = pubspec.parent / "lib"
    return pkgs


def resolve(uri: str, file: Path, pkgs: dict[str, Path], root: Path) -> str | None:
    if uri.startswith("dart:"):
        return None
    if uri.startswith("package:"):
        name, _, rest = uri[8:].partition("/")
        libdir = pkgs.get(name)
        if libdir is None:  # external dependency
            return None
        target = libdir / rest
    else:
        target = (file.parent / uri).resolve()
    try:
        return target.resolve().relative_to(root).as_posix()
    except ValueError:
        return None


def main() -> None:
    root = Path(sys.argv[1]).resolve()
    files = subprocess.run(
        ["git", "-C", str(root), "ls-files", "*.dart"],
        capture_output=True, text=True, check=True,
    ).stdout.split()
    pkgs = workspace_packages(root)
    known = set(files)
    graph: dict[str, list[str]] = {}
    for rel in files:
        path = root / rel
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        text = BLOCK_COMMENT.sub("", text)
        deps = []
        for line in text.splitlines():
            line = LINE_COMMENT.sub("", line)
            m = DIRECTIVE.match(line)
            if not m:
                continue
            uris = [m.group(2), *CONDITIONAL.findall(line)]
            for uri in uris:
                target = resolve(uri, path, pkgs, root)
                if target and target in known and target != rel:
                    deps.append(target)
        graph[rel] = sorted(set(deps))
    json.dump(graph, sys.stdout)
    print(
        f"\n{len(graph)} nodes, {sum(len(v) for v in graph.values())} edges,"
        f" {len(pkgs)} workspace packages",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
