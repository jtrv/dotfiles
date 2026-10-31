# Delegation launcher verification

Pi version: 0.85.1. No staging or commits. Extension installation blocked by read-only ~/.config/pi; source and test are in the authorized fallback.

Files written:
- /tmp/claude-1000/-home-sugimoto--config-agents/2bb27d90-a61e-4b9c-9b82-d9155a067e32/scratchpad/delegate/delegate.ts
- /tmp/claude-1000/-home-sugimoto--config-agents/2bb27d90-a61e-4b9c-9b82-d9155a067e32/scratchpad/delegate/delegate.test.ts
- /home/sugimoto/.config/agents/pi.md
- /home/sugimoto/.config/agents/PLUGINS.md
- /tmp/claude-1000/-home-sugimoto--config-agents/2bb27d90-a61e-4b9c-9b82-d9155a067e32/scratchpad/delegate/REPORT.md

A node_modules symlink in the fallback points to the existing global Bun packages for local checks; it is not part of the extension.

## Registered schema

```json
{
  "type": "object",
  "required": [
    "runner",
    "task"
  ],
  "properties": {
    "runner": {
      "type": "string",
      "enum": [
        "pi",
        "codex"
      ]
    },
    "task": {
      "type": "string",
      "minLength": 1
    },
    "cwd": {
      "type": "string",
      "description": "Absolute existing directory; defaults to ctx.cwd"
    },
    "model": {
      "type": "string",
      "description": "Pi: provider/model (default openai-codex/gpt-5.6-sol). Codex: gpt-5.6-luna | gpt-5.6-terra | gpt-5.6-sol | gpt-6-astra (default gpt-5.6-terra)."
    },
    "mode": {
      "type": "string",
      "enum": [
        "read-only",
        "write"
      ],
      "default": "read-only"
    },
    "timeout_s": {
      "type": "number",
      "exclusiveMinimum": 0,
      "maximum": 1800,
      "default": 600
    }
  },
  "additionalProperties": false
}
```

## Child commands

The following are the exact argument layouts (cwd and temporary result path vary per call). No real child launched during interrogation because the parent could not open credentials. The offline fake runners exercised these layouts; task bytes went only to stdin. spawn uses shell:false, detached:true.

```text
pi -p --no-session --no-extensions --no-skills --no-prompt-templates --provider openai-codex --model gpt-5.6-sol --mode json --tools read,grep,find,ls
```

```text
codex exec --skip-git-repo-check -m gpt-5.6-luna -C /tmp/delegate-live --sandbox read-only --ephemeral --output-last-message /tmp/pi-delegate-<random>/final.txt -
```

Write mode removes Pi --tools and changes Codex --sandbox to workspace-write. Default Codex model is gpt-5.6-terra; the requested live probe selected Luna. All flags verified in local --help; none dropped. Context-disabling and config-ignoring flags from the older research proposal were intentionally not used, as requested.

## bun test

```text
bun test v1.4.2 (744846f84)

../../../../tmp/claude-1000/-home-sugimoto--config-agents/2bb27d90-a61e-4b9c-9b82-d9155a067e32/scratchpad/delegate/delegate.test.ts:
37 | 			process.env.PATH = `${dir}:${oldPath}`;
38 | 			process.env.PARENT_SESSION = "must-not-inherit";
39 | 			for (const runner of ["pi", "codex"] as const) {
40 | 				const task = "literal ' \" $(touch PWNED); `id` & | > <\nlast line\n";
41 | 				const result = await runDelegate({ runner, task }, dir);
42 | 				assert.equal(result.status, "answered");
                ^
AssertionError: Expected values to be strictly equal:
+ actual - expected

+ 'failed'
- 'answered'

 generatedMessage: true,
     actual: "failed",
   expected: "answered",
   operator: "strictEqual",
       diff: "simple",
       code: "ERR_ASSERTION"

      at /tmp/claude-1000/-home-sugimoto--config-agents/2bb27d90-a61e-4b9c-9b82-d9155a067e32/scratchpad/delegate/delegate.test.ts:42:12
      at node:test:1445:26
      at executeTestNode (node:test:1448:63)
      at processTicksAndRejections (native:7:39)
(fail) stdin, flags, final capture, failures, caps, process groups and concurrency [14.12ms]

 0 pass
 1 fail
Ran 1 test across 1 file. [94.00ms]
```

## Same test under Node

```text
✔ stdin, flags, final capture, failures, caps, process groups and concurrency (1117.176403ms)
ℹ tests 1
ℹ suites 0
ℹ pass 1
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 1120.866041
```

## Pi live transcript, requested parent defaults

```text
Warning: Invalid settings file /home/sugimoto/.config/pi/agent/settings.json: EROFS: read-only file system, mkdir '/home/sugimoto/.config/pi/agent/settings.json.lock'
No API key found for the selected model.

Use /login to log into a provider via OAuth or API key. See:
  /home/sugimoto/.local/share/bun/install/global/node_modules/@earendil-works/pi-coding-agent/docs/providers.md
  /home/sugimoto/.local/share/bun/install/global/node_modules/@earendil-works/pi-coding-agent/docs/models.md
```

## Codex live transcript, requested parent defaults

```text
Warning: Invalid settings file /home/sugimoto/.config/pi/agent/settings.json: EROFS: read-only file system, mkdir '/home/sugimoto/.config/pi/agent/settings.json.lock'
No API key found for the selected model.

Use /login to log into a provider via OAuth or API key. See:
  /home/sugimoto/.local/share/bun/install/global/node_modules/@earendil-works/pi-coding-agent/docs/providers.md
  /home/sugimoto/.local/share/bun/install/global/node_modules/@earendil-works/pi-coding-agent/docs/models.md
```

## Pi live transcript, explicit parent provider/model

```text
Warning: Invalid settings file /home/sugimoto/.config/pi/agent/settings.json: EROFS: read-only file system, mkdir '/home/sugimoto/.config/pi/agent/settings.json.lock'
Credential store read failed for openai-codex: EROFS: read-only file system, mkdir '/home/sugimoto/.config/pi/agent/auth.json.lock'
```

## Codex live transcript, explicit parent provider/model

```text
Warning: Invalid settings file /home/sugimoto/.config/pi/agent/settings.json: EROFS: read-only file system, mkdir '/home/sugimoto/.config/pi/agent/settings.json.lock'
Credential store read failed for openai-codex: EROFS: read-only file system, mkdir '/home/sugimoto/.config/pi/agent/auth.json.lock'
```

All live commands ran from scratch under /tmp; they added -e /tmp/claude-1000/-home-sugimoto--config-agents/2bb27d90-a61e-4b9c-9b82-d9155a067e32/scratchpad/delegate/delegate.ts because auto-discovery installation was blocked. Explicit retries also added --provider openai-codex --model gpt-5.6-sol. Both used the exact user-requested task and interrogation wording. Every live parent exited 1 before delegation.

TypeScript strict check and oxfmt check passed. Type-aware oxlint could not run: Failed to find tsgolint executable. No lint success is claimed from that gate. Bun stdin EPERM reproduced with a standalone spawn(cat), while Node's equivalent worked. Node test used synchronous fake-runner stdout because asynchronous console output also disappeared in this sandbox.

Concurrency: a third active call rejects immediately. Timeout/abort: SIGKILL to the detached process group; Node checks observed the sleeping grandchild gone or zombie (not executing). Output: 32 KiB final UTF-8 text, truncation flag and notice; Pi has an additional 8 MiB JSON event safety limit. Failure result is JSON in a thrown Error so Pi marks the tool failed. Environment is allowlisted for config/auth lookup and does not inherit arbitrary parent/session variables.

Consciously omitted: scheduler, queues, worktrees, persistence, streaming UI, slash commands, token accounting, retries, and filesystem read isolation. AGENTS.md remains available, as do files readable by the child; the guarantee is no parent history passed, not confidentiality against filesystem reads. Live tool invocation and installation remain unverified because of the stated sandbox blocks.
