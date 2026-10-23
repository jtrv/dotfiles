"""PreToolUse hook: ask before a recursive rm that could hit home or an important dir.

Reads the hook payload on stdin. Prints an "ask" decision when any recursive rm in
the command has a target it cannot prove harmless; prints nothing otherwise, which
leaves the call to the normal permission flow. Stdlib only: it runs under whatever
python3 the machine has (guard-rm.sh picks it).

Harmless means one of:
  - strictly inside a temp root (/tmp, /var/tmp, $TMPDIR, $XDG_RUNTIME_DIR);
  - inside $HOME at depth 3 or more (~/repos/proj/build), outside the protected
    trees below, and not a git work tree or a .git dir;
  - inside ~/.cache at depth 2 or more.
Anything it cannot resolve (an unset variable, command substitution, xargs or
find -exec feeding the targets, a quote it cannot parse) asks.
"""

import json
import os
import re
import shlex
import sys
from pathlib import Path

HOME = Path.home()
# Depth alone would let these through: ~/.config/dotfiles is the bare dotfiles repo,
# ~/.local/share holds game installs and keyrings, and the rest hold keys or notes.
PROTECTED = {".config", ".local", ".ssh", ".gnupg", ".password-store", "notes", "documents"}
SEPARATORS = {";", "&&", "||", "|", "&", "(", ")", "\n"}
WRAPPERS = {"sudo", "doas", "command", "builtin", "nice", "nohup", "time", "exec"}
VAR = re.compile(r"\$(\{(\w+)\}|(\w+))")
ASSIGN = re.compile(r"^(\w+)=(.*)$", re.DOTALL)


class Unresolved(Exception):
    pass


def temp_roots() -> list[Path]:
    roots = ["/tmp", "/var/tmp", os.environ.get("TMPDIR"), os.environ.get("XDG_RUNTIME_DIR")]
    return [Path(r).resolve() for r in roots if r]


def expand(word: str, env: dict[str, str]) -> str:
    if "$(" in word or "`" in word or word in {"$", "{}"}:
        raise Unresolved(word)

    def sub(m: re.Match[str]) -> str:
        name = m.group(2) or m.group(3)
        if name not in env or not env[name]:
            raise Unresolved(m.group(0))
        return env[name]

    word = VAR.sub(sub, word)
    if word == "~" or word.startswith("~/"):
        word = str(HOME) + word[1:]
    return word


def resolve(target: str, cwd: Path) -> tuple[Path, bool]:
    """The real path rm would remove, or for a glob the dir it matches inside."""
    parts = Path(target).parts
    glob = False
    for i, part in enumerate(parts):
        if any(c in part for c in "*?["):
            target, glob = (str(Path(*parts[:i])) if i else "."), True
            break
    path = Path(os.path.normpath(cwd / target))
    # rm removes a symlink operand itself, so resolve only its parent.
    return (path.parent.resolve() / path.name if path.name and not glob else path.resolve()), glob


def harmless(path: Path, *, glob: bool) -> bool:
    """A glob only removes entries inside `path`: enough for a temp root, which may
    hold anything, but in $HOME it is judged as removing `path` itself, so
    `rm -rf *` at a repo root still asks. Home rules run first, so a $HOME that
    happens to sit under a temp root never makes `rm -rf ~` a temp cleanup."""
    if HOME.is_relative_to(path):
        return False
    if path.is_relative_to(HOME):
        rel = path.relative_to(HOME).parts
        if path.name == ".git" or (path / ".git").exists():
            return False
        if rel[0] == ".cache":
            return len(rel) >= 2
        return len(rel) >= 3 and rel[0] not in PROTECTED
    return any(path.is_relative_to(root) and (glob or path != root) for root in temp_roots())


def simple_commands(command: str) -> list[list[str]]:
    lexer = shlex.shlex(command.replace("\n", " ; "), posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    commands: list[list[str]] = [[]]
    redirect_target = False
    for token in lexer:
        if redirect_target:
            redirect_target = False
        elif set(token) <= set("<>&|") and set(token) & set("<>"):
            # `2>/dev/null` lexes as `2`, `>`, `/dev/null`: neither neighbour is an operand.
            if commands[-1] and commands[-1][-1].isdigit():
                commands[-1].pop()
            redirect_target = True
        elif token in SEPARATORS or set(token) <= set(";&|()"):
            commands.append([])
        else:
            commands[-1].append(token)
    return [c for c in commands if c]


def is_rm(word: str) -> bool:
    return word == "rm" or word.endswith("/rm")


def rm_targets(words: list[str]) -> list[str] | None:
    """Targets of a recursive rm in this simple command, or None if it has none.

    Only rm in command position counts (`git rm -r` is not this rm), unless a feeder
    like xargs or find -exec runs it, and then its targets are unknowable.
    """
    at = next((i for i, w in enumerate(words) if is_rm(w)), None)
    if at is None:
        return None
    head, args = words[:at], words[at + 1 :]
    feeders = {"xargs", "-exec", "-execdir", "parallel"}
    if head and not feeders & set(head):
        return None
    recursive, targets, end_of_flags = False, [], False
    for arg in args:
        if not end_of_flags and arg == "--":
            end_of_flags = True
        elif not end_of_flags and arg.startswith("--"):
            recursive |= arg == "--recursive"
        elif not end_of_flags and arg.startswith("-") and len(arg) > 1:
            recursive |= "r" in arg or "R" in arg
        else:
            targets.append(arg)
    if not recursive:
        return None
    if head or not targets:
        raise Unresolved("targets come from another command")
    return targets


def verdict(command: str, cwd: Path) -> str | None:
    env = dict(os.environ)
    try:
        for words in simple_commands(command):
            while words and ASSIGN.match(words[0]):
                name, value = ASSIGN.match(words[0]).groups()  # pyright: ignore[reportOptionalMemberAccess]
                try:
                    env[name] = expand(value, env)
                except Unresolved:
                    env.pop(name, None)
                words = words[1:]
            while words and words[0] in WRAPPERS:
                words = words[1:]
            if words[:1] == ["cd"] and len(words) == 2:
                cwd = Path(os.path.normpath(cwd / expand(words[1], env)))
                continue
            for target in rm_targets(words) or []:
                path, glob = resolve(expand(target, env), cwd)
                if not harmless(path, glob=glob):
                    return f"recursive rm of {path}"
    except Unresolved as e:
        return f"recursive rm with a target it cannot resolve ({e})"
    except ValueError as e:
        return f"recursive rm in a command it cannot parse ({e})"
    return None


def main() -> None:
    payload = json.load(sys.stdin)
    command = payload.get("tool_input", {}).get("command") or ""
    cwd = Path(payload.get("cwd") or Path.cwd())
    reason = verdict(command, cwd)
    if reason:
        print(
            json.dumps(
                {
                    "hookSpecificOutput": {
                        "hookEventName": "PreToolUse",
                        "permissionDecision": "ask",
                        "permissionDecisionReason": f"guard-rm: {reason}. Temp dirs and paths 3+ levels"
                        " into $HOME (not .config/.local/keys/notes, not a git repo) pass without asking.",
                    }
                }
            )
        )


if __name__ == "__main__":
    main()
