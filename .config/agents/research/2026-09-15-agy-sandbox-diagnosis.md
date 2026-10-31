## Diagnosis

**The sandbox child dies while installing its proxy CA certificate.** The exact failure was already recorded in [agy.log:164](/tmp/agysbx.mthP/agy.log:164):

```text
sbox: installing certificate: open /etc/ssl/cert.pem: read-only file system
```

The search missed it because the line says `sbox`, not `sandbox`. The same failure appears in 14 additional entries in the default CLI logs.

**Likely underlying cause:** a sandbox filesystem-layout bug involving this machine’s CA-bundle symlinks. Both paths resolve to the same file:

```text
/etc/ssl/cert.pem
/etc/ssl/certs/ca-certificates.crt
    → /etc/ca-certificates/extracted/tls-ca-bundle.pem
```

Both resolve to inode `33:26555668`, mode `0444`. The reported error is **EROFS**, so changing file permissions alone would not fix it.

## Mechanism — verified from binary call sites

Symbols below have prefix `google3/devtools/ai/sandbox/`; addresses are ELF virtual addresses in the inspected binary.

- `exebox.(*Box).initSbox` (`0x71638c0`) calls `os.executable`, constructs a command for **itself**, and adds `_EXEBOX_SBOXSERVE=1`.
- `urpc.socket` (`0x7126740`) calls `syscall.Socketpair(1,1,0)`: **AF_UNIX, SOCK_STREAM, unnamed socketpair**. Thus `@->@` does **not** establish a named abstract socket; there is no stale socket pathname to remove.
- `exebox.(*Box).startSbox` supplies namespace configuration and JSON rules through fd 3.
- `exebox.init.1` dispatches the environment marker to `jailMain`. This builds the mount layout, remounts the root read-only, pivots root, and installs the proxy CA.
- At `0x716158d`, `jailMain` calls `localcert.(*Root).Install`; failure reaches `log.Fatalf` at `0x71615d1`, with `"installing certificate: %v"`.
- Successful startup would then re-exec `/proc/self/exe` with `_EXEBOX_SBOXSERVE=2`, install seccomp/notification hooks, and enter `sbox.Main`. **This run dies before that.**
- The parent’s `"the handshake"` operation consequently receives the reset and wraps it as `"connecting to sandbox server: %w"`.

**Linux support is compiled in:** `exebox_linux.go`, `exebox_unotify.go`, `loadSeccompFilter`, and `installUnotifyHooks`. This is a built-in implementation, not a missing bubblewrap helper or separately installed sandbox daemon.

## Other evidence corrections

- Log-prefix numbers `1` and `261` are **goroutine IDs**, not evidence of two processes: `google3/base/go/log.ctxlogf` calls `runtime_goroutineID`. The explicit process ID in [log line 1](/tmp/agysbx.mthP/agy.log:1) is `583837`.
- No separate language-server log is needed to explain this failure. The fatal child message reached `agy.log`; default logs are under `~/.config/gemini/antigravity-cli/log/`.
- The stream records failure followed by success but **omits `BypassSandbox`** from both calls. The earlier model’s final response claims bypass; the stream parameters cannot independently verify it.
- The earlier namespace probe used literal `/proc/$/stat`, so it did not measure process namespaces.
- Deeper asset inspection found `bin/agentapi` and `bin/webm_encoder`. `agentapi` is a shell wrapper back to this same `agy`, not the sandbox server.

## Ranked hypotheses and exact checks

### 1. CA symlink/alias handling leaves the bundle read-only — strongest

The fatal certificate-install failure is proven; the symlink explanation needs an A/B test.

**Offline confirmation:**

```bash
rg -n 'sbox:|installing certificate|read-only file system' /tmp/agysbx.mthP/agy.log "$HOME/.config/gemini/antigravity-cli/log"
readlink -f /etc/ssl/cert.pem /etc/ssl/certs/ca-certificates.crt
stat -Lc '%d:%i %a %n' /etc/ssl/cert.pem /etc/ssl/certs/ca-certificates.crt
```

**Live A/B:** temporarily expose regular CA-bundle copies inside a private mount namespace. This changes neither host CA symlink nor host trust-store contents. It creates temporary files and runs the live CLI.

```bash
AGY_CA_TEST=$(mktemp -d /tmp/agy-ca-layout.XXXXXX)
cp -a /etc/ssl "$AGY_CA_TEST/ssl"
cp --remove-destination /etc/ssl/cert.pem "$AGY_CA_TEST/ssl/cert.pem"
cp --remove-destination /etc/ssl/certs/ca-certificates.crt "$AGY_CA_TEST/ssl/certs/ca-certificates.crt"
bwrap --die-with-parent --ro-bind / / --dev-bind /dev /dev --proc /proc \
  --bind "$HOME" "$HOME" --bind /tmp /tmp --ro-bind "$AGY_CA_TEST/ssl" /etc/ssl \
  -- "$HOME/.local/bin/agy" --gemini_dir="$HOME/.config/gemini" \
  --sandbox --dangerously-skip-permissions --log-file="$AGY_CA_TEST/agy.log" \
  --output-format=stream-json \
  -p='Call run_command exactly once with CommandLine="echo SBX-OK". Do not retry or bypass the sandbox.' \
  >"$AGY_CA_TEST/trace.jsonl" 2>"$AGY_CA_TEST/err.txt"
rg -n 'sbox:|ERROR|SBX-OK' "$AGY_CA_TEST"/{agy.log,trace.jsonl,err.txt}
```

**Interpretation:** disappearance of the certificate fatal and success of the *first* tool call strongly support this hypothesis. `SBX-OK` after an error/retry does not count. The prompt itself is not an enforcement boundary.

**Repair:** vendor fix to make CA installation use private writable bundle copies while correctly handling resolved symlink targets and aliases. A validated private-mount wrapper could be an interim workaround; adopting it requires a user decision. Avoid replacing package-managed host CA symlinks.

### 2. Broader sandbox mount-policy bug, independent of symlinks — second

If the A/B still produces EROFS, capture the actual mounts and failing file operation:

```bash
AGY_DIAG=$(mktemp -d /tmp/agy-sbox-strace.XXXXXX)
strace -ff -tt -s 512 -yy -o "$AGY_DIAG/sys" \
  -e trace=%process,%file,%network,write,writev,mount,umount2,pivot_root,unshare,setns,prctl,seccomp,dup2,dup3 \
  "$HOME/.local/bin/agy" --gemini_dir="$HOME/.config/gemini" \
  --sandbox --dangerously-skip-permissions --log-file="$AGY_DIAG/agy.log" \
  --output-format=stream-json \
  -p='Call run_command exactly once with CommandLine="echo SBX-OK". Do not retry or bypass the sandbox.' \
  >"$AGY_DIAG/trace.jsonl" 2>"$AGY_DIAG/err.txt"
rg -n 'EROFS|sbox:|cert.pem|tls-ca-bundle|socketpair|execve|exited with|SIGSYS' "$AGY_DIAG"/sys* "$AGY_DIAG/agy.log"
```

Expect a certificate write/truncate failure and child exit before the second exec. `-ff` catches the short-lived helper; `-yy` identifies descriptor destinations, including redirected logs.

**Repair:** fix the mount ordering or writable CA exception in `exebox`, or test a vendor release containing that fix. Kernel/userns changes are unjustified by the current evidence. The observed failure precedes this sandbox’s seccomp initialization.

### 3. Different binary in the lead’s launch path — low probability

Current PATH entries all resolve to `~/.local/bin/agy`; inspected build ID is `41c0722061557995df58308202bf857a`.

```bash
type -a agy
sha256sum "$HOME/.local/bin/agy"
ps -C agy -o pid,ppid,stat,comm
for p in $(pgrep -x agy); do readlink "/proc/$p/exe"; done
ss -xapn | rg 'agy|exebox'
```

Run during a live attempt. An unnamed socketpair may have no `exebox` label; absence from this filtered snapshot proves nothing.

**Repair:** if paths differ, pin the intended absolute executable and restart affected processes. This cannot explain away the certificate failure already captured.

## Limits and immediate containment

I did not run `agy`, access the network, or modify files. The exact fatal cause is established; the CA-layout A/B and syscall trace remain unrun. No sandbox-specific verbosity variable was verified; the existing log already contains the decisive error.

Until repaired, enforce rejection of `BypassSandbox: true` outside the model, or disable terminal execution in these jobs. That policy change requires a user decision; successful fallback must not be treated as successful sandboxing.
