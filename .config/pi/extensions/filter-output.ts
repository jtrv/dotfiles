import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

/**
 * Filter or transform tool results before the LLM sees them.
 * Redacts sensitive data like API keys, tokens, passwords, etc.
 */
export default function (pi: ExtensionAPI) {
  const sensitivePatterns = [
    { pattern: /\b(sk-[a-zA-Z0-9]{20,})\b/g, replacement: "[OPENAI_KEY_REDACTED]" }, // sk-abc123...
    { pattern: /\b(ghp_[a-zA-Z0-9]{36,})\b/g, replacement: "[GITHUB_TOKEN_REDACTED]" }, // ghp_xxxx...
    { pattern: /\b(gho_[a-zA-Z0-9]{36,})\b/g, replacement: "[GITHUB_OAUTH_REDACTED]" }, // gho_xxxx...
    { pattern: /\b(xox[baprs]-[a-zA-Z0-9-]{10,})\b/g, replacement: "[SLACK_TOKEN_REDACTED]" }, // xoxb-xxx, xoxp-xxx
    { pattern: /\b(AKIA[A-Z0-9]{16})\b/g, replacement: "[AWS_KEY_REDACTED]" }, // AKIAIOSFODNN7EXAMPLE
    {
      pattern: /\b(api[_-]?key|apikey)\s*[=:]\s*['"]?([a-zA-Z0-9_-]{20,})['"]?/gi,
      replacement: "$1=[REDACTED]",
    }, // api_key=xxx, apiKey: "xxx"
    {
      pattern: /\b(secret|token|password|passwd|pwd)\s*[=:]\s*['"]?([^\s'"]{8,})['"]?/gi,
      replacement: "$1=[REDACTED]",
    }, // password=xxx, secret: "xxx"
    { pattern: /\b(bearer)\s+([a-zA-Z0-9._-]{20,})\b/gi, replacement: "Bearer [REDACTED]" }, // Bearer eyJhbGc...
    { pattern: /(mongodb(\+srv)?:\/\/[^:]+:)[^@]+(@)/gi, replacement: "$1[REDACTED]$3" }, // mongodb://user:pass@host
    { pattern: /(postgres(ql)?:\/\/[^:]+:)[^@]+(@)/gi, replacement: "$1[REDACTED]$3" }, // postgresql://user:pass@host
    { pattern: /(mysql:\/\/[^:]+:)[^@]+(@)/gi, replacement: "$1[REDACTED]$3" }, // mysql://user:pass@host
    { pattern: /(redis:\/\/[^:]+:)[^@]+(@)/gi, replacement: "$1[REDACTED]$3" }, // redis://user:pass@host
    {
      pattern:
        /-----BEGIN (RSA |EC |OPENSSH |)PRIVATE KEY-----[\s\S]*?-----END \1PRIVATE KEY-----/g,
      replacement: "[PRIVATE_KEY_REDACTED]",
    }, // -----BEGIN RSA PRIVATE KEY-----...
  ];

  const sensitiveFiles = [
    /\.env$/, // .env
    /\.env\.(?!example$)[^/]+$/, // .env.local, .env.production (but not .env.example)
    /\.dev\.vars($|\.[^/]+$)/, // .dev.vars
    /secrets?\.(json|ya?ml|toml)$/i, // secrets.json, secret.yaml
    /credentials/i, // credentials, CREDENTIALS
  ];

  pi.on("tool_result", async (event, ctx) => {
    if (event.isError) return undefined;

    // Extract text from content array
    const textContent = event.content.find(
      (c): c is { type: "text"; text: string } => c.type === "text",
    );
    if (!textContent) return undefined;

    let result = textContent.text;
    let wasModified = false;

    if (event.toolName === "read") {
      const filePath = event.input.path as string;
      if (/(^|\/)\.env\.example$/i.test(filePath)) {
        return undefined;
      }
      for (const pattern of sensitiveFiles) {
        if (pattern.test(filePath)) {
          ctx.ui.notify(`🔒 Redacted contents of sensitive file: ${filePath}`, "info");
          return {
            content: [{ type: "text", text: `[Contents of ${filePath} redacted for security]` }],
          };
        }
      }
    }

    for (const { pattern, replacement } of sensitivePatterns) {
      const newResult = result.replace(pattern, replacement);
      if (newResult !== result) {
        wasModified = true;
        result = newResult;
      }
    }

    if (wasModified) {
      ctx.ui.notify("🔒 Sensitive data redacted from output", "info");
      return { content: [{ type: "text", text: result }] };
    }

    return undefined;
  });
}
