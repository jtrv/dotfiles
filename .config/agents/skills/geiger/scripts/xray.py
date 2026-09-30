#!/usr/bin/env python3
"""geiger: compute an architecture digest (graph metrics + git temporal signals).

Stdlib only. Input: a module dependency graph, either extracted natively
(python via ast) or fed in from an external tool (madge/lakos/depcruise/DOT)
via --edges.

Output: compact JSON digest, top-N capped, designed to fit in LLM context.
Deterministic detection lives here; judgment (intentional vs erosion) is the
caller's job. --baseline gives a shrink-only ratchet; --changed scopes the
digest to a PR's blast radius.
"""
import argparse
import ast
import hashlib
import json
import math
import os
import re
import subprocess
import sys
import time
from collections import Counter, defaultdict
from itertools import pairwise
from pathlib import Path

# ---------------------------------------------------------------- extraction

CODE_EXTS = {".py", ".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs", ".dart",
             ".rs", ".go", ".java", ".kt", ".rb", ".php", ".cs", ".swift"}

# Tests inflate fan_in and dominate churn; generated files dominate hotspots.
# Excluded by default from graph AND git signals (--include-tests disables).
TEST_GEN_RE = re.compile(
    r"(^|/)(tests?|__tests__|spec|specs|__generated__|generated|testdata)/"
    r"|(^|/)test_[^/]*\.py$|_test\.|\.test\.|\.spec\.|_spec\.|Test\.java|Tests?\.cs"
    r"|\.g\.dart|\.freezed\.dart|_pb2\.py|\.pb\.go|_generated\.|\.min\.js")

BOT_AUTHOR_RE = re.compile(r"\[bot\]|dependabot|renovate|github-actions", re.IGNORECASE)

# Barrel facades have max fan_in + re-export instability by design; as the
# "stable" side of an SDP check they're pure noise (measured: 43/60 findings
# on sqlalchemy were __init__.py artifacts).
BARREL_RE = re.compile(r"(^|/)(__init__\.py|index\.(jsx?|tsx?|mjs|cjs))$")


def is_excluded(path, include_tests):
    return not include_tests and TEST_GEN_RE.search(path)


def list_files(repo, include_tests=False, code_only=True):
    try:
        out = subprocess.run(["git", "-c", "core.quotepath=off", "-C", repo, "ls-files", "-z"],
                             capture_output=True, check=True).stdout.decode("utf-8", "surrogateescape").split("\0")
    except (subprocess.CalledProcessError, FileNotFoundError):
        out = []
        for root, dirs, files in os.walk(repo):
            dirs[:] = [d for d in dirs if d not in
                       {".git", "node_modules", "build", "dist", "target", ".dart_tool", "__pycache__", "venv", ".venv"}]
            for f in files:
                out.append(os.path.relpath(os.path.join(root, f), repo))
    return [f for f in out if f and (not code_only or os.path.splitext(f)[1] in CODE_EXTS)
            and not is_excluded(f, include_tests)]


def _runtime_nodes(tree):
    """Walk the AST skipping `if TYPE_CHECKING:` bodies — type-only imports
    aren't runtime edges (they fabricate SDP violations and inflate cycles;
    confirmed on flask and click). Returns (nodes, skipped_import_count)."""
    modules, flags, shadowed = set(), set(), set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                name = alias.asname or alias.name.split(".")[0]
                if alias.name == "typing":
                    modules.add(name)
                else:
                    shadowed.add(name)
        elif isinstance(node, ast.ImportFrom):
            for alias in node.names:
                name = alias.asname or alias.name
                if node.module == "typing" and alias.name == "TYPE_CHECKING" and not node.level:
                    flags.add(name)
                else:
                    shadowed.add(name)
        elif isinstance(node, ast.Name) and isinstance(node.ctx, (ast.Store, ast.Del)):
            shadowed.add(node.id)
        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            shadowed.add(node.name)
        elif isinstance(node, ast.arg):
            shadowed.add(node.arg)
    modules -= shadowed
    flags -= shadowed

    def runtime_value(node):
        if isinstance(node, ast.Name) and node.id in flags:
            return False
        if (isinstance(node, ast.Attribute) and node.attr == "TYPE_CHECKING"
                and isinstance(node.value, ast.Name) and node.value.id in modules):
            return False
        if isinstance(node, ast.Constant) and isinstance(node.value, bool):
            return node.value
        if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.Not):
            value = runtime_value(node.operand)
            return None if value is None else not value
        if isinstance(node, ast.BoolOp):
            values = [runtime_value(value) for value in node.values]
            if isinstance(node.op, ast.And):
                return False if False in values else (True if all(v is True for v in values) else None)
            return True if True in values else (False if all(v is False for v in values) else None)
        return None

    nodes, skipped, stack = [], 0, [tree]
    while stack:
        node = stack.pop()
        nodes.append(node)
        for child in ast.iter_child_nodes(node):
            if isinstance(child, ast.If):
                value = runtime_value(child.test)
                if value is not None:
                    omitted = child.body if value is False else child.orelse
                    skipped += sum(1 for stmt in omitted for n in ast.walk(stmt)
                                   if isinstance(n, (ast.Import, ast.ImportFrom)))
                    stack.extend(child.orelse if value is False else child.body)
                    continue
            stack.append(child)
    return nodes, skipped


def extract_python(repo, files):
    """Resolve imports from the repository root and explicit src/ roots.
    Package directories are never themselves implicit source roots. Ambiguous
    module identities are dropped. Importing a module also executes each of
    its parent package initializers. Failed files are omitted from the graph.
    """
    pyfiles = sorted(f for f in files if f.endswith(".py"))
    roots = {""}
    for f in pyfiles:
        parts = f.split("/")
        for i, part in enumerate(parts[:-1]):
            if part == "src":
                roots.add("/".join(parts[:i + 1]) + "/")
    owners = defaultdict(set)
    identities, source_roots = {}, {}
    root_owners = defaultdict(lambda: defaultdict(set))
    for f in pyfiles:
        root = max((r for r in roots if f.startswith(r)), key=len)
        dotted = f[len(root):-3].replace("/", ".")
        dotted = dotted.removesuffix(".__init__")
        identities[f], source_roots[f] = dotted, root
        for candidate_root in roots:
            if f.startswith(candidate_root):
                candidate = f[len(candidate_root):-3].replace("/", ".").removesuffix(".__init__")
                owners[candidate].add(f)
                root_owners[candidate_root][candidate].add(f)
    mod_map = {k: next(iter(v)) for k, v in owners.items() if len(v) == 1}
    root_maps = {root: {k: next(iter(v)) for k, v in names.items() if len(v) == 1}
                 for root, names in root_owners.items()}
    edges, failed, parsed = defaultdict(set), set(), set()
    extract_python.type_only = 0
    for f in pyfiles:
        try:
            with open(os.path.join(repo, f), encoding="utf-8") as stream:
                tree = ast.parse(stream.read())
        except (SyntaxError, ValueError, OSError, UnicodeError):
            failed.add(f)
            continue
        parsed.add(f)
        pkg_parts = identities[f].split(".")
        if not f.endswith("/__init__.py"):
            pkg_parts = pkg_parts[:-1]
        rt_nodes, skipped = _runtime_nodes(tree)
        extract_python.type_only += skipped
        for node in rt_nodes:
            names = []
            lookup = mod_map
            if isinstance(node, ast.Import):
                names = [a.name for a in node.names]
            elif isinstance(node, ast.ImportFrom):
                if node.level:
                    lookup = root_maps[source_roots[f]]
                    if node.level > len(pkg_parts):
                        continue
                    base = pkg_parts[:len(pkg_parts) - node.level + 1]
                    mod = ".".join(base + (node.module.split(".") if node.module else []))
                    names = [mod] + [mod + "." + a.name for a in node.names]
                elif node.module:
                    names = [node.module] + [node.module + "." + a.name for a in node.names]
            for name in names:
                parts = name.split(".")
                for i in range(1, len(parts) + 1):
                    tgt = lookup.get(".".join(parts[:i]))
                    if tgt and tgt != f and (i == len(parts) or tgt.endswith("/__init__.py")):
                        edges[f].add(tgt)
    extract_python.coverage = {"discovered": len(pyfiles), "parsed": len(parsed),
                               "failed": len(failed)}
    return {f: sorted(edges[f] - failed) for f in sorted(parsed)}


extract_python.type_only = 0  # reset by run(); accumulated per extraction


def parse_dot(text):
    """Parse a flat directed DOT graph (IDs, chains, attributes, isolates).
    Subgraphs, ports and HTML IDs are rejected rather than partially parsed.
    """
    token_re = re.compile(r'\s+|//[^\n]*|/\*.*?\*/|\#[^\n]*|"(?:\\.|[^"\\])*"|->|[{}\[\];,=]|[A-Za-z_\x80-\uffff][\w\x80-\uffff]*|-?(?:\d+(?:\.\d*)?|\.\d+)', re.DOTALL)
    tokens, pos = [], 0
    for match in token_re.finditer(text):
        if match.start() != pos:
            raise ValueError("unsupported DOT syntax; use flat directed DOT or JSON")
        pos = match.end()
        token = match.group()
        if token.isspace() or token.startswith(("//", "/*", "#")):
            continue
        tokens.append(token)
    if pos != len(text):
        raise ValueError("unsupported DOT syntax")
    index = 0

    def take():
        nonlocal index
        if index >= len(tokens):
            raise ValueError("incomplete DOT graph")
        value = tokens[index]
        index += 1
        return value

    def identifier(token):
        if token in {"{", "}", "[", "]", ";", ",", "=", "->", "subgraph"}:
            raise ValueError("unsupported DOT identifier")
        return json.loads(token) if token.startswith('"') else token

    first = take()
    if first == "strict":
        first = take()
    if first != "digraph":
        raise ValueError("expected directed DOT graph")
    if tokens[index] != "{":
        identifier(take())
    if take() != "{":
        raise ValueError("expected DOT graph body")
    edges = defaultdict(set)
    while index < len(tokens) and tokens[index] != "}":
        if tokens[index] == ";":
            take()
            continue
        head = take()
        ids = [identifier(head)]
        if tokens[index] == "=":
            take(); identifier(take())
            continue
        while tokens[index] == "->":
            take(); ids.append(identifier(take()))
        attrs = {}
        while tokens[index] == "[":
            take()
            while tokens[index] != "]":
                if tokens[index] in {",", ";"}:
                    take()
                    continue
                key = identifier(take())
                if take() != "=":
                    raise ValueError("expected DOT attribute assignment")
                attrs[key] = identifier(take())
            take()
        if head in {"node", "edge", "graph"} and len(ids) == 1:
            continue
        if attrs.get("label") == "owns":
            continue
        for node in ids:
            edges.setdefault(node, set())
        for source, target in pairwise(ids):
            edges[source].add(target)
    if take() != "}" or index != len(tokens):
        raise ValueError("unsupported trailing DOT syntax")
    return {k: sorted(v) for k, v in edges.items()}


def parse_edges_file(path):
    """Accept madge JSON ({mod: [deps]}), depcruise JSON ({modules:[...]}),
    lakos/generic JSON ({nodes, edges:[{from,to}]}), or graphviz DOT."""
    text = Path(path).read_text(encoding="utf-8")
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return parse_dot(text)

    def norm(s):
        return os.path.normpath(s)
    if isinstance(data, dict) and isinstance(data.get("modules"), list) and (any(isinstance(m, dict) for m in data["modules"]) or isinstance(data.get("summary"), dict)):  # dependency-cruiser
        edges = defaultdict(set)
        for m in data["modules"]:
            edges[norm(m["source"])].update(
                norm(d["resolved"]) for d in m.get("dependencies", ())
                if d.get("resolved") and not any(d.get(flag) for flag in
                    ("couldNotResolve", "coreModule", "external", "matchesDoNotFollow", "dependencyTypesExternal"))
                and not any(t.startswith("npm") for t in d.get("dependencyTypes", ())))
        return {k: sorted(v) for k, v in edges.items()}
    if isinstance(data, dict) and isinstance(data.get("edges"), list) and ("nodes" in data or any(isinstance(e, dict) for e in data["edges"])):  # lakos / generic
        edges = defaultdict(set)
        nodes = data.get("nodes") or {}
        node_ids = (list(nodes) if isinstance(nodes, dict)
                    else [n.get("id") if isinstance(n, dict) else n for n in nodes])
        for e in data["edges"]:
            edges[norm(e["from"].lstrip("/"))].add(norm(e["to"].lstrip("/")))
        for n in node_ids:
            if n:
                edges.setdefault(norm(n.lstrip("/")), set())
        return {k: sorted(v) for k, v in edges.items()}
    if isinstance(data, dict) and all(isinstance(v, list) and all(isinstance(x, str) for x in v)
                                      for v in data.values()):  # madge adjacency
        return {norm(k): sorted({norm(x) for x in v}) for k, v in data.items()}
    raise ValueError("unrecognized edges format")


def align_to_git(adj, repo, include_tests):
    """Rename external-graph node ids to repo-relative git paths where a unique
    suffix match exists (madge scanned a subdir, lakos paths, etc.). The git
    join is load-bearing: hidden_coupling dies silently without it."""
    gitfiles = list_files(repo, True)
    fileset = set(gitfiles)
    by_suffix = defaultdict(list)
    for f in gitfiles:
        parts = f.split("/")
        for i in range(len(parts)):
            by_suffix["/".join(parts[i:])].append(f)
    rename, matched = {}, 0
    nodes = set(adj) | {d for v in adj.values() for d in v}
    for n in nodes:
        normalized = os.path.normpath(n)
        if os.path.isabs(normalized):
            normalized = os.path.relpath(normalized, os.path.abspath(repo))
        if normalized in fileset:
            rename[n] = normalized; matched += 1
        else:
            hits = by_suffix.get(normalized, [])
            if len(hits) == 1:
                rename[n] = hits[0]; matched += 1
            else:
                rename[n] = normalized
    new_adj = defaultdict(set)
    retained = {n for n in nodes if not is_excluded(rename[n], include_tests)}
    for n in sorted(retained):
        new_adj[rename[n]].update(rename[d] for d in adj.get(n, ()) if d in retained)
    rate = (sum(rename[n] in fileset for n in retained) / len(retained)
            if retained else 0.0)
    return {k: sorted(v) for k, v in new_adj.items()}, round(rate, 2)

# ------------------------------------------------------------------- metrics

def tarjan_sccs(adj):
    """Iterative Tarjan. Returns list of SCCs (each a list of nodes)."""
    index, low, on_stack = {}, {}, set()
    stack, sccs, counter = [], [], [0]
    for root in sorted(adj):
        if root in index:
            continue
        work = [(root, iter(sorted(adj.get(root, ()))))]
        index[root] = low[root] = counter[0]; counter[0] += 1
        stack.append(root); on_stack.add(root)
        while work:
            node, it = work[-1]
            advanced = False
            for nxt in it:
                if nxt not in adj:
                    continue
                if nxt not in index:
                    index[nxt] = low[nxt] = counter[0]; counter[0] += 1
                    stack.append(nxt); on_stack.add(nxt)
                    work.append((nxt, iter(sorted(adj.get(nxt, ())))))
                    advanced = True
                    break
                elif nxt in on_stack:
                    low[node] = min(low[node], index[nxt])
            if advanced:
                continue
            work.pop()
            if work:
                parent = work[-1][0]
                low[parent] = min(low[parent], low[node])
            if low[node] == index[node]:
                scc = []
                while True:
                    w = stack.pop(); on_stack.discard(w); scc.append(w)
                    if w == node:
                        break
                sccs.append(scc)
    return sccs


def _cycle_path(scc, adj, cap=8):
    """Short example path through the SCC, incident-encoded ("a → b → a") —
    LLMs read edge paths better than bare member lists."""
    sset = set(scc)
    start = min(scc)
    # BFS from each successor of start back to start, within the SCC
    for first in sorted(d for d in adj.get(start, ()) if d in sset):
        prev, frontier, seen = {first: start}, [first], {start, first}
        while frontier:
            nxt_frontier = []
            for n in frontier:
                for d in adj.get(n, ()):
                    if d == start:
                        seq, cur2 = [n], n
                        while cur2 != start:
                            cur2 = prev[cur2]
                            seq.append(cur2)
                        seq = list(reversed(seq)) + [start]
                        if len(seq) > cap:
                            seq = seq[:cap - 1] + ["…", start]
                        return " → ".join(seq)
                    if d in sset and d not in seen:
                        seen.add(d); prev[d] = n; nxt_frontier.append(d)
            frontier = nxt_frontier
    return None


def compute_graph_metrics(adj, top, scope=None):
    if top <= 0:
        raise ValueError("--top must be positive")
    nodes = set(adj)
    for deps in adj.values():
        nodes.update(deps)
    adj = {n: sorted({d for d in adj.get(n, ()) if d in nodes}) for n in sorted(nodes)}
    fan_out = {n: len(adj[n]) for n in sorted(nodes)}
    fan_in = Counter()
    for n, deps in adj.items():
        for d in deps:
            fan_in[d] += 1
    edge_count = sum(fan_out.values())

    # cycles: SCCs of size >1, plus self-loops (possible via --edges input)
    sccs = [s for s in tarjan_sccs(adj) if len(s) > 1 or s[0] in adj[s[0]]]
    sccs.sort(key=lambda s: (-len(s), sorted(s)))
    cycle_nodes = {n for s in sccs for n in s}

    inst = {n: (fan_out[n] / (fan_in[n] + fan_out[n])) if fan_in[n] + fan_out[n] else None
            for n in sorted(nodes)}

    def deg(n):
        return fan_in[n] + fan_out[n]
    # hub floor >=2/>=2 plus p90 degree cutoff (Arcan uses benchmark-derived
    # thresholds; a repo-relative percentile is the honest cheap equivalent)
    degs = sorted(deg(n) for n in nodes)
    p90 = degs[int(0.9 * (len(degs) - 1))] if len(degs) >= 20 else 0
    hubs_all = sorted((n for n in nodes
                       if fan_in[n] >= 2 and fan_out[n] >= 2 and deg(n) >= p90),
                      key=lambda n: (-deg(n), n))
    orphans_all = sorted(n for n in nodes if deg(n) == 0)

    # SDP: depend toward stability (any inversion violates it — Martin);
    # delta > 0.4 is a precision heuristic, not a published threshold.
    sdp = []
    for n in nodes:
        if BARREL_RE.search(n):
            continue
        for d in adj[n]:
            if inst[n] is not None and inst[d] is not None and inst[d] - inst[n] > 0.4 and fan_in[n] >= 2:
                sdp.append({"from": n, "to": d, "delta": round(inst[d] - inst[n], 2),
                            "from_fan_in": fan_in[n]})
    sdp.sort(key=lambda e: (-e["from_fan_in"], -e["delta"], e["from"], e["to"]))

    # PR mode: scope BEFORE top-N capping, else in-scope findings silently
    # vanish behind the cap while summary counts still include them.
    if scope is not None:
        sccs = [s for s in sccs if any(m in scope for m in s)]
        cycle_nodes = {n for s in sccs for n in s}
        hubs_all = [n for n in hubs_all if n in scope]
        orphans_all = [n for n in orphans_all if n in scope]
        sdp = [e for e in sdp if e["from"] in scope or e["to"] in scope]

    # Levelization (Eades–Lin–Smyth): order nodes so edges point forward.
    # Backward ("feedback") edges are the near-minimal cut set that would make
    # the graph layerable — the highest-precision forbid-rule candidates
    # (the DSM back-edge signal, without a DSM).
    feedback, layering = [], None
    if edge_count and len(nodes) <= 3000:
        succ = {n: set(adj[n]) for n in sorted(nodes)}
        pred = defaultdict(set)
        for n, ds in adj.items():
            for d in ds:
                pred[d].add(n)
        remaining, s1, s2 = set(nodes), [], []
        while remaining:
            moved = True
            while moved:
                moved = False
                for n in [x for x in sorted(remaining) if not (succ[x] & remaining) - {x}]:
                    s2.append(n); remaining.discard(n); moved = True
                for n in [x for x in sorted(remaining) if not (pred[x] & remaining) - {x}]:
                    s1.append(n); remaining.discard(n); moved = True
            if remaining:  # break a cycle: node with max out-in degree delta
                n = min(remaining, key=lambda x: (len(pred[x] & remaining) - len(succ[x] & remaining), x))
                s1.append(n); remaining.discard(n)
        order = {n: i for i, n in enumerate(s1 + list(reversed(s2)))}
        feedback = sorted(({"from": n, "to": d, "span": order[n] - order[d]}
                           for n in nodes for d in adj[n] if order[d] <= order[n]),
                          key=lambda e: (-e["span"], e["from"], e["to"]))
        layering = round(1 - len(feedback) / edge_count, 3)
        if scope is not None:  # layering_score stays whole-graph; edges scoped
            feedback = [e for e in feedback if e["from"] in scope or e["to"] in scope]

    nccd = pc = None
    if 1 < len(nodes) <= 3000:  # ponytail: O(V*E) BFS closure; skip on huge graphs
        ccd = 0
        for n in nodes:
            seen, frontier = {n}, [n]
            while frontier:
                nxt = {d for f in frontier for d in adj[f]} - seen
                seen.update(nxt); frontier = nxt
            ccd += len(seen)
        n_ = len(nodes)
        tree_ccd = (n_ + 1) * math.log2(n_ + 1) - n_
        nccd = round(ccd / tree_ccd, 2) if tree_ccd > 0 else None
        # MacCormack propagation cost: closure density (incl. self). Size-
        # sensitive — compare within one repo over time, not across repos.
        pc = round(ccd / (n_ * n_), 3)

    return {
        "adj": adj,
        "_full": {"cycles": [sorted(s) for s in sccs],
                  "sdp": [(e["from"], e["to"]) for e in sdp],
                  "hubs": hubs_all, "orphans": orphans_all},
        "summary": {
            "nodes": len(nodes), "edges": edge_count,
            "acyclic": not sccs,
            "cycle_count": len(sccs), "nodes_in_cycles": len(cycle_nodes),
            "nccd": nccd,  # lower is better; <1 horizontal, >2 likely tangled (Lakos)
            "propagation_cost": pc,
            "layering_score": layering,  # 1.0 = perfectly layerable
        },
        # the complete uncapped cut set makes the graph layerable; span = how far
        # backward the edge jumps in the inferred layering
        "feedback_edges": feedback[:top],
        "feedback_truncated": max(0, len(feedback) - top),
        # folder_span 1 = intra-folder tangle (often intentional); >1 crosses
        # architecture boundaries — mechanizes the intentional-cycle criterion
        "cycles": [{"size": len(s), "members": sorted(s)[:12],
                    "folder_span": len({os.path.dirname(m) for m in s}),
                    "example_path": _cycle_path(s, adj),
                    "truncated": max(0, len(s) - 12)} for s in sccs[:top]],
        "cycles_truncated": max(0, len(sccs) - top),
        # role:aggregator = facade-shaped hub (huge fan_out, near-max
        # instability) — catches barrels that BARREL_RE can't name-match
        "hubs": [{"id": n, "fan_in": fan_in[n], "fan_out": fan_out[n],
                  "instability": round(inst[n], 2),
                  **({"role": "aggregator"} if fan_out[n] >= 20 and (inst[n] or 0) >= 0.9 else {})}
                 for n in hubs_all[:top]],
        "hubs_truncated": max(0, len(hubs_all) - top),
        "orphans": orphans_all[:top], "orphans_truncated": max(0, len(orphans_all) - top),
        "sdp_violations": sdp[:top], "sdp_truncated": max(0, len(sdp) - top),
    }

# ----------------------------------------------------------------- git layer

RENAME_BRACE_RE = re.compile(r"\{([^{}]*) => ([^{}]*)\}")


def _split_rename(path):
    """numstat rename forms: 'a.py => b.py' or 'src/{a.py => b.py}'.
    Returns (old, new) or (None, path)."""
    if "{" in path and "=>" in path:
        old = RENAME_BRACE_RE.sub(lambda m: m.group(1), path).replace("//", "/")
        new = RENAME_BRACE_RE.sub(lambda m: m.group(2), path).replace("//", "/")
        return old, new
    if " => " in path:
        old, new = path.split(" => ", 1)
        return old, new
    return None, path


def _decay(t):
    """Canonical Bugspots sigmoid: t in [0,1]; newest commit → 0.5, oldest → ~0,
    with most weight in the last ~fifth of the window. Aggressive by design —
    formerly-hot dormant files must fall fast in ranking (Google/Linespots)."""
    return 1.0 / (1.0 + math.exp(-12.0 * t + 12.0))


def _date(epoch):
    return time.strftime("%Y-%m-%d", time.gmtime(epoch)) if epoch else None


def git_signals(repo, nodes, adj, top, include_tests=False, scope=None,
                max_commits=2000, max_files_per_commit=20):
    try:
        # numstat on a blobless partial clone lazy-fetches every blob over the
        # network (minutes); fall back to name-status there (no line counts).
        partial = subprocess.run(
            ["git", "-C", repo, "config", "--get", "remote.origin.partialclonefilter"],
            capture_output=True, text=True, check=False).stdout.strip()
        stat_flag = "--name-status" if partial else "--numstat"
        out = subprocess.run(
            ["git", "-c", "core.quotepath=off", "-C", repo, "log", "--no-merges",
             stat_flag, "-M", "-z", "--format=%x00commit%x00%H%x00%an%x00%at%x00",
             f"--max-count={max_commits}"],
            capture_output=True, check=True, timeout=60).stdout.decode("utf-8", "surrogateescape")
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

    # newest-first walk; renames alias old path -> current name so history
    # survives renames; bot commits fabricate coupling — skipped.
    alias = {}

    def cur(p):
        seen = set()
        while p in alias and p not in seen:
            seen.add(p); p = alias[p]
        return p

    commits, window_ids = [], []
    file_commits = defaultdict(list)
    tokens = iter(out.split("\0"))
    author, epoch, files, footprint = None, None, [], 0
    for token in tokens:
        record = token.lstrip("\n")
        if record == "commit":
            if files and author is not None and not BOT_AUTHOR_RE.search(author):
                commits.append((author, epoch, files, footprint))
            window_ids.append(next(tokens))
            author, epoch = next(tokens), int(next(tokens))
            files, footprint = [], 0
        elif record:
            if partial:
                status = record
                old = next(tokens) if status.startswith(("R", "C")) else None
                new, lines = next(tokens), 0
            else:
                add, dele, new = record.split("\t", 2)
                lines = (0 if add == "-" else int(add)) + (0 if dele == "-" else int(dele))
                old = None
                if not new:
                    old, new = next(tokens), next(tokens)
            footprint += 1
            if old:
                alias[old] = cur(new)
            path = cur(new)
            if os.path.splitext(path)[1] in CODE_EXTS and not is_excluded(path, include_tests):
                files.append((path, lines))
                file_commits[path].append(window_ids[-1])
    if files and author is not None and not BOT_AUTHOR_RE.search(author):
        commits.append((author, epoch, files, footprint))

    epochs = [e for _, e, _, _ in commits if e is not None]
    lo, hi = (min(epochs), max(epochs)) if epochs else (0, 0)
    span = max(1, hi - lo)
    recent_cut = hi - 90 * 86400

    decayed = Counter()      # Σ sigmoid weight per file — hotspot ranking
    churn = Counter()        # raw commit count (evidence)
    churn_small = Counter()  # co-change-eligible commits — jaccard denominator
    line_churn = Counter()   # added+deleted lines (evidence; relative churn = /loc)
    recent_w = Counter()     # decayed weight from last 90 days
    co = Counter()
    authors = defaultdict(Counter)
    last_touched = {}
    author_last = {}         # author -> newest commit epoch (departure detection)
    first_author = {}        # file -> author of oldest windowed commit (DOA "FA")
    flat_window = (hi - lo) < 86400  # degenerate window (shallow clone / same-day
    for who, e, fs, footprint in commits:      # import): decay meaningless, weight uniformly
        w = 1.0 if (e is None or flat_window) else _decay((e - lo) / span)
        if e is not None:
            author_last[who] = max(e, author_last.get(who, e))
        for f, ln in fs:
            churn[f] += 1; decayed[f] += w; line_churn[f] += ln
            authors[f][who] += 1
            first_author[f] = who  # keeps overwriting -> oldest wins
            if e is not None and e >= recent_cut:
                recent_w[f] += w
            if e is not None:
                last_touched[f] = max(e, last_touched.get(f, e))
        names = sorted({f for f, _ in fs})
        if footprint <= max_files_per_commit:  # skip mass renames/reformats
            for i in range(len(names)):
                for j in range(i + 1, len(names)):
                    co[(names[i], names[j])] += 1
            for f in names:
                churn_small[f] += 1

    hotspots = []
    # shortlist by decay weight (top*10, not provably score-order-safe — a
    # colossal rarely-touched file beyond the shortlist could out-score; the
    # bound is documented in score_formula) — scope filter BEFORE shortlist
    candidates = ((f, dw) for f, dw in decayed.items()
                  if scope is None or f in scope)
    for f, dw in sorted(candidates, key=lambda kv: (-kv[1], kv[0]))[:top * 10]:
        p = os.path.join(repo, f)
        if not os.path.isfile(p):
            continue  # deleted since
        loc = indent = 0
        try:
            with open(p, encoding="utf-8", errors="replace") as stream:
                for line_ in stream:
                    s = line_.expandtabs(4)
                    if s.strip():
                        loc += 1
                        indent += (len(s) - len(s.lstrip(" "))) // 4
        except OSError:
            continue
        ac = authors[f]
        total = sum(ac.values())
        hotspots.append({
            "file": f, "commits": churn[f], "lines_churned": line_churn[f],
            "loc": loc, "indent_units": indent,
            "recent_share": round(recent_w[f] / dw, 2) if dw else None,
            "last_touched": _date(last_touched.get(f)),
            "authors": len(ac),
            "top_author_share": round(ac.most_common(1)[0][1] / total, 2) if total else None,
            "score": round(dw * (loc + indent)),
        })
    hotspots.sort(key=lambda h: (-h["score"], h["file"]))
    hot_files = {h["file"] for h in hotspots[:top]}

    # hot functions: which functions inside the top hotspots take the churn —
    # converts "read this 3000-line file" into "read these 3 functions".
    # Parsed from `git log -p` hunk headers (git's xfuncname context). Skipped
    # on partial clones (-p would lazy-fetch blobs).
    enrichment = {"attempted": 0, "completed": 0, "timed_out": 0, "failed": 0,
                  "skipped": len(hotspots[:top]) if partial else max(0, len(hotspots[:top]) - 10),
                  "skip_reason": "partial clone" if partial else "at most 10 hotspots",
                  "history": "file-touching commit IDs from main scan; no revision walk"}
    if not partial:
        hunk_re = re.compile(r"^@@[^@]*@@ (.+)$", re.MULTILINE)
        def_re = re.compile(r"(?:def|class|function|fn|func|interface|struct|impl)\s+([A-Za-z_][\w$]*)")
        call_re = re.compile(r"([A-Za-z_][\w$]*)\s*\(")
        for h in hotspots[:min(10, top)]:
            enrichment["attempted"] += 1
            try:
                logp = subprocess.run(
                    ["git", "-c", "core.quotepath=off", "-C", repo, "log",
                     "--no-walk=unsorted", "--stdin", "-p", "--format=", "-M",
                     "--", h["file"]],
                    input="\n".join(file_commits[h["file"]]) + "\n",
                    capture_output=True, text=True, check=True, timeout=20).stdout
            except subprocess.TimeoutExpired:
                enrichment["timed_out"] += 1
                continue
            except (subprocess.CalledProcessError, FileNotFoundError):
                enrichment["failed"] += 1
                continue
            enrichment["completed"] += 1
            names = Counter()
            for ctx in hunk_re.findall(logp):
                m = def_re.search(ctx) or call_re.search(ctx)
                if m:
                    names[m.group(1)] += 1
            if names:
                h["hot_functions"] = [{"name": n, "touches": c}
                                      for n, c in sorted(names.items(), key=lambda kv: (-kv[1], kv[0]))[:5]]
                h["hot_functions_truncated"] = max(0, len(names) - 5)

    # knowledge: DOA (Avelino truck-factor lineage) + git-only departure —
    # a knowledge island inside a hotspot/cycle outranks either signal alone
    doa_authors = {}
    for f, ac in authors.items():
        total = sum(ac.values())
        doas = {}
        for a, dl in ac.items():
            fa = 1.0 if a == first_author.get(f) else 0.0
            doas[a] = 3.293 + 1.098 * fa + 0.164 * dl - 0.321 * math.log(1 + total - dl)
        mx = max(doas.values())
        doa_authors[f] = ({a for a, v in doas.items() if v / mx > 0.75}
                          if mx > 0 else set(ac))
    removed, tf = set(), 0
    flist = list(doa_authors)
    while flist:  # greedy truck factor: remove top expert until >50% orphaned
        if sum(1 for f in flist if doa_authors[f] <= removed) * 2 > len(flist):
            break
        counts = Counter(a for f in flist for a in doa_authors[f] - removed)
        if not counts:
            break
        removed.add(min(counts, key=lambda a: (-counts[a], a))); tf += 1
    departed = {a for a, e in author_last.items() if e < hi - 365 * 86400}
    islands = sorted((f for f, s in doa_authors.items()
                      if len(s) == 1 and (scope is None or f in scope)),
                     key=lambda f: (-decayed[f], f))
    stale = sorted(
        ({"file": f, "departed_share": round(
            sum(c for a, c in authors[f].items() if a in departed) / sum(authors[f].values()), 2)}
         for f in authors
         if (scope is None or f in scope)
         and sum(c for a, c in authors[f].items() if a in departed) * 2
             > sum(authors[f].values())),
        key=lambda x: (-x["departed_share"], x["file"]))
    knowledge = {
        "truck_factor": tf,
        "islands": [{"file": f, "owner": next(iter(doa_authors[f])),
                     "is_hotspot": f in hot_files} for f in islands[:top]],
        "islands_truncated": max(0, len(islands) - top),
        "stale_ownership": stale[:top],
        "stale_ownership_truncated": max(0, len(stale) - top),
        "note": ("DOA over the analyzed window only; departed = no commit in "
                 "12 months within window"),
    }

    edge_pairs = set()
    for n, deps in adj.items():
        for d in deps:
            edge_pairs.add((n, d)); edge_pairs.add((d, n))
    hidden = []
    for (a, b), c in sorted(co.items(), key=lambda kv: (-kv[1], kv[0])):
        if c < 4:
            break
        if scope is not None and a not in scope and b not in scope:
            continue
        denom = churn_small[a] + churn_small[b] - c
        jaccard = c / denom if denom else 1.0
        if a in nodes and b in nodes and (a, b) not in edge_pairs and jaccard >= 0.3:
            hidden.append({"a": a, "b": b, "co_commits": c, "jaccard": round(jaccard, 2)})

    churned_in_graph = sum(1 for f in churn if f in nodes)
    hot_all = {h["file"] for h in hotspots}  # scored set, pre-cap (compound needs it)
    sizes = sorted(footprint for _, _, _, footprint in commits)
    co_scoped = [(pair, c) for pair, c in sorted(co.items(), key=lambda kv: (-kv[1], kv[0]))
                 if scope is None or any(f in scope for f in pair)]
    stats = {
        "commits": len(commits),
        "median_files_per_commit": sizes[len(sizes) // 2] if sizes else 0,
        "big_commit_share": (round(sum(1 for n in sizes if 10 < n <= max_files_per_commit)
                                   / len(sizes), 2) if sizes else 0.0),
        "max_co": co.most_common(1)[0][1] if co else 0,
    }
    return {
        "commits_analyzed": len(commits), "commits_cap": max_commits,
        "commits_scanned": len(window_ids),
        "window": {"timestamp_basis": "author", "oldest": _date(lo), "as_of": _date(hi)},
        "enrichment": enrichment,
        **({"line_churn_note": "lines_churned unavailable (blobless partial clone "
            "— numstat would lazy-fetch every blob)"} if partial else {}),
        "git_join": (round(churned_in_graph / len(churn), 2) if churn else None),
        "score_formula": ("hotspot score = decayed_commit_weight (canonical bugspots "
                          "sigmoid: newest≈0.5, most weight in last ~fifth of window) "
                          "× (loc + indent_units); recent_share = share of decayed "
                          "weight from last 90 days; scored from the top-10×N files "
                          "by decayed weight"),
        "hotspots": hotspots[:top],
        "hotspots_truncated": max(0, len(hotspots) - top),
        "hotspot_candidates_truncated": max(0, sum(scope is None or f in scope for f in decayed) - top * 10),
        "co_change_top": [{"a": a, "b": b, "co_commits": c}
                          for (a, b), c in co_scoped[:top]],
        "co_change_top_truncated": max(0, len(co_scoped) - top),
        "hidden_coupling": hidden[:top], "hidden_truncated": max(0, len(hidden) - top),
        "knowledge": knowledge,
        "_hidden_all": [(h["a"], h["b"]) for h in hidden],
        "_last_touched": {f: _date(e) for f, e in last_touched.items()},
        "_co2": {p for p, c in co.items() if c >= 2},
        "_stats": stats,
        "_hot_all": hot_all,
        "_islands_all": islands,
        "_alias": {old: cur(old) for old in alias},  # rename map for baseline v2
    }

def folder_cohesion(adj, co2, top, scope=None):
    """PairSmell-InCol analog: folders whose files are mostly unrelated (no
    import edge, no co-change) are grab-bags violating common closure.
    Phenomenon validated (InCol pairs co-change 35% less); this cheap proxy
    itself is unvalidated — present as a lead, not a verdict."""
    folders = defaultdict(list)
    for n in adj:
        folders[os.path.dirname(n)].append(n)
    out = []
    for fold, fs in folders.items():
        if not (3 <= len(fs) <= 40):  # ponytail: skip tiny + giant flat folders
            continue
        if scope is not None and not any(f in scope for f in fs):
            continue
        fset = set(fs)
        local_edges = {(a, b) for a in fs for b in adj[a] if b in fset}
        rel = tot = 0
        for i in range(len(fs)):
            for j in range(i + 1, len(fs)):
                a, b = fs[i], fs[j]
                tot += 1
                if (a, b) in local_edges or (b, a) in local_edges or (min(a, b), max(a, b)) in co2:
                    rel += 1
        out.append({"folder": fold or ".", "files": len(fs), "cohesion": round(rel / tot, 2)})
    out.sort(key=lambda x: (x["cohesion"], x["folder"]))
    return [f for f in out if f["cohesion"] < 0.3][:top]

# ------------------------------------------------------- baseline & PR scope

def _keys(raw, alias):
    """Canonical identity keys from raw finding material, with member paths
    normalized through the git rename map first. Storing RAW paths in the
    baseline (v2) and normalizing at compare time is what lets a `git mv`
    refactor read as `known` instead of `new` — the ratchet must never punish
    refactoring. (ArchUnit FreezingArchRule lesson: structural identity,
    volatile fields excluded; rename-following added on top.)"""
    n = lambda p: alias.get(p, p)
    return {
        "cycles": {hashlib.sha1("|".join(sorted(n(m) for m in mem)).encode()).hexdigest()[:12]
                   for mem in raw["cycles"]},
        "sdp": {f"{n(a)}→{n(b)}" for a, b in raw["sdp"]},
        "hidden": {"↔".join(sorted((n(a), n(b)))) for a, b in raw["hidden"]},
        "hubs": {n(x) for x in raw["hubs"]},
        "orphans": {n(x) for x in raw["orphans"]},
    }


def apply_baseline(digest, raw, path, refresh, pr_mode, alias=None, rebaseline=False):
    """raw = uncapped finding material: {cycles: [[members]], sdp: [(a,b)],
    hidden: [(a,b)], hubs: [ids], orphans: [ids]}. alias = git rename map
    (old path -> current path) applied to BASELINE entries at compare time."""
    if refresh and os.path.exists(path) and not pr_mode and not rebaseline:
        base = json.loads(Path(path).read_text())
        if base.get("version") != 2:
            raise ValueError("baseline upgrade requires --rebaseline")
        current, previous = _keys(raw, {}), _keys(base, alias or {})
        if any(current[k] - previous[k] for k in current):
            raise ValueError("baseline growth refused; use --rebaseline explicitly")
    if refresh or not os.path.exists(path):
        if pr_mode:  # includes failed --changed refs: intent decides, not diff success
            digest.setdefault("warnings", []).append(
                "baseline not written in PR mode (scoped run would freeze a partial view)")
            return
        Path(path).write_text(json.dumps({"version": 2, **raw}, indent=1))
        digest["baseline"] = {"status": "refreshed" if refresh else "created", "path": path}
        return
    base = json.loads(Path(path).read_text())
    if base.get("version") != 2:
        digest.setdefault("warnings", []).append(
            "baseline file is pre-v2 (no rename-following) — run --refresh-baseline to upgrade")
        digest["baseline"] = {"status": "incompatible", "path": path}
        return
    cur_keys = _keys(raw, {})
    base_keys = _keys(base, alias or {})
    diff = {}
    for cat in ("cycles", "sdp", "hidden", "hubs", "orphans"):
        cur, old = cur_keys[cat], base_keys[cat]
        diff[cat] = {"new": len(cur - old), "known": len(cur & old),
                     # scoped run can't see out-of-scope findings — "fixed" is
                     # indeterminable from a partial view
                     "fixed": None if pr_mode else len(old - cur)}
    digest["baseline"] = {"status": "compared", "path": path, "diff": diff,
                          **({"note": "PR mode: fixed counts unavailable (partial view)"}
                             if pr_mode else {})}
    # annotate visible findings: new vs known
    for c in digest.get("cycles", ()):
        if c.get("id"):
            c["baseline"] = "known" if c["id"] in base_keys["cycles"] else "new"
    for e in digest.get("sdp_violations", ()):
        e["baseline"] = "known" if f"{e['from']}→{e['to']}" in base_keys["sdp"] else "new"
    git = digest.get("git") or {}
    for h in git.get("hidden_coupling", ()):
        key = "↔".join(sorted((h["a"], h["b"])))
        h["baseline"] = "known" if key in base_keys["hidden"] else "new"
    for h in digest.get("hubs", ()):
        h["baseline"] = "known" if h["id"] in base_keys["hubs"] else "new"


def changed_scope(repo, base_ref, adj, include_tests):
    """PR blast radius: changed code files + their 1-hop graph neighbors."""
    try:
        out = subprocess.run(
            ["git", "-c", "core.quotepath=off", "-C", repo, "diff",
             "--name-only", "-z", f"{base_ref}...HEAD"],
            capture_output=True, check=True).stdout.decode("utf-8", "surrogateescape").split("\0")
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    changed = {f for f in out if os.path.splitext(f)[1] in CODE_EXTS
               and not is_excluded(f, include_tests)}
    neighbors = set()
    for n, deps in adj.items():
        for d in deps:
            if n in changed:
                neighbors.add(d)
            if d in changed:
                neighbors.add(n)
    return changed, (changed | neighbors)


def detect_tier3_triggers(digest, git_stats):
    """Build-condition detectors for parked (Tier 3) features: each fires when
    a real run exhibits the exact situation the deferred feature exists to
    fix. Fired triggers are the pre-agreed go-signal to build — accountability
    instead of 'later means never'. Judge-side triggers (pagerank misrank,
    cohesion-informed verdicts) live in SKILL.md, not here."""
    t = []
    if digest["summary"]["nodes"] > 3000:
        t.append("bitset-nccd: >3000 nodes, NCCD/propagation_cost skipped — "
                 "bitset closure over the SCC condensation would raise the cap ~20k")
    if git_stats:
        if (git_stats["commits"] >= 200 and git_stats["median_files_per_commit"] <= 2
                and git_stats["max_co"] < 4):
            t.append("author-day-windowing: fine-grained commits starve co-change "
                     "(median ≤2 files/commit, no pair reaches 4 co-commits) — "
                     "sliding-window same-author grouping would recover coupling")
        if (git_stats["big_commit_share"] >= 0.25
                and (digest.get("git") or {}).get("hidden_truncated", 0) > 0):
            t.append("pair-damping: ≥25% of commits touch 10-20 files and hidden "
                     "coupling overflows the cap — 1/(n-1) damping + directional "
                     "confidence would improve pair precision")
    if digest.get("baseline", {}).get("status") == "compared":
        t.append("erosion-velocity: a second data point now exists (baseline "
                 "compared) — `--at <rev>` metric trend tracking is meaningful")
    return t


# --------------------------------------------------------------------- main

def run(repo, lang, edges_file, top, no_git, include_tests=False,
        changed=None, baseline=None, refresh_baseline=False, rebaseline=False):
    if top <= 0:
        raise ValueError("--top must be positive")
    discovered = list_files(repo, True, code_only=False)
    eligible = [f for f in discovered if not is_excluded(f, include_tests)]
    files = [f for f in eligible if os.path.splitext(f)[1] in CODE_EXTS]
    discovered_counts = Counter(os.path.splitext(f)[1] for f in discovered)
    eligible_counts = Counter(os.path.splitext(f)[1] for f in eligible)
    coverage = {ext: {"discovered": count, "eligible": eligible_counts[ext],
                      "parsed": None, "failed": None}
                for ext, count in sorted(discovered_counts.items())}
    if edges_file:
        raw = parse_edges_file(edges_file)
        raw, match_rate = align_to_git(raw, repo, include_tests)
        source = f"external:{edges_file}"
    else:
        py = [f for f in files if f.endswith(".py")]
        if py and (lang == "python" or len(py) >= len(files) * 0.2):
            extract_python.type_only = 0
            raw = extract_python(repo, py)
            coverage[".py"].update({k: extract_python.coverage[k] for k in ("parsed", "failed")})
            source = f"builtin:python ({len(py)}/{len(files)} code files)"
        else:  # no extractor for this language — git-signals-only mode
            raw, source = {}, "none"
        match_rate = None

    # PR scope resolves BEFORE metrics so filtering precedes top-N caps
    pr_mode = changed is not None
    scope_files = None
    scope_info = None
    if changed:
        sc = changed_scope(repo, changed, raw, include_tests)
        if sc is None:
            scope_info = {"base": changed, "error": "git diff failed — full digest emitted"}
        else:
            cset, scope_files = sc
            scope_info = {"base": changed, "changed_code_files": len(cset),
                          "in_scope_with_neighbors": len(scope_files)}

    g = compute_graph_metrics(raw, top, scope_files)
    adj = g.pop("adj")
    full = g.pop("_full")
    digest = {"extractor": source, **g, "coverage": coverage,
              "graph_scope": "eligible supplied nodes" if edges_file else "successfully parsed Python files"}
    if source.startswith("builtin:python") and extract_python.type_only:
        digest["summary"]["type_only_imports_excluded"] = extract_python.type_only
    warnings = []
    if any(c["failed"] for c in coverage.values()):
        warnings.append("parse/read failures omitted from graph; see coverage")
    if not edges_file and any(c["eligible"] and c["parsed"] is None
                              for ext, c in coverage.items() if ext in CODE_EXTS):
        warnings.append("graph omits languages without an active extractor; see coverage")
    if source == "none":
        warnings.append("no graph extractor for this language — git signals only "
                        "(hotspots, co-change); graph metrics and hidden_coupling "
                        "unavailable. Provide --edges from a native tool.")
    if match_rate is not None:
        digest["node_git_match_rate"] = match_rate
        if match_rate < 0.5:
            warnings.append("most graph node ids don't match git paths — "
                            "git-based signals (hidden_coupling) unreliable")
    if digest["summary"]["edges"] == 0 and source != "none":
        warnings.append("no edges extracted — graph unusable; this means "
                        "extraction failed, NOT that the architecture is clean")

    hidden_all = []
    git_stats = None
    hot_all, islands_all, alias = set(), [], {}
    if not no_git:
        git = git_signals(repo, set(adj), adj, top, include_tests, scope_files)
        if git:
            hidden_all = git.pop("_hidden_all")
            git_stats = git.pop("_stats")
            hot_all = git.pop("_hot_all")
            islands_all = git.pop("_islands_all")
            alias = git.pop("_alias")
            co2 = git.pop("_co2")
            if digest["summary"]["edges"]:
                lows = folder_cohesion(adj, co2, len(adj), scope_files)
                if lows:
                    digest["low_cohesion_folders"] = lows[:top]
                    digest["low_cohesion_folders_truncated"] = max(0, len(lows) - top)
            lt = git.pop("_last_touched")
            for c, members in zip(digest["cycles"], full["cycles"]):
                dates = [lt[m] for m in members if m in lt]
                c["last_active"] = max(dates) if dates else None
            if git["git_join"] is not None and git["git_join"] < 0.3 and digest["summary"]["edges"]:
                warnings.append("git↔graph join rate low — hidden_coupling and "
                                "cycle last_active dates unreliable")
            digest["git"] = git

    # cycle identities ride along for baseline annotation (full member sets)
    cycle_ids = {tuple(m[:12]): hashlib.sha1("|".join(m).encode()).hexdigest()[:12]
                 for m in full["cycles"]}
    for c in digest["cycles"]:
        c["id"] = cycle_ids.get(tuple(c["members"]))

    # compound smells: overlaps are the amplifier — 97% of cycles pass through
    # an unstable-dependency center; engineers locate the pain at the
    # intersections (Sas & Avgeriou, EMSE 2022, 9 industrial projects).
    # hotspot membership is bounded by the scoring shortlist (top×10).
    smell_map = defaultdict(set)
    for s in full["cycles"]:
        for m in s:
            smell_map[m].add("cycle")
    for n in full["hubs"]:
        smell_map[n].add("hub")
    for a, _b in full["sdp"]:
        smell_map[a].add("sdp_source")
    for a, b in hidden_all:
        smell_map[a].add("hidden_coupling"); smell_map[b].add("hidden_coupling")
    for f in hot_all:
        smell_map[f].add("hotspot")
    for f in islands_all:
        smell_map[f].add("knowledge_island")
    compound = sorted(({"id": n, "smells": sorted(s), "count": len(s)}
                       for n, s in smell_map.items() if len(s) >= 2
                       and (scope_files is None or n in scope_files)),
                      key=lambda x: (-x["count"], x["id"]))
    if compound:
        digest["compound"] = compound[:top]
        digest["compound_truncated"] = max(0, len(compound) - top)

    if scope_info:
        digest["scope"] = scope_info
        if "error" in scope_info:
            warnings.append(f"--changed {changed}: git diff failed — full digest emitted")
    if warnings:
        digest["warnings"] = warnings

    if baseline:
        raw_ids = {"cycles": full["cycles"], "sdp": full["sdp"],
                   "hidden": hidden_all, "hubs": full["hubs"],
                   "orphans": full["orphans"]}
        apply_baseline(digest, raw_ids, baseline, refresh_baseline, pr_mode, alias, rebaseline)

    triggers = detect_tier3_triggers(digest, git_stats)
    if triggers:
        digest["tier3_triggers"] = triggers
    return digest


def regression_tests():
    import tempfile
    from unittest.mock import patch

    for source, skipped in (
        ("from typing import TYPE_CHECKING as TC\nif TC: import other", 1),
        ("TYPE_CHECKING=True\nif TYPE_CHECKING: import other", 0),
        ("if obj.TYPE_CHECKING: import other", 0),
        ("import typing as t\nif t.TYPE_CHECKING and unknown: import other", 1),
        ("import typing as t\nif not t.TYPE_CHECKING: pass\nelse: import other", 1),
    ):
        assert _runtime_nodes(ast.parse(source))[1] == skipped
    work = Path(__file__).resolve().parent.parent
    with tempfile.TemporaryDirectory(prefix="xray-test-", dir=work) as td:
        root = Path(td)
        subprocess.run(["git", "-c", "core.fsmonitor=false", "init", "-q", td], check=True)

        def write(name, text=""):
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)

        for name, text in {
            "main.py": "import local\nimport pkg.sub.mod\nimport service.api\n",
            "pkg/__init__.py": "import main\n", "pkg/local.py": "",
            "pkg/sub/__init__.py": "", "pkg/sub/mod.py": "from .. import local\n",
            "src/service/__init__.py": "", "src/service/api.py": "from . import other\n",
            "src/service/other.py": "", "bad.py": "def ???",
            "tests/t.py": "", "test_api.py": "", "generated/g.py": "",
        }.items():
            write(name, text)
        subprocess.run(["git", "-c", "core.fsmonitor=false", "-C", td, "add", "."], check=True)
        files = list_files(td)
        graph = extract_python(td, files)
        assert "pkg/local.py" not in graph["main.py"]
        assert set(graph["main.py"]) == {"pkg/__init__.py", "pkg/sub/__init__.py",
                                          "pkg/sub/mod.py", "src/service/__init__.py", "src/service/api.py"}
        assert "pkg/local.py" in graph["pkg/sub/mod.py"]
        assert "src/service/other.py" in graph["src/service/api.py"]
        assert "bad.py" not in graph and extract_python.coverage["failed"] == 1
        digest = run(td, "python", None, 10, True)
        assert digest["coverage"][".py"] == {"discovered": 12, "eligible": 9, "parsed": 8, "failed": 1}
        assert "bad.py" not in digest["orphans"]
        assert any({"main.py", "pkg/__init__.py"} <= set(c["members"]) for c in digest["cycles"])
        for prefix in ("one", "two"):
            write(prefix + "/src/shared/a.py", "from . import b\n")
            write(prefix + "/src/shared/b.py")
        relatives = extract_python(td, [prefix + "/src/shared/" + name + ".py"
                                        for prefix in ("one", "two") for name in ("a", "b")])
        assert relatives["one/src/shared/a.py"] == ["one/src/shared/b.py"]
        assert relatives["two/src/shared/a.py"] == ["two/src/shared/b.py"]
        for fmt in (
            {"main.py": ["tests/t.py", "generated/g.py"], "tests/t.py": ["main.py"]},
            {"modules": [{"source": "main.py", "dependencies": [{"resolved": "tests/t.py"}]}]},
            {"nodes": ["main.py", "tests/t.py"], "edges": [{"from": "main.py", "to": "tests/t.py"}]},
            'digraph { "main.py" -> "tests/t.py"; "tests/t.py" -> "main.py"; }',
        ):
            path = root / "edges.json"
            path.write_text(fmt if isinstance(fmt, str) else json.dumps(fmt))
            excluded = run(td, "auto", str(path), 10, True)
            included = run(td, "auto", str(path), 10, True, True)
            assert excluded["summary"]["nodes"] == 1 and excluded["summary"]["edges"] == 0
            assert included["summary"]["nodes"] >= 2 and included["summary"]["edges"] > 0
        aligned, _ = align_to_git({"t.py": ["main.py"], "./main.py": ["t.py"]}, td, False)
        assert aligned == {"main.py": []}
        assert parse_dot('digraph { isolated; a -> b; "c" -> "c"; "d" -> "e" [label = "owns"]; }') == {
            "isolated": [], "a": ["b"], "b": [], "c": ["c"]}
        try:
            parse_dot("digraph { subgraph cluster { a -> b; } }")
        except ValueError:
            pass
        else:
            raise AssertionError("unsupported DOT was silently accepted")
        for top in (0, -1):
            result = subprocess.run([sys.executable, __file__, "--top", str(top)], capture_output=True, check=False)
            assert result.returncode != 0 and b"positive" in result.stderr
        empty = {"cycles": [], "sdp": [], "hidden": [], "hubs": [], "orphans": []}
        baseline = str(root / "baseline.json")
        apply_baseline({}, empty, baseline, False, False)
        before = Path(baseline).read_bytes()
        growth = {**empty, "cycles": [["a", "b"]]}
        try:
            apply_baseline({}, growth, baseline, True, False)
        except ValueError:
            pass
        else:
            raise AssertionError("baseline growth accepted")
        assert Path(baseline).read_bytes() == before
        apply_baseline({}, growth, baseline, True, False, rebaseline=True)
        apply_baseline({}, empty, baseline, True, False)
        assert json.loads(Path(baseline).read_text())["cycles"] == []
        tied = {"a": ["b", "c"], "b": ["a", "c"], "c": ["a", "b"],
                "d": ["e"], "e": ["d"], "f": ["g"], "g": ["f"]}
        for prefix in ("s", "t"):
            tied.update({prefix: [prefix + "v"], prefix + "v": [prefix + str(i) for i in range(3)],
                         prefix + "u1": [prefix], prefix + "u2": [prefix],
                         **{prefix + str(i): [] for i in range(3)}})
        write("ties.json", json.dumps(tied))
        outputs = []
        for seed in ("0", "1", "4"):
            outputs.append(subprocess.run(
                [sys.executable, __file__, "--repo", td, "--edges", str(root / "ties.json"), "--top", "1", "--no-git"],
                capture_output=True, text=True, check=True, env={**os.environ, "PYTHONHASHSEED": seed}).stdout)
        assert len(set(outputs)) == 1
        tied_digest = json.loads(outputs[0])
        assert tied_digest["hubs_truncated"] == 2 and tied_digest["cycles_truncated"] == 2
        assert tied_digest["sdp_truncated"] == 1 and tied_digest["sdp_violations"][0]["from"] == "s"
        layered = {f"{i}/{j}": [f"{i+1}/{k}" for k in range(6)] if i < 9 else []
                   for i in range(10) for j in range(6)}
        assert compute_graph_metrics(layered, 1)["summary"]["propagation_cost"] == round(1680 / 3600, 3)

    with tempfile.TemporaryDirectory(prefix="git-test-", dir=work) as td:
        root = Path(td)
        subprocess.run(["git", "-c", "core.fsmonitor=false", "init", "-q", td], check=True)
        env = {**os.environ, "GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_NOSYSTEM": "1",
               "GIT_AUTHOR_NAME": "Alice", "GIT_AUTHOR_EMAIL": "alice@example.invalid",
               "GIT_COMMITTER_NAME": "Alice", "GIT_COMMITTER_EMAIL": "alice@example.invalid"}

        def git(*args):
            return subprocess.run(["git", "-C", td, *args], capture_output=True, text=True,
                                  check=True, env=env).stdout

        def commit(author_date, committer_date=None):
            env["GIT_AUTHOR_DATE"] = author_date
            env["GIT_COMMITTER_DATE"] = committer_date or author_date
            git("add", ".")
            git("-c", "commit.gpgsign=false", "commit", "-qm", "fixture")

        git("init", "-q")
        ring = {f"a{i:02}.py": [f"a{(i+1)%13:02}.py"] for i in range(13)}
        odd = ["tab\tname.py", "line\nname.py", "back\\name.py", "space name.py"]
        for name in [*ring, *odd]:
            write(name, "x=0\n")
        commit("2020-01-01T00:00:00Z")
        write("a12.py", "x=1\n")
        write("line\nname.py", "x=1\n")
        commit("2026-09-01T00:00:00Z")
        assert "line\nname.py" in changed_scope(td, "HEAD~1", ring, False)[0]
        write("edges.json", json.dumps(ring))
        digest = run(td, "auto", str(root / "edges.json"), 30, False)
        assert digest["cycles"][0]["truncated"] == 1
        assert digest["cycles"][0]["last_active"] == "2026-09-01"
        assert set(odd) <= {h["file"] for h in digest["git"]["hotspots"]}
        assert digest["git"]["enrichment"]["skipped"] == 7
        git("mv", odd[0], "renamed\tfile.py")
        commit("2026-09-02T00:00:00Z")
        signals = git_signals(td, set(ring), ring, 30)
        assert signals["_alias"][odd[0]] == "renamed\tfile.py"
        assert next(h for h in signals["hotspots"] if h["file"] == "renamed\tfile.py")["commits"] == 2
        write("a12.py", "x=2\n")
        commit("2020-01-01T00:00:00Z", "2026-09-03T00:00:00Z")
        signals = git_signals(td, set(ring), ring, 30)
        assert signals["_last_touched"]["a12.py"] == "2026-09-01"
        assert not signals["knowledge"]["stale_ownership"]
        for i in range(4):
            for name in ["mass_a.py", "mass_b.py", *[f"doc{j}.md" for j in range(21)]]:
                write(name, f"x={i}\n")
            commit(f"2026-09-{4+i:02}T00:00:00Z")
        mass = {"mass_a.py": [], "mass_b.py": []}
        signals = git_signals(td, set(mass), mass, 1, max_commits=4)
        assert not signals["hidden_coupling"] and not signals["co_change_top"]
        assert signals["_stats"]["median_files_per_commit"] == 23
        assert signals["hotspots_truncated"] == 1
        original = subprocess.run
        queries = []

        def recording(command, **kwargs):
            if "-p" in command:
                queries.append((command, kwargs["input"]))
            return original(command, **kwargs)

        with patch.object(subprocess, "run", side_effect=recording):
            signals = git_signals(td, set(mass), mass, 1, max_commits=2)
        expected = set(git("log", "--no-merges", "--max-count=2", "--format=%H").splitlines())
        assert queries and all("--no-walk=unsorted" in cmd and set(data.splitlines()) == expected
                               for cmd, data in queries)
        assert signals["enrichment"]["completed"] == 1

        def timeout(command, **kwargs):
            if "-p" in command:
                raise subprocess.TimeoutExpired(command, 20)
            return original(command, **kwargs)

        with patch.object(subprocess, "run", side_effect=timeout):
            signals = git_signals(td, set(mass), mass, 1)
        assert signals["enrichment"]["timed_out"] == 1
        assert signals["enrichment"]["completed"] == 0
        git("config", "remote.origin.partialclonefilter", "blob:none")
        signals = git_signals(td, set(ring), ring, 30)
        assert signals["enrichment"]["attempted"] == 0
        assert signals["enrichment"]["skip_reason"] == "partial clone"
        assert "renamed\tfile.py" in signals["_last_touched"]


def self_test():
    import tempfile
    # cycle a<->b, hub h, orphan o
    adj = {"a": ["b"], "b": ["a"], "h": ["a", "b"], "c": ["h"], "d": ["h"], "o": []}
    g = compute_graph_metrics(adj, top=10)
    assert g["summary"]["cycle_count"] == 1 and sorted(g["cycles"][0]["members"]) == ["a", "b"]
    assert g["orphans"] == ["o"]
    assert not g["summary"]["acyclic"]
    assert g["cycles"][0]["example_path"] in ("a → b → a", "b → a → b")
    hub = {x["id"]: x for x in g["hubs"]}
    assert "h" in hub and hub["h"]["fan_in"] == 2 and hub["h"]["fan_out"] == 2
    # self-loop counts as cycle
    g_sl = compute_graph_metrics({"a": ["a"], "b": ["a"]}, 10)
    assert g_sl["summary"]["cycle_count"] == 1 and not g_sl["summary"]["acyclic"]
    # SDP violation fires — but not for barrel facades
    g2 = compute_graph_metrics({"stable": ["volatile"], "u1": ["stable"], "u2": ["stable"],
                                "volatile": ["x1", "x2", "x3"], "x1": [], "x2": [], "x3": []}, 10)
    assert any(v["from"] == "stable" and v["to"] == "volatile" for v in g2["sdp_violations"])
    g3 = compute_graph_metrics({"p/__init__.py": ["volatile"], "u1": ["p/__init__.py"],
                                "u2": ["p/__init__.py"], "volatile": ["x1", "x2", "x3"],
                                "x1": [], "x2": [], "x3": []}, 10)
    assert not g3["sdp_violations"]
    # folder_span: cross-folder cycle = 2, same-folder = 1
    g4 = compute_graph_metrics({"a/x.py": ["b/y.py"], "b/y.py": ["a/x.py"],
                                "a/p.py": ["a/q.py"], "a/q.py": ["a/p.py"]}, 10)
    spans = sorted(c["folder_span"] for c in g4["cycles"])
    assert spans == [1, 2]
    # propagation cost: chain a->b->c reach 3+2+1=6, n²=9
    g5 = compute_graph_metrics({"a": ["b"], "b": ["c"], "c": []}, 10)
    assert g5["summary"]["propagation_cost"] == round(6 / 9, 3)
    # PR scope filters BEFORE top-N caps (codex M1): big out-of-scope cycle
    # must not shadow the in-scope one at top=1
    g6 = compute_graph_metrics({"a": ["b"], "b": ["c"], "c": ["a"],
                                "x": ["y"], "y": ["x"]}, top=1, scope={"x", "y"})
    assert g6["summary"]["cycle_count"] == 1 and g6["cycles"][0]["members"] == ["x", "y"]
    # levelization: cycle a->b->c->a + d->a: exactly one feedback edge,
    # layering 1 - 1/4; acyclic graph scores 1.0 with no feedback edges
    g7 = compute_graph_metrics({"a": ["b"], "b": ["c"], "c": ["a"], "d": ["a"]}, 10)
    assert len(g7["feedback_edges"]) == 1 and g7["summary"]["layering_score"] == 0.75
    fe = g7["feedback_edges"][0]
    assert (fe["from"], fe["to"]) in {("a", "b"), ("b", "c"), ("c", "a")}
    assert g5["summary"]["layering_score"] == 1.0 and g5["feedback_edges"] == []
    # folder cohesion: unrelated triple flagged, connected triple not
    adj_fc = {"g/a.py": [], "g/b.py": [], "g/c.py": [],
              "h/x.py": ["h/y.py"], "h/y.py": ["h/z.py"], "h/z.py": []}
    fc = folder_cohesion(adj_fc, co2=set(), top=5)
    assert [f["folder"] for f in fc] == ["g"] and fc[0]["cohesion"] == 0.0
    fc2 = folder_cohesion(adj_fc, co2={("g/a.py", "g/b.py"), ("g/a.py", "g/c.py"),
                                       ("g/b.py", "g/c.py")}, top=5)
    assert fc2 == []  # co-change relations rescue the folder
    # tier-3 trigger detectors: each fires on its exact condition, not otherwise
    base_d = {"summary": {"nodes": 100}, "git": {"hidden_truncated": 0}}
    assert detect_tier3_triggers(base_d, None) == []
    assert any("bitset" in t for t in
               detect_tier3_triggers({"summary": {"nodes": 3001}}, None))
    st_sparse = {"commits": 300, "median_files_per_commit": 1, "big_commit_share": 0.0, "max_co": 2}
    assert any("windowing" in t for t in detect_tier3_triggers(base_d, st_sparse))
    st_tangled = {"commits": 300, "median_files_per_commit": 8, "big_commit_share": 0.4, "max_co": 9}
    d_overflow = {"summary": {"nodes": 100}, "git": {"hidden_truncated": 3}}
    assert any("damping" in t for t in detect_tier3_triggers(d_overflow, st_tangled))
    assert not any("damping" in t for t in detect_tier3_triggers(base_d, st_tangled))
    d_base = {"summary": {"nodes": 5}, "baseline": {"status": "compared"}}
    assert any("velocity" in t for t in detect_tier3_triggers(d_base, None))
    # tarjan on mixed graph
    sccs = tarjan_sccs({"x": ["y"], "y": ["z"], "z": ["x", "w"], "w": []})
    assert sorted(len(s) for s in sccs) == [1, 3]
    # decay: canonical bugspots — 0.5 at newest, ~0 at oldest
    assert 0.49 < _decay(1.0) <= 0.5 and _decay(0.0) < 0.001
    # numstat rename forms
    assert _split_rename("src/{a.py => b.py}") == ("src/a.py", "src/b.py")
    assert _split_rename("a.py => b.py") == ("a.py", "b.py")
    assert _split_rename("plain.py") == (None, "plain.py")
    with tempfile.TemporaryDirectory(dir=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))) as td:
        # DOT: chained edges + owns filtering
        p = os.path.join(td, "g.dot")
        Path(p).write_text('digraph {\n"a" -> "b" -> "c" [label="uses"];\n'
                           '"c" -> "a" [label="uses"];\n"a" -> "a::f" [label="owns"];\n}')
        e = parse_edges_file(p)
        assert e["a"] == ["b"] and e["b"] == ["c"] and e["c"] == ["a"]
        assert "a::f" not in e.get("a", []) and not compute_graph_metrics(e, 5)["summary"]["acyclic"]
        # depcruise shape
        p2 = os.path.join(td, "dc.json")
        Path(p2).write_text(json.dumps({"modules": [{"source": "src/a.js",
                                "dependencies": [{"resolved": "src/b.js"},
                                                 {"resolved": "lodash", "couldNotResolve": True}]}],
                   "summary": {}}))
        assert parse_edges_file(p2) == {"src/a.js": ["src/b.js"]}
        # lakos-ish: leading-slash ids + string node list
        p3 = os.path.join(td, "lk.json")
        Path(p3).write_text(json.dumps({"nodes": ["/lib/a.dart", "/lib/iso.dart"],
                   "edges": [{"from": "/lib/a.dart", "to": "/lib/b.dart"}]}))
        e3 = parse_edges_file(p3)
        assert e3["lib/a.dart"] == ["lib/b.dart"] and "lib/iso.dart" in e3
        # madge dup deps deduped
        p4 = os.path.join(td, "m.json")
        Path(p4).write_text(json.dumps({"a": ["b", "b"]}))
        assert parse_edges_file(p4) == {"a": ["b"]}
        # TYPE_CHECKING imports excluded; else-branch imports NOT counted (codex m6)
        os.makedirs(os.path.join(td, "pkg"))
        Path(td, "pkg", "a.py").write_text(
            "import typing as t\nif t.TYPE_CHECKING:\n    from pkg.b import B\n"
            "else:\n    import os\n")
        Path(td, "pkg", "b.py").write_text("from pkg.a import A\n")
        extract_python.type_only = 0
        e5 = extract_python(td, ["pkg/a.py", "pkg/b.py"])
        assert e5["pkg/a.py"] == [] and e5["pkg/b.py"] == ["pkg/a.py"]
        assert extract_python.type_only == 1
        # baseline v2: create then compare with one fixed + one new sdp
        bp = os.path.join(td, "base.json")
        raw_a = {"cycles": [["a", "b"]], "sdp": [("s", "v")], "hidden": [("x", "y")],
                 "hubs": ["h"], "orphans": []}
        d1 = {"cycles": [], "sdp_violations": [], "hubs": [], "orphans": []}
        apply_baseline(d1, raw_a, bp, False, False)
        assert d1["baseline"]["status"] == "created" and json.loads(Path(bp).read_text())["version"] == 2
        raw_b = {"cycles": [["a", "b"]], "sdp": [("s2", "v2")], "hidden": [("x", "y")],
                 "hubs": ["h"], "orphans": []}
        d2 = {"cycles": [], "sdp_violations": [{"from": "s2", "to": "v2"}],
              "hubs": [], "orphans": [], "git": {"hidden_coupling": []}}
        apply_baseline(d2, raw_b, bp, False, False)
        diff = d2["baseline"]["diff"]
        assert diff["sdp"] == {"new": 1, "known": 0, "fixed": 1}
        assert diff["cycles"]["known"] == 1 and diff["hidden"]["known"] == 1
        assert d2["sdp_violations"][0]["baseline"] == "new"
        # rename-following (refuted-plan C6): baseline holds OLD paths; alias
        # maps them to current names — a pure move must read as known
        raw_moved = {"cycles": [["sub/a.py", "b.py"]], "sdp": [], "hidden": [],
                     "hubs": [], "orphans": []}
        bp2 = os.path.join(td, "b2.json")
        apply_baseline({}, {"cycles": [["a.py", "b.py"]], "sdp": [], "hidden": [],
                            "hubs": [], "orphans": []}, bp2, False, False)
        d_mv = {"cycles": [], "sdp_violations": [], "hubs": [], "orphans": []}
        apply_baseline(d_mv, raw_moved, bp2, False, False, alias={"a.py": "sub/a.py"})
        assert d_mv["baseline"]["diff"]["cycles"] == {"new": 0, "known": 1, "fixed": 0}
        # without the alias the same move would (wrongly) read new+fixed
        d_mv2 = {"cycles": [], "sdp_violations": [], "hubs": [], "orphans": []}
        apply_baseline(d_mv2, raw_moved, bp2, False, False)
        assert d_mv2["baseline"]["diff"]["cycles"]["new"] == 1
        # PR mode: fixed indeterminable; refresh refused even on diff failure (codex M2)
        d3 = {"cycles": [], "sdp_violations": [], "hubs": [], "orphans": [],
              "git": {"hidden_coupling": []}}
        apply_baseline(d3, raw_b, bp, False, True)
        assert d3["baseline"]["diff"]["sdp"]["fixed"] is None
        before = Path(bp).read_text()
        d4 = {}
        apply_baseline(d4, raw_a, bp, True, True)
        assert "baseline" not in d4 and Path(bp).read_text() == before
    regression_tests()
    print("self-test OK")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=".")
    ap.add_argument("--lang", default="auto", choices=["auto", "python"])
    ap.add_argument("--edges", help="madge/depcruise/lakos JSON or DOT file from an external extractor")
    ap.add_argument("--top", type=int, default=10)
    ap.add_argument("--no-git", action="store_true")
    ap.add_argument("--include-tests", action="store_true",
                    help="include test/generated files (excluded by default)")
    ap.add_argument("--changed", metavar="BASE_REF",
                    help="PR mode: scope findings to files changed since BASE_REF + 1-hop neighbors")
    ap.add_argument("--baseline", metavar="FILE",
                    help="ratchet file: created if missing, else findings marked new/known/fixed")
    ap.add_argument("--refresh-baseline", action="store_true",
                    help="rewrite the baseline file from current findings")
    ap.add_argument("--rebaseline", action="store_true", help="allow baseline growth with --refresh-baseline")
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.top <= 0:
        ap.error("--top must be positive")
    if a.rebaseline and not (a.baseline and a.refresh_baseline):
        ap.error("--rebaseline requires --baseline and --refresh-baseline")
    if a.self_test:
        self_test()
        sys.exit(0)
    print(json.dumps(run(a.repo, a.lang, a.edges, a.top, a.no_git, a.include_tests,
                         a.changed, a.baseline, a.refresh_baseline, a.rebaseline), indent=1))
