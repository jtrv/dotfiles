# Bound lsp-exit's shutdown wait. Upstream lsp-exit (rc/lsp.kak) loops FOREVER
# waiting for kak-lsp to delete its session dir. But kak's exit and kak-lsp's
# shutdown can deadlock in a circular wait (kak stops servicing the server while
# waiting; the server can't finish flushing to kak, so it never removes the dir),
# leaving kak un-quittable and blocking whatever launched it. Cap the wait at ~3s
# so exit always proceeds; a still-wedged server is reaped when kak's client dies.
# Applied on KakBegin, which fires after all startup config (incl. the plugin,
# which defines lsp-exit at source time) — so this -override always wins, and it
# survives plugin updates.
hook -group lsp-exit-timeout global KakBegin .* %{
    define-command -override -hidden lsp-exit -params 0..1 -docstring %{
        lsp-exit: shutdown language servers associated with current editor session
    } %{
        lsp-send kakoune/exit
        evaluate-commands %sh{
            existing_session_dir=${kak_opt_lsp_pid_file%.ref/*}
            i=0
            while [ -e "${existing_session_dir}" ] && [ "$i" -lt 100 ]; do
                sleep .030
                i=$((i + 1))
            done
        }
    }
}

set-option global lsp_auto_highlight_references true
set-option global lsp_auto_show_code_actions true
set-option global lsp_diagnostic_line_error_sign '║'
set-option global lsp_diagnostic_line_warning_sign '┊'
set-option global lsp_hover_anchor true
set-option global lsp_hover_max_diagnostic_lines 40
set-option global lsp_hover_max_info_lines 40
set-option global lsp_insert_spaces true
set-option global lsp_snippet_support true

hook global -group semantic-tokens BufReload .* lsp-semantic-tokens
hook global -group semantic-tokens NormalIdle .* lsp-semantic-tokens
hook global -group semantic-tokens InsertIdle .* lsp-semantic-tokens

map global insert <tab> -docstring 'Select next snippet placeholder' %{<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>}

# LSP goto/jump targets. Keys avoid built-in goto bindings (g k j e t b c v h l i a f . n p).
map global goto d '<esc>: lsp-definition<ret>'           -docstring 'LSP definition'
map global goto y '<esc>: lsp-type-definition<ret>'      -docstring 'LSP type definition'
map global goto r '<esc>: lsp-references<ret>'           -docstring 'LSP references'
map global goto I '<esc>: lsp-implementation<ret>'       -docstring 'LSP implementation'
map global goto s '<esc>: lsp-goto-document-symbol<ret>' -docstring 'LSP document symbol'
map global goto o '<esc>: lsp-workspace-symbol-incr<ret>' -docstring 'LSP search workspace symbols'

# LSP next/previous navigation (brackets/parens are free in goto mode).
map global goto ] '<esc>: lsp-find-error<ret>'            -docstring 'LSP next error'
map global goto [ '<esc>: lsp-find-error --previous<ret>' -docstring 'LSP previous error'
map global goto } '<esc>: lsp-next-symbol<ret>'           -docstring 'LSP next symbol'
map global goto { '<esc>: lsp-previous-symbol<ret>'       -docstring 'LSP previous symbol'
map global goto ) '<esc>: lsp-next-function<ret>'         -docstring 'LSP next function'
map global goto ( '<esc>: lsp-previous-function<ret>'     -docstring 'LSP previous function'

map global object a      -docstring 'LSP any symbol'                 %{: lsp-object <ret>}
map global object <a-a>  -docstring 'LSP any symbol'                 %{: lsp-object <ret>}
map global object f      -docstring 'LSP function or method'         %{: lsp-object Function Method <ret>}
map global object t      -docstring 'LSP class interface or struct'  %{: lsp-object Class Interface Struct <ret>}
map global object d      -docstring 'LSP errors and warnings'        %{: lsp-diagnostic-object --include-warnings <ret>}
map global object D      -docstring 'LSP errors'                     %{: lsp-diagnostic-object <ret>}

declare-option -hidden str lsp_server_emmet %{
  [emmet-language-server]
  root_globs = [ "package.json", ".git", ".hg" ]
  args = [ "--stdio" ]
}

declare-option -hidden str lsp_server_harper %{
  [harper-ls]
  args = [ "--stdio" ]
  [harper-ls.settings.harper-ls]
  dialect = "American"
  maxFileLength = 120000
  diagnosticSeverity = "information"   # default "hint" barely shows in kak
  [harper-ls.settings.harper-ls.linters]
  AnA = true
  RepeatedWords = true
  SentenceCapitalization = false
  SpellCheck = true
}

# This is mainly a linter for HTML and to be used together with vscode-html-language-server
# https://github.com/kristoff-it/superhtml
declare-option -hidden str lsp_server_superhtml %{
  [superhtml]
  root_globs = [ "package.json", ".git", ".hg" ]
  args = [ "lsp" ]
}

declare-option -hidden str lsp_server_tailwind %{
  [tailwindcss-language-server]
  root_globs = [ "tailwind.*" ]
  args = [ "--stdio" ]
  [tailwindcss-language-server.settings.tailwindCSS]
  emmetCompletions = true
  editor.quickSuggestions.strings = "on"
}

declare-option -hidden str lsp_server_unocss %{
  [unocss-language-server]
  root_globs = [ ".git", ".hg", "package.json" ]
  args = [ "--stdio" ]
}

# type-checker alternative to pylsp+jedi; toggle on with %opt in the python hook
declare-option -hidden str lsp_server_basedpyright %{
  [basedpyright-langserver]
  root_globs = [ "requirements.txt", "setup.py", "pyproject.toml", "pyrightconfig.json", ".git", ".hg" ]
  args = [ "--stdio" ]
  settings_section = "_"
  [basedpyright-langserver.settings._.basedpyright.analysis]
  typeCheckingMode = "standard"
}

# same tsserver engine as typescript-language-server, just a faster/maintained wrapper;
# toggle this ON and the plain typescript-language-server block OFF (never both - two tsservers)
declare-option -hidden str lsp_server_vtsls %{
  [vtsls]
  root_globs = [ "package.json", "tsconfig.json", "jsconfig.json", ".git", ".hg" ]
  args = [ "--stdio" ]
}

# scss/sass superset of vscode-css (Sass modules, @use/@forward, SassDoc); toggle on for scss
declare-option -hidden str lsp_server_some_sass %{
  [some-sass-language-server]
  root_globs = [ ".git", ".hg", "package.json" ]
  args = [ "--stdio" ]
}

# older ruby LSP; ruby-lsp supersedes it - keep as a fallback toggle (YARD-doc hover)
declare-option -hidden str lsp_server_solargraph %{
  [solargraph]
  root_globs = [ "Gemfile" ]
  args = [ "stdio" ]
  settings_section = "_"
  [solargraph.settings._]
  diagnostics = true
}

# SQL linter/formatter (complements sqls, which does completion only); needs a .sqruff file
declare-option -hidden str lsp_server_sqruff %{
  [sqruff]
  root_globs = [ ".sqruff", ".git", ".hg" ]
  args = [ "lsp" ]
}

hook -group lsp-filetype-css global BufSetOption filetype=(?:css|less|scss) %{
  set-option buffer lsp_servers %{
    # Documented options see
    # https://github.com/sublimelsp/LSP-css/blob/master/LSP-css.sublime-settings
    [vscode-css-language-server]
    root_globs = [ "package.json", ".git", ".hg" ]
    args = [ "--stdio" ]
    settings_section = "_"
    [vscode-css-language-server.settings._]
    provideFormatter = true
    handledSchemas = [ "file" ]
    [vscode-css-language-server.settings]
    css.format.enable = true
    css.validProperties = []
    css.validate = false
    css.lint.unknownAtRules = "ignore"
    scss.validProperties = []
    scss.format.enable = true
    scss.validate = true
    less.validProperties = []
    less.format.enable = true
    less.validate = true
  }

  set-option -add buffer lsp_servers "
    %opt{lsp_server_biome}
    #opt{lsp_server_emmet}
    #opt{lsp_server_superhtml}
    #opt{lsp_server_unocss}
    #opt{lsp_server_some_sass}
  "
}

hook -group lsp-filetype-fish global BufSetOption filetype=fish %{
  set-option buffer lsp_servers %{
    [fish-lsp]
    root_globs = [ "*.fish", "config.fish", "fish", ".git", ".hg" ]
    args = [ "start" ]
    [fish-lsp.envs]
    fish_lsp_diagnostic_disable_error_codes = "2002 2001"
  }
}

hook -group lsp-filetype-html global BufSetOption filetype=html %{
  set-option buffer lsp_servers %{
    # Documented options see
    # https://github.com/sublimelsp/LSP-html/blob/master/LSP-html.sublime-settings
    [vscode-html-language-server]
    root_globs = [ "package.json", ".git", ".hg" ]
    args = [ "--stdio" ]
    settings_section = "_"
    [vscode-html-language-server.settings._]
    provideFormatter = true
    quotePreference = "none"
    [vscode-html-language-server.settings.embeddedLanguages]
    css = true
    javascript = true

    [vscode-html-language-server.settings.html]
    autoClosingTags = true
    suggest.html5 = true
    validate.scripts = true
    validate.styles = true
    [vscode-html-language-server.settings.html.format]
    contentUnformatted = "head, meta"
    enable = true
    extraLiners = "head, body, /html"
    indentInnerHtml = false
    preserveNewLines = false
    templating = true
    unformatted = "head, meta"

    [vscode-html-language-server.settings.css]
    validate = true
    validProperties = []
    [vscode-html-language-server.settings.css.format]
    enable = true
    preserveNewLines = false
    spaceAroundSelectorSeparator = true
    [vscode-html-language-server.settings.css.lint]
    boxModel = "ignore"
    compatibleVendorPrefixes = "ignore"
    duplicateProperties = "ignore"
    universalSelector = "ignore"
    unknownAtRules = "ignore"
    zeroUnits = "ignore"

    [vscode-html-language-server.settings.javascript]
    format.enable = true
    format.semicolons = "remove"
    validate.enable = true
  }

  set-option -add buffer lsp_servers "
    %opt{lsp_server_biome}
    #opt{lsp_server_emmet}
    #opt{lsp_server_superhtml}
    #opt{lsp_server_unocss}
  "
}

hook -group lsp-filetype-javascript global BufSetOption filetype=(?:javascript|typescript) %{
  set-option buffer lsp_servers %{
    [typescript-language-server]
    root_globs = [ "package.json", "tsjson", "jsjson", ".git", ".hg" ]
    args = [ "--stdio" ]
    settings_section = "_"
    [typescript-language-server.settings._]
    quotePreference = "auto"
    typescript.format.semicolons = "remove"

    [vscode-eslint-language-server]
    root_globs = [ ".eslintrc", ".eslintrc.json" ]
    args = [ "--stdio" ]
    workaround_eslint = true
    [vscode-eslint-language-server.settings]
    nodePath = ""
    codeActionsOnSave = { mode = "all", "source.fixAll.eslint" = true }
    format = { enable = true }
    quiet = false
    rulesCustomizations = []
    run = "onType"
    validate = "on"
    experimental = {}
    problems = { shortenToSingleLine = false }
    codeAction.disableRuleComment = { enable = true, location = "separateLine" }
    codeAction.showDocumentation = { enable = true }
  }

  set-option -add buffer lsp_servers "
    %opt{lsp_server_biome}
    #opt{lsp_server_emmet}
    #opt{lsp_server_unocss}
    #opt{lsp_server_vtsls}
  "
}

hook -group lsp-filetype-json global BufSetOption filetype=(?:json|jsonc) %{
  set-option buffer lsp_servers %{
    [vscode-json-language-server]
    root_globs = ["package.json", ".git", ".hg"]
    args = ["--stdio"]
    settings_section = "_"
    [vscode-json-language-server.settings._]
    provideFormatter = true
    json.format.enable = true
    json.validate.enable = true
    # These are just some example JSON schemas, you need to add whatever JSON files you edit.
    # The needed URLs you can find at https://www.schemastore.org/json/
    # Configuration see
    # https://github.com/microsoft/vscode/blob/main/extensions/json-language-features/server/README.md#configuration
    [[vscode-json-language-server.settings._.json.schemas]]
    fileMatch = ["/package.json"]
    url = "https://json.schemastore.org/package.json"
    [[vscode-json-language-server.settings._.json.schemas]]
    fileMatch = ["/.markdownlintrc","/.markdownlint.json","/.markdownlint.jsonc"]
    url = "https://raw.githubusercontent.com/DavidAnson/markdownlint/main/schema/markdownlint-config-schema.json"
    [[vscode-json-language-server.settings._.json.schemas]]
    fileMatch = ["/.prettierrc", "/.prettierrc.json"]
    url = "https://json.schemastore.org/prettierrc.json"
    [[vscode-json-language-server.settings._.json.schemas]]
    fileMatch = ["/compile_commands.json"]
    url = "https://json.schemastore.org/compile-commands.json"
    [[vscode-json-language-server.settings._.json.schemas]]
    fileMatch = ["/tsconfig*.json"]
    url = "https://json.schemastore.org/tsconfig.json"
  }
  set-option -add buffer lsp_servers "
    #opt{lsp_server_biome}
  "
}

hook -group lsp-filetype-latex global BufSetOption filetype=latex %{
  set-option buffer lsp_servers %{
    [texlab]
    root_globs = [ ".git", ".hg" ]
    [texlab.settings.texlab]
    # See https://github.com/latex-lsp/texlab/wiki/Configuration
    #
    # Preview configuration for zathura with SyncTeX search.
    # For other PDF viewers see https://github.com/latex-lsp/texlab/wiki/Previewing
    forwardSearch.executable = "sioyek"
    forwardSearch.args = [
      "--reuse-window",
      "--execute-command", "toggle_synctex",
      "--inverse-search",
      "texlab inverse-search -i '%%1' -l '%%2'",
      "--forward-search-file", "%f",
      "--forward-search-line", "%l",
      "%p",
    ]
    chktex.onOpenAndSave = true
    chktex.onEdit = true
    build.onSave = true
    build.forwardSearchAfter = true
    build.args = [ "-pdf", "-interaction=nonstopmode", "-auxdir=.aux", "-synctex=1", "%f" ]
  }
}


hook -group lsp-filetype-markdown global BufSetOption filetype=markdown %{
  set-option buffer lsp_servers %{
    [markdown-oxide]
    root_globs = [ "logseq" ]
  #   [zk]
  #   root_globs = [ ".zk" ]
  #   args = [ "lsp" ]
  #   [marksman]
  #   root_globs = [ ".marksman.toml" ]
  #   args = [ "server" ]
  }

  set-option -add buffer lsp_servers "
    %opt{lsp_server_harper}
  "
}

# prose grammar/spell (harper-ls) for commit messages and plain text
hook -group lsp-filetype-prose global BufSetOption filetype=(?:gitcommit|text) %{
  set-option buffer lsp_servers "
    %opt{lsp_server_harper}
  "
}

hook -group lsp-filetype-nix global BufSetOption filetype=nix %{
  set-option buffer lsp_servers %{
    [nil]
    root_globs = [ "*.nix" ]
    [nil.settings.nil]
    formatting.command = "nixfmt"
  }
}


hook -group lsp-filetype-prisma global BufSetOption filetype=prisma %{
  set-option buffer lsp_servers %{
    [prisma-language-server]
    root_globs = [ ".git", ".hg", "prisma" ]
    args = [ "--stdio" ]
  }
}

hook -group lsp-filetype-python global BufSetOption filetype=python %{
  set-option buffer lsp_servers %{
    [pylsp]
    root_globs = [ "requirements.txt", "setup.py", "pyproject.toml", ".git", ".hg" ]
    settings_section = "_"
    [pylsp.settings._]
    # See https://github.com/python-lsp/python-lsp-server#configuration
    # pylsp.configurationSources = [ "flake8" ]
    pylsp.plugins.jedi_completion.include_params = true

    [ruff]
    args = [ "server", "--quiet" ]
    root_globs = [ "requirements.txt", "setup.py", "pyproject.toml", ".git", ".hg" ]
    settings_section = "_"
    [ruff.settings._.globalSettings]
    organizeImports = true
    fixAll = true
  }

  set-option -add buffer lsp_servers "
    #opt{lsp_server_basedpyright}
  "
}

hook -group lsp-filetype-ruby global BufSetOption filetype=ruby %{
  set-option buffer lsp_servers %{
    [ruby-lsp]
    root_globs = [ "Gemfile", ".git", ".hg" ]
    args = [ "stdio" ]
  }

  set-option -add buffer lsp_servers "
    #opt{lsp_server_solargraph}
  "
}

hook -group lsp-filetype-sql global BufSetOption filetype=sql %{
  set-option buffer lsp_servers %{
    [sqls]
    root_globs = [ ".git", ".hg" ]
  }

  set-option -add buffer lsp_servers "
    #opt{lsp_server_sqruff}
  "
}

hook -group lsp-filetype-systemd global BufSetOption filetype=systemd %{
  set-option buffer lsp_servers %{
    [systemd-lsp]
    root_globs = [ "*.service", "*.mount", "*.device", "*.nspawn", "*.target", "*.timer" ]
  }
}


hook -group lsp-filetype-toml global BufSetOption filetype=toml %{
  set-option buffer lsp_servers %{
    [taplo]
    root_globs = [ ".git", ".hg" ]
    args = [ "lsp", "stdio" ]
  }
}
