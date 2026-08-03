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

# ---------------------------------------------------------------- extraction

CODE_EXTS = {".py", ".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs", ".dart",
             ".rs", ".go", ".java", ".kt", ".rb", ".php", ".cs", ".swift"}

# Tests inflate fan_in and dominate churn; generated files dominate hotspots.
# Excluded by default from graph AND git signals (--include-tests disables).
TEST_GEN_RE = re.compile(
    r"(^|/)(tests?|__tests__|spec|specs|__generated__|generated|testdata)/"
    r"|_test\.|\.test\.|\.spec\.|_spec\.|Test\.java|Tests?\.cs"
    r"|\.g\.dart|\.freezed\.dart|_pb2\.py|\.pb\.go|_generated\.|\.min\.js")

BOT_AUTHOR_RE = re.compile(r"\[bot\]|dependabot|renovate|github-actions", re.I)

# Barrel facades have max fan_in + re-export instability by design; as the
# "stable" side of an SDP check they're pure noise (measured: 43/60 findings
# on sqlalchemy were __init__.py artifacts).
BARREL_RE = re.compile(r"(^|/)(__init__\.py|index\.(jsx?|tsx?|mjs|cjs))$")


def is_excluded(path, include_tests):
    return not include_tests and TEST_GEN_RE.search(path)


def list_files(repo, include_tests=False):
    try:
        out = subprocess.run(["git", "-c", "core.quotepath=off", "-C", repo, "ls-files"],
                             capture_output=True, text=True, check=True).stdout.splitlines()
    except (subprocess.CalledProcessError, FileNotFoundError):
        out = []
        for root, dirs, files in os.walk(repo):
            dirs[:] = [d for d in dirs if d not in
                       {".git", "node_modules", "build", "dist", "target", ".dart_tool", "__pycache__", "venv", ".venv"}]
            for f in files:
                out.append(os.path.relpath(os.path.join(root, f), repo))
    return [f for f in out if os.path.splitext(f)[1] in CODE_EXTS
            and not is_excluded(f, include_tests)]


STDLIB = set(getattr(sys, "stdlib_module_names", ()))


def _runtime_nodes(tree):
    """Walk the AST skipping `if TYPE_CHECKING:` bodies — type-only imports
    aren't runtime edges (they fabricate SDP violations and inflate cycles;
    confirmed on flask and click). Returns (nodes, skipped_import_count)."""
    nodes, skipped, stack = [], 0, [tree]
    while stack:
        node = stack.pop()
        nodes.append(node)
        for child in ast.iter_child_nodes(node):
            if isinstance(child, ast.If):
                t = child.test
                name = t.attr if isinstance(t, ast.Attribute) else getattr(t, "id", None)
                if name == "TYPE_CHECKING":
                    skipped += sum(1 for stmt in child.body for n in ast.walk(stmt)
                                   if isinstance(n, (ast.Import, ast.ImportFrom)))
                    stack.extend(child.orelse)  # else-branch runs at runtime
                    continue
            stack.append(child)
    return nodes, skipped


def extract_python(repo, files):
    """Resolve python imports to repo-relative file paths via ast.
    Ambiguous or stdlib-colliding names dropped; TYPE_CHECKING imports excluded."""
    pyfiles = [f for f in files if f.endswith(".py")]
    suffix_owners = defaultdict(set)  # dotted suffix -> candidate files
    for f in pyfiles:
        dotted = f[:-3].replace(os.sep, ".")
        dotted = dotted[:-9] if dotted.endswith(".__init__") else dotted
        parts = dotted.split(".")
        for i in range(len(parts)):
            suffix_owners[".".join(parts[i:])].add(f)
    mod_map = {k: next(iter(v)) for k, v in suffix_owners.items()
               if len(v) == 1 and k.split(".")[0] not in STDLIB}
    edges = defaultdict(set)
    for f in pyfiles:
        try:
            tree = ast.parse(open(os.path.join(repo, f), encoding="utf-8", errors="replace").read())
        except (SyntaxError, ValueError, OSError):
            continue
        pkg_parts = f[:-3].replace(os.sep, ".").split(".")[:-1]
        rt_nodes, skipped = _runtime_nodes(tree)
        extract_python.type_only += skipped
        for node in rt_nodes:
            names = []
            if isinstance(node, ast.Import):
                names = [a.name for a in node.names]
            elif isinstance(node, ast.ImportFrom):
                if node.level:  # relative import
                    if node.level > len(pkg_parts) + 1:
                        continue
                    base = pkg_parts[:len(pkg_parts) - node.level + 1]
                    mod = ".".join(base + (node.module.split(".") if node.module else []))
                    names = [mod] + [mod + "." + a.name for a in node.names]
                elif node.module:
                    names = [node.module] + [node.module + "." + a.name for a in node.names]
            for n in names:
                tgt = mod_map.get(n)
                if tgt and tgt != f:
                    edges[f].add(tgt)
    return {f: sorted(edges.get(f, ())) for f in pyfiles}


extract_python.type_only = 0  # reset by run(); accumulated per extraction


def parse_edges_file(path):
    """Accept madge JSON ({mod: [deps]}), depcruise JSON ({modules:[...]}),
    lakos/generic JSON ({nodes, edges:[{from,to}]}), or graphviz DOT."""
    text = open(path, encoding="utf-8").read()
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        # DOT. Chains ("a" -> "b" -> "c") pair consecutively; containment
        # (label="owns", cargo-modules) is not a dependency — skip it.
        edges = defaultdict(set)
        for stmt in re.split(r"[;\n]", text):
            if "->" not in stmt or 'label="owns"' in stmt:
                continue
            ids = re.findall(r'"([^"]+)"', stmt.split("[")[0])
            for a, b in zip(ids, ids[1:]):
                if a != b:
                    edges[a].add(b)
        return {k: sorted(v) for k, v in edges.items()}
    norm = lambda s: s.lstrip("/")  # lakos ids lead with '/'
    if isinstance(data, dict) and "modules" in data:  # dependency-cruiser
        edges = defaultdict(set)
        for m in data["modules"]:
            edges[norm(m["source"])].update(
                norm(d["resolved"]) for d in m.get("dependencies", ())
                if not d.get("couldNotResolve"))
        return {k: sorted(v) for k, v in edges.items()}
    if isinstance(data, dict) and "edges" in data:  # lakos / generic
        edges = defaultdict(set)
        nodes = data.get("nodes") or {}
        node_ids = (list(nodes) if isinstance(nodes, dict)
                    else [n.get("id") if isinstance(n, dict) else n for n in nodes])
        for e in data["edges"]:
            edges[norm(e["from"])].add(norm(e["to"]))
        for n in node_ids:
            if n:
                edges.setdefault(norm(n), set())
        return {k: sorted(v) for k, v in edges.items()}
    if isinstance(data, dict):  # madge adjacency
        return {norm(k): sorted({norm(x) for x in v}) for k, v in data.items()}
    raise ValueError("unrecognized edges format")


def align_to_git(adj, repo, include_tests):
    """Rename external-graph node ids to repo-relative git paths where a unique
    suffix match exists (madge scanned a subdir, lakos paths, etc.). The git
    join is load-bearing: hidden_coupling dies silently without it."""
    gitfiles = list_files(repo, include_tests)
    fileset = set(gitfiles)
    by_suffix = defaultdict(list)
    for f in gitfiles:
        parts = f.split("/")
        for i in range(len(parts)):
            by_suffix["/".join(parts[i:])].append(f)
    rename, matched = {}, 0
    nodes = set(adj) | {d for v in adj.values() for d in v}
    for n in nodes:
        if n in fileset:
            rename[n] = n; matched += 1
        else:
            hits = by_suffix.get(n, [])
            if len(hits) == 1:
                rename[n] = hits[0]; matched += 1
            else:
                rename[n] = n
    new_adj = defaultdict(set)
    for k, deps in adj.items():
        new_adj[rename[k]].update(rename[d] for d in deps)
    rate = matched / len(nodes) if nodes else 0.0
    return {k: sorted(v) for k, v in new_adj.items()}, round(rate, 2)

# ------------------------------------------------------------------- metrics

def tarjan_sccs(adj):
    """Iterative Tarjan. Returns list of SCCs (each a list of nodes)."""
    index, low, on_stack = {}, {}, set()
    stack, sccs, counter = [], [], [0]
    for root in adj:
        if root in index:
            continue
        work = [(root, iter(adj.get(root, ())))]
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
                    work.append((nxt, iter(adj.get(nxt, ()))))
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
    nodes = set(adj)
    for deps in adj.values():
        nodes.update(deps)
    adj = {n: sorted({d for d in adj.get(n, ()) if d in nodes}) for n in nodes}
    fan_out = {n: len(adj[n]) for n in nodes}
    fan_in = Counter()
    for n, deps in adj.items():
        for d in deps:
            fan_in[d] += 1
    edge_count = sum(fan_out.values())

    # cycles: SCCs of size >1, plus self-loops (possible via --edges input)
    sccs = [s for s in tarjan_sccs(adj) if len(s) > 1 or s[0] in adj[s[0]]]
    sccs.sort(key=len, reverse=True)
    cycle_nodes = {n for s in sccs for n in s}

    inst = {n: (fan_out[n] / (fan_in[n] + fan_out[n])) if fan_in[n] + fan_out[n] else None
            for n in nodes}

    def deg(n):
        return fan_in[n] + fan_out[n]
    # hub floor >=2/>=2 plus p90 degree cutoff (Arcan uses benchmark-derived
    # thresholds; a repo-relative percentile is the honest cheap equivalent)
    degs = sorted(deg(n) for n in nodes)
    p90 = degs[int(0.9 * (len(degs) - 1))] if len(degs) >= 20 else 0
    hubs_all = sorted((n for n in nodes
                       if fan_in[n] >= 2 and fan_out[n] >= 2 and deg(n) >= p90),
                      key=deg, reverse=True)
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
    sdp.sort(key=lambda e: (e["from_fan_in"], e["delta"]), reverse=True)

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
        succ = {n: set(adj[n]) for n in nodes}
        pred = defaultdict(set)
        for n, ds in adj.items():
            for d in ds:
                pred[d].add(n)
        remaining, s1, s2 = set(nodes), [], []
        while remaining:
            moved = True
            while moved:
                moved = False
                for n in [x for x in remaining if not (succ[x] & remaining - {x})]:
                    s2.append(n); remaining.discard(n); moved = True
                for n in [x for x in remaining if not (pred[x] & remaining - {x})]:
                    s1.append(n); remaining.discard(n); moved = True
            if remaining:  # break a cycle: node with max out-in degree delta
                n = max(remaining, key=lambda x: len(succ[x] & remaining) - len(pred[x] & remaining))
                s1.append(n); remaining.discard(n)
        order = {n: i for i, n in enumerate(s1 + list(reversed(s2)))}
        feedback = sorted(({"from": n, "to": d, "span": order[n] - order[d]}
                           for n in nodes for d in adj[n] if order[d] <= order[n]),
                          key=lambda e: e["span"], reverse=True)
        layering = round(1 - len(feedback) / edge_count, 3)
        if scope is not None:  # layering_score stays whole-graph; edges scoped
            feedback = [e for e in feedback if e["from"] in scope or e["to"] in scope]

    nccd = pc = None
    if 1 < len(nodes) <= 3000:  # ponytail: O(V*E) BFS closure; skip on huge graphs
        ccd = 0
        for n in nodes:
            seen, frontier = {n}, [n]
            while frontier:
                nxt = [d for f in frontier for d in adj[f] if d not in seen]
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
        # cut these imports and the graph becomes layerable; span = how far
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
            capture_output=True, text=True).stdout.strip()
        stat_flag = "--name-status" if partial else "--numstat"
        out = subprocess.run(
            ["git", "-c", "core.quotepath=off", "-C", repo, "log", "--no-merges",
             stat_flag, "-M", "--format=%x00%an%x00%at",
             f"--max-count={max_commits}"],
            capture_output=True, text=True, check=True).stdout
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

    commits, author, epoch, files = [], None, None, []
    for line in out.splitlines() + ["\x00"]:
        if line.startswith("\x00"):
            if files and author is not None and not BOT_AUTHOR_RE.search(author):
                commits.append((author, epoch, files))
            parts = line.split("\x00")
            author = parts[1] if len(parts) > 1 else ""
            try:
                epoch = int(parts[2])
            except (IndexError, ValueError):
                epoch = None
            files = []
        elif line.strip():
            m = re.match(r"^(\d+|-)\t(\d+|-)\t(.+)$", line)
            if m:  # numstat
                add, dele, path = m.groups()
                lines = (0 if add == "-" else int(add)) + (0 if dele == "-" else int(dele))
                old, new = _split_rename(path)
            else:  # name-status: "M\tpath" or "R100\told\tnew"
                cols = line.split("\t")
                if len(cols) < 2 or not re.match(r"^[A-Z]\d*$", cols[0]):
                    continue
                lines = 0
                if cols[0][0] in "RC" and len(cols) >= 3:
                    old, new = cols[1], cols[2]
                else:
                    old, new = None, cols[-1]
            if old:
                alias[old] = cur(new)
            path = cur(new)
            if os.path.splitext(path)[1] in CODE_EXTS and not is_excluded(path, include_tests):
                files.append((path, lines))

    epochs = [e for _, e, _ in commits if e is not None]
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
    for who, e, fs in commits:      # import): decay meaningless, weight uniformly
        w = 1.0 if (e is None or flat_window) else _decay((e - lo) / span)
        if e is not None and who not in author_last:
            author_last[who] = e  # newest-first: first hit = latest activity
        for f, ln in fs:
            churn[f] += 1; decayed[f] += w; line_churn[f] += ln
            authors[f][who] += 1
            first_author[f] = who  # keeps overwriting -> oldest wins
            if e is not None and e >= recent_cut:
                recent_w[f] += w
            if f not in last_touched and e is not None:
                last_touched[f] = e  # newest-first: first hit wins
        names = sorted({f for f, _ in fs})
        if len(names) <= max_files_per_commit:  # skip mass renames/reformats
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
    for f, dw in sorted(candidates, key=lambda kv: kv[1], reverse=True)[:top * 10]:
        p = os.path.join(repo, f)
        if not os.path.isfile(p):
            continue  # deleted since
        loc = indent = 0
        try:
            for line_ in open(p, encoding="utf-8", errors="replace"):
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
    hotspots.sort(key=lambda h: h["score"], reverse=True)
    hot_files = {h["file"] for h in hotspots[:top]}

    # hot functions: which functions inside the top hotspots take the churn —
    # converts "read this 3000-line file" into "read these 3 functions".
    # Parsed from `git log -p` hunk headers (git's xfuncname context). Skipped
    # on partial clones (-p would lazy-fetch blobs).
    if not partial:
        hunk_re = re.compile(r"^@@[^@]*@@ (.+)$", re.M)
        def_re = re.compile(r"(?:def|class|function|fn|func|interface|struct|impl)\s+([A-Za-z_][\w$]*)")
        call_re = re.compile(r"([A-Za-z_][\w$]*)\s*\(")
        for h in hotspots[:min(10, top)]:
            try:
                logp = subprocess.run(
                    ["git", "-c", "core.quotepath=off", "-C", repo, "log",
                     "--no-merges", "-p", "--format=", "-M", "--max-count=300",
                     "--", h["file"]],
                    capture_output=True, text=True, timeout=20).stdout
            except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
                continue
            names = Counter()
            for ctx in hunk_re.findall(logp):
                m = def_re.search(ctx) or call_re.search(ctx)
                if m:
                    names[m.group(1)] += 1
            if names:
                h["hot_functions"] = [{"name": n, "touches": c}
                                      for n, c in names.most_common(5)]

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
        removed.add(counts.most_common(1)[0][0]); tf += 1
    departed = {a for a, e in author_last.items() if e < hi - 365 * 86400}
    islands = sorted((f for f, s in doa_authors.items()
                      if len(s) == 1 and (scope is None or f in scope)),
                     key=lambda f: decayed[f], reverse=True)
    stale = sorted(
        ({"file": f, "departed_share": round(
            sum(c for a, c in authors[f].items() if a in departed) / sum(authors[f].values()), 2)}
         for f in authors
         if (scope is None or f in scope)
         and sum(c for a, c in authors[f].items() if a in departed) * 2
             > sum(authors[f].values())),
        key=lambda x: x["departed_share"], reverse=True)
    knowledge = {
        "truck_factor": tf,
        "islands": [{"file": f, "owner": next(iter(doa_authors[f])),
                     "is_hotspot": f in hot_files} for f in islands[:top]],
        "islands_truncated": max(0, len(islands) - top),
        "stale_ownership": stale[:top],
        "note": ("DOA over the analyzed window only; departed = no commit in "
                 "12 months within window"),
    }

    edge_pairs = set()
    for n, deps in adj.items():
        for d in deps:
            edge_pairs.add((n, d)); edge_pairs.add((d, n))
    hidden = []
    for (a, b), c in co.most_common():
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
    sizes = sorted(len(fs) for _, _, fs in commits)
    stats = {
        "commits": len(commits),
        "median_files_per_commit": sizes[len(sizes) // 2] if sizes else 0,
        "big_commit_share": (round(sum(1 for n in sizes if 10 < n <= max_files_per_commit)
                                   / len(sizes), 2) if sizes else 0.0),
        "max_co": co.most_common(1)[0][1] if co else 0,
    }
    return {
        "commits_analyzed": len(commits), "commits_cap": max_commits,
        **({"line_churn_note": "lines_churned unavailable (blobless partial clone "
            "— numstat would lazy-fetch every blob)"} if partial else {}),
        "git_join": (round(churned_in_graph / len(churn), 2) if churn else None),
        "score_formula": ("hotspot score = decayed_commit_weight (canonical bugspots "
                          "sigmoid: newest≈0.5, most weight in last ~fifth of window) "
                          "× (loc + indent_units); recent_share = share of decayed "
                          "weight from last 90 days; scored from the top-10×N files "
                          "by decayed weight"),
        "hotspots": hotspots[:top],
        "co_change_top": [{"a": a, "b": b, "co_commits": c}
                          for (a, b), c in co.most_common()
                          if scope is None or a in scope or b in scope][:top],
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
    out.sort(key=lambda x: x["cohesion"])
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


def apply_baseline(digest, raw, path, refresh, pr_mode, alias=None):
    """raw = uncapped finding material: {cycles: [[members]], sdp: [(a,b)],
    hidden: [(a,b)], hubs: [ids], orphans: [ids]}. alias = git rename map
    (old path -> current path) applied to BASELINE entries at compare time."""
    if refresh or not os.path.exists(path):
        if pr_mode:  # includes failed --changed refs: intent decides, not diff success
            digest.setdefault("warnings", []).append(
                "baseline not written in PR mode (scoped run would freeze a partial view)")
            return
        json.dump({"version": 2, **raw}, open(path, "w"), indent=1)
        digest["baseline"] = {"status": "refreshed" if refresh else "created", "path": path}
        return
    base = json.load(open(path))
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
             "--name-only", f"{base_ref}...HEAD"],
            capture_output=True, text=True, check=True).stdout.splitlines()
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
        changed=None, baseline=None, refresh_baseline=False):
    if edges_file:
        raw = parse_edges_file(edges_file)
        raw, match_rate = align_to_git(raw, repo, include_tests)
        source = f"external:{edges_file}"
    else:
        files = list_files(repo, include_tests)
        py = [f for f in files if f.endswith(".py")]
        if py and (lang == "python" or len(py) >= len(files) * 0.2):
            extract_python.type_only = 0
            raw = extract_python(repo, py)
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
    digest = {"extractor": source, **g}
    if source.startswith("builtin:python") and extract_python.type_only:
        digest["summary"]["type_only_imports_excluded"] = extract_python.type_only
    warnings = []
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
                lows = folder_cohesion(adj, co2, top, scope_files)
                if lows:
                    digest["low_cohesion_folders"] = lows
            lt = git.pop("_last_touched")
            for c in digest["cycles"]:
                dates = [lt[m] for m in c["members"] if m in lt]
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
        apply_baseline(digest, raw_ids, baseline, refresh_baseline, pr_mode, alias)

    triggers = detect_tier3_triggers(digest, git_stats)
    if triggers:
        digest["tier3_triggers"] = triggers
    return digest


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
    with tempfile.TemporaryDirectory() as td:
        # DOT: chained edges + owns filtering
        p = os.path.join(td, "g.dot")
        open(p, "w").write('digraph {\n"a" -> "b" -> "c" [label="uses"];\n'
                           '"c" -> "a" [label="uses"];\n"a" -> "a::f" [label="owns"];\n}')
        e = parse_edges_file(p)
        assert e["a"] == ["b"] and e["b"] == ["c"] and e["c"] == ["a"]
        assert "a::f" not in e.get("a", []) and not compute_graph_metrics(e, 5)["summary"]["acyclic"]
        # depcruise shape
        p2 = os.path.join(td, "dc.json")
        json.dump({"modules": [{"source": "src/a.js",
                                "dependencies": [{"resolved": "src/b.js"},
                                                 {"resolved": "lodash", "couldNotResolve": True}]}],
                   "summary": {}}, open(p2, "w"))
        assert parse_edges_file(p2) == {"src/a.js": ["src/b.js"]}
        # lakos-ish: leading-slash ids + string node list
        p3 = os.path.join(td, "lk.json")
        json.dump({"nodes": ["/lib/a.dart", "/lib/iso.dart"],
                   "edges": [{"from": "/lib/a.dart", "to": "/lib/b.dart"}]}, open(p3, "w"))
        e3 = parse_edges_file(p3)
        assert e3["lib/a.dart"] == ["lib/b.dart"] and "lib/iso.dart" in e3
        # madge dup deps deduped
        p4 = os.path.join(td, "m.json")
        json.dump({"a": ["b", "b"]}, open(p4, "w"))
        assert parse_edges_file(p4) == {"a": ["b"]}
        # TYPE_CHECKING imports excluded; else-branch imports NOT counted (codex m6)
        os.makedirs(os.path.join(td, "pkg"))
        open(os.path.join(td, "pkg", "a.py"), "w").write(
            "import typing as t\nif t.TYPE_CHECKING:\n    from pkg.b import B\n"
            "else:\n    import os\n")
        open(os.path.join(td, "pkg", "b.py"), "w").write("from pkg.a import A\n")
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
        assert d1["baseline"]["status"] == "created" and json.load(open(bp))["version"] == 2
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
        before = open(bp).read()
        d4 = {}
        apply_baseline(d4, raw_a, bp, True, True)
        assert "baseline" not in d4 and open(bp).read() == before
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
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.self_test:
        self_test()
        sys.exit(0)
    print(json.dumps(run(a.repo, a.lang, a.edges, a.top, a.no_git, a.include_tests,
                         a.changed, a.baseline, a.refresh_baseline), indent=1))
