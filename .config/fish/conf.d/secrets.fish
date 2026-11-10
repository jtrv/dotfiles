# API keys from sops-nix (nixos-config nixos/common/sops.nix). The ANALAYSIS
# typo is the name its consumers read.
for pair in \
    ARTIFICIAL_ANALAYSIS_API_KEY:artificial-analysis-key \
    DEEPSEEK_API_KEY:deepseek-key \
    GEMINI_KEY:gemini-key \
    GROQ_API_KEY:groq-key \
    OPENROUTER_API_KEY:openrouter-key
    set -l kv (string split : $pair)
    test -r /run/secrets/$kv[2]; and set -gx $kv[1] (string collect </run/secrets/$kv[2])
end

