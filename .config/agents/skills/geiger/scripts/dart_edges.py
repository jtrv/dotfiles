#!/usr/bin/env python3
"""Dart file dependency graph for geiger's xray.py --edges (madge JSON).

One batched ast-grep run selects URI syntax nodes under import_or_export
and part_directive, plus ERROR nodes for failure reporting. Conditional URIs
are included conservatively (all possible runtime branches). Parts remain
file nodes with an edge from the owning library to each part; part-of is not
an import back to the owner. No whole-file regex import fallback is used.
Requires ast-grep with Dart and ESQuery kind selectors (tested with 0.45.1).

Usage: dart_edges.py <repo_root> > edges.json
       dart_edges.py --self-test
Coverage is printed to stderr; failed files and their edges are omitted.
"""

import argparse
import ast
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def tracked_files(root: Path) -> list[str]:
    return subprocess.run(
        ["git", "-C", str(root), "ls-files", "-z"],
        capture_output=True, check=True,
    ).stdout.decode("utf-8", "surrogateescape").rstrip("\0").split("\0")


def workspace_packages(root: Path, files: list[str] | None = None) -> dict[str, Path]:
    """Resolve tracked workspace manifests, including quoted YAML names."""
    pkgs = {}
    for rel in files if files is not None else tracked_files(root):
        pubspec = root / rel
        if pubspec.name != "pubspec.yaml":
            continue
        match = re.search(r"^name:\s*(['\"]?)([\w]+)\1\s*(?:#.*)?$",
                          pubspec.read_text(), re.MULTILINE)
        if match:
            name = match.group(2)
            if name in pkgs:
                raise ValueError(f"duplicate workspace package name: {name}")
            pkgs[name] = pubspec.parent / "lib"
    return pkgs


def resolve(uri: str, file: Path, pkgs: dict[str, Path], root: Path) -> str | None:
    if uri.startswith("dart:"):
        return None
    if uri.startswith("package:"):
        name, _, rest = uri[8:].partition("/")
        libdir = pkgs.get(name)
        if libdir is None:
            return None
        target = libdir / rest
    elif ":" in uri:
        return None
    else:
        target = file.parent / uri
    try:
        return target.resolve().relative_to(root).as_posix()
    except ValueError:
        return None


def extract(root: Path) -> tuple[dict[str, list[str]], dict[str, int]]:
    if not shutil.which("ast-grep"):
        raise RuntimeError("ast-grep is required for Dart extraction; install ast-grep with Dart support")
    tracked = tracked_files(root)
    files = sorted(f for f in tracked if f.endswith(".dart"))
    pkgs = workspace_packages(root, tracked)
    graph = {f: set() for f in files}
    failed = {f for f in files if not (root / f).is_file()}
    paths = [str(root / f) for f in files if f not in failed]
    if paths:
        result = subprocess.run(
            ["ast-grep", "run", "--lang", "dart", "--kind",
             "import_or_export uri, part_directive uri, ERROR", "--json=compact", *paths],
            capture_output=True, text=True, check=False,
        )
        if result.returncode not in (0, 1):
            raise RuntimeError(f"ast-grep failed: {result.stderr.strip()}")
        if result.stderr.strip():
            raise RuntimeError(f"ast-grep reported incomplete extraction: {result.stderr.strip()}")
        for match in json.loads(result.stdout):
            rel = Path(match["file"]).relative_to(root).as_posix()
            parents = match.get("metaVariables", {}).get("multi", {}).get("secondary", [])
            if not parents:  # ERROR selector; URI selectors carry their ancestor
                failed.add(rel)
                continue
            literal = match["text"]
            if not literal.startswith(("r'", 'r"')):
                literal = re.sub(r"\\u\{([0-9a-fA-F]+)\}",
                                 lambda m: "\\U" + m.group(1).zfill(8), literal)
            try:
                uri = ast.literal_eval(literal)
            except (SyntaxError, ValueError):
                failed.add(rel)
                continue
            target = resolve(uri, root / rel, pkgs, root)
            if target in graph:
                graph[rel].add(target)
    return ({f: sorted(deps - failed) for f, deps in graph.items() if f not in failed},
            {"discovered": len(files), "parsed": len(files) - len(failed), "failed": len(failed)})


def self_test() -> None:
    if not shutil.which("ast-grep"):
        print("self-test SKIPPED: ast-grep is absent")
        return
    from unittest.mock import patch

    with patch.object(shutil, "which", return_value=None):
        try:
            extract(Path("."))
        except RuntimeError as exc:
            assert "ast-grep is required" in str(exc)
        else:
            raise AssertionError("missing ast-grep was not rejected")
    with tempfile.TemporaryDirectory(prefix="dart-test-", dir=Path(__file__).resolve().parent.parent) as td:
        root = Path(td)
        subprocess.run(["git", "-c", "core.fsmonitor=false", "init", "-q", str(root)], check=True)
        (root / "lib").mkdir()
        (root / "pubspec.yaml").write_text('name: "app"\n')
        for name in ("b.dart", "c.dart", "d.dart", "space name.dart", "tab\tname.dart", "p.dart", "fake.dart"):
            (root / "lib" / name).write_text("// fixture\n")
        (root / "lib" / "a.dart").write_text(
            "import\n 'b.dart'; import 'c.dart'\n"
            " if (dart.library.io == 'true') 'd.dart';\n"
            "export 'package:app/space name.dart';\n"
            "import 'tab\\tname.dart'; part 'p.dart';\n"
            "/* outer /* import 'fake.dart'; */ comment */\n"
            'final text = """\nimport \'fake.dart\';\n""";\n')
        (root / "lib" / "p.dart").write_text("part of 'a.dart';\n")
        subprocess.run(["git", "-c", "core.fsmonitor=false", "-C", str(root), "add", "."], check=True)
        graph, counts = extract(root)
        assert graph["lib/a.dart"] == sorted("lib/" + f for f in (
            "b.dart", "c.dart", "d.dart", "space name.dart", "tab\tname.dart", "p.dart")), graph
        assert graph["lib/p.dart"] == []
        assert counts == {"discovered": 8, "parsed": 8, "failed": 0}, counts
        (root / "lib" / "b.dart").write_text("import 'oops.dart' if ( ;")
        graph, counts = extract(root)
        assert counts["failed"] == 1 and "lib/b.dart" not in graph, (graph, counts)
        assert "lib/b.dart" not in graph["lib/a.dart"]
    print("self-test OK")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", nargs="?", default=".")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    try:
        graph, coverage = extract(Path(args.repo).resolve())
    except (RuntimeError, ValueError, OSError, subprocess.CalledProcessError) as exc:
        parser.exit(1, f"dart_edges: {exc}\n")
    json.dump(graph, sys.stdout)
    print(f"\nDart coverage: {json.dumps(coverage)}; "
          f"{sum(map(len, graph.values()))} edges", file=sys.stderr)


if __name__ == "__main__":
    main()
