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

map global object a      -docstring 'LSP any symbol'                 %{: lsp-object <ret>}
map global object <a-a>  -docstring 'LSP any symbol'                 %{: lsp-object <ret>}
map global object f      -docstring 'LSP function or method'         %{: lsp-object Function Method <ret>}
map global object t      -docstring 'LSP class interface or struct'  %{: lsp-object Class Interface Struct <ret>}
map global object d      -docstring 'LSP errors and warnings'        %{: lsp-diagnostic-object --include-warnings <ret>}
map global object D      -docstring 'LSP errors'                     %{: lsp-diagnostic-object <ret>}

declare-option -hidden str lsp_server_lsp_ai %{
  [lsp-ai]
  root = "./"
  [lsp-ai.settings.memory]
  file_store = { }

  [lsp-ai.settings.completion]
  model = "gemini_complete"
  [lsp-ai.settings.completion.parameters]
  max_context = 1024
  max_tokens = 128

  [lsp-ai.settings.models.gemini_complete]
  type = "open_ai"
  completions_endpoint = "https://openrouter.ai/api/v1/completions"
  model = "google/gemini-2.5-pro-preview-03-25"
  auth_token_env_var_name = "OPENROUTER_API_KEY"

  [lsp-ai.settings.models.gemini]
  type = "open_ai"
  chat_endpoint = "https://openrouter.ai/api/v1/chat/completions"
  model = "google/gemini-2.5-pro-preview-03-25"
  auth_token_env_var_name = "OPENROUTER_API_KEY"
  max_requests_per_second = 1
  [[lsp-ai.settings.chat]]
  trigger = ",.gg"
  action_display_name = "google gemini"
  model = "gemini"
  parameters.max_context = 4096
  parameters.max_tokens = 1024
  paramaeters.messages = [
    { role = "system", content = "You are a code assistant chatbot. The user will ask you for assistance coding and you will do you best to answer succinctly and accurately" }
  ]

  [lsp-ai.settings.models.r1]
  type = "open_ai"
  chat_endpoint = "https://openrouter.ai/api/v1/chat/completions"
  model = "deepseek/r1"
  auth_token_env_var_name = "OPENROUTER_API_KEY"
  max_requests_per_second = 1
  [[lsp-ai.settings.chat]]
  trigger = ",.r1"
  action_display_name = "deepseek r1"
  model = "r1"
  parameters.max_context = 4096
  parameters.max_tokens = 1024
  paramaeters.messages = [
    { role = "system", content = "You are a code assistant chatbot. The user will ask you for assistance coding and you will do you best to answer succinctly and accurately" }
  ]

  [lsp-ai.settings.models.sonnet]
  type = "open_ai"
  chat_endpoint = "https://openrouter.ai/api/v1/chat/completions"
  model = "anthropic/claude-3.7-sonnet:thinking"
  auth_token_env_var_name = "OPENROUTER_API_KEY"
  max_requests_per_second = 1
  [[lsp-ai.settings.chat]]
  trigger = ",.so"
  action_display_name = "claude sonnet"
  model = "sonnet"
  parameters.max_context = 4096
  parameters.max_tokens = 1024
  paramaeters.messages = [
    { role = "system", content = "You are a code assistant chatbot. The user will ask you for assistance coding and you will do you best to answer succinctly and accurately" }
  ]
}

declare-option -hidden str lsp_server_harper %{
  [harper-ls]
  args = [ "--stdio" ]
  [harper-ls.settings]
  dialect = "American"
  maxFileLength = 120000
  [[linters]]
  AnA = true
  RepeatedWords = true
  SentenceCapitalization = false
  SpellCheck = false
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

declare-option -hidden str lsp_server_emmet %{
  [emmet-language-server]
  root_globs = [ "package.json", ".git", ".hg" ]
  args = [ "--stdio" ]
}

hook -group lsp-filetype-css global BufSetOption filetype=(?:css|less|scss) %{
  set-option buffer lsp_servers %exp{
    #opt{lsp_server_lsp_ai}
    %opt{lsp_server_biome}
    %opt{lsp_server_emmet}
    #opt{lsp_server_unocss}

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
    css.validate = true
    css.lint.unknownAtRules = "ignore"
    scss.validProperties = []
    scss.format.enable = true
    scss.validate = true
    less.validProperties = []
    less.format.enable = true
    less.validate = true
  }

}

hook -group lsp-filetype-dotenv global BufSetOption filetype=dotenv %{
  set-option buffer lsp_servers %{
    [dotenv-lsp]
    root_globs = [ ".env", "*.env", ".git", ".hg" ]
  }
}

hook -group lsp-filetype-fish global BufSetOption filetype=fish %{
  set-option buffer lsp_servers %exp{
    #opt{lsp_server_lsp_ai}

    [fish-lsp]
    root_globs = [ "*.fish", "fish", ".git", ".hg" ]
    args = [ "start" ]
    [fish-lsp.envs]
    fish_lsp_enabled_handlers = "popups formatting complete hover rename definition references diagnostics signatureHelp codeAction inlayHint highlight"
    fish_lsp_diagnostic_disable_error_codes = "2002 2001"
  }
}

hook -group lsp-filetype-html global BufSetOption filetype=html %{
  set-option buffer lsp_servers %exp{
    #opt{lsp_server_lsp_ai}
    %opt{lsp_server_biome}
    %opt{lsp_server_emmet}
    #opt{lsp_server_unocss}

    # Documented options see
    # https://github.com/sublimelsp/LSP-html/blob/master/LSP-html.sublime-settings
    [vscode-html-language-server]
    root_globs = [ "package.json", ".git", ".hg" ]
    args = [ "--stdio" ]
    settings_section = "_"
    [vscode-html-language-server.settings._]
    provideFormatter = true
    quotePreference = "none"
    javascript.format.semicolons = "none"
    [vscode-html-language-server.settings]
    embeddedLanguages.css = true
    embeddedLanguages.javascript = true

    html.autoClosingTags = true
    html.format.enable = true
    html.format.preserveNewLines = false
    html.mirrorCursorOnMatchingTag = true
    html.validate.scripts = true
    html.validate.styles = true

    css.format.enable = true
    css.format.preserveNewLines = false
    css.format.spaceAroundSelectorSeparator = true
    css.lint.boxModel = "ignore"
    css.lint.compatibleVendorPrefixes = "ignore"
    css.lint.duplicateProperties = "ignore"
    css.lint.universalSelector = "ignore"
    css.lint.zeroUnits = "ignore"
    css.validate = true
    css.validProperties = []

    javascript.format.enable = true
    javascript.validate.enable = true

    # This is mainly a linter for HTML and to be used together with vscode-html-language-server
    # https://github.com/kristoff-it/superhtml
    [superhtml]
    root_globs = [ "package.json", ".git", ".hg" ]
    args = [ "lsp" ]
  }
}

hook -group lsp-filetype-javascript global BufSetOption filetype=(?:javascript|typescript) %{
  set-option buffer lsp_servers %exp{
    #opt{lsp_server_lsp_ai}
    %opt{lsp_server_biome}
    %opt{lsp_server_emmet}
    #opt{lsp_server_unocss}

    [typescript-language-server]
    root_globs = [ "package.json", "tsjson", "jsjson", ".git", ".hg" ]
    args = [ "--stdio" ]
    settings_section = "_"
    [typescript-language-server.settings._]
    quotePreference = "none"
    typescript.format.semicolons = "none"

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
    #opt{lsp_server_lsp_ai}
    #opt{lsp_server_unocss}
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
    %opt{lsp_server_biome}
  "
}

hook -group lsp-filetype-latex global BufSetOption filetype=latex %{
  set-option buffer lsp_servers %exp{
    #opt{lsp_server_lsp_ai}

    [texlab]
    root_globs = [ ".git", ".hg" ]
    [texlab.settings.texlab]
    # See https://github.com/latex-lsp/texlab/wiki/Configuration
    #
    # Preview configuration for zathura with SyncTeX search.
    # For other PDF viewers see https://github.com/latex-lsp/texlab/wiki/Previewing
    forwardSearch.executable = "zathura"
    forwardSearch.args = [
      "%%p",
      "--synctex-forward", # Support texlab-forward-search
      "%%l:1:%%f",
      "--synctex-editor-command", # Inverse search: use Control+Left-Mouse-Button to jump to source.
      """
        sh -fc '
          echo "
            evaluate-commands -client %%opt{texlab_client} %%{
              evaluate-commands -try-client %%opt{jumpclient} %%{
                edit -- %%{input} %%{line}
              }
            }
          " | kak -p $kak_session
        '
      """,
    ]
    chktex.onOpenAndSave = true
    chktex.onEdit = true
    build.onSave = true
    build.args = [ "-pdf", "-interaction=nonstopmode", "-auxdir=.aux", "-synctex=1", "%%f" ]
  }
}


hook -group lsp-filetype-markdown global BufSetOption filetype=markdown %{
  set-option buffer lsp_servers %exp{
    #opt{lsp_server_lsp_ai}
    %opt{lsp_server_biome}

    [markdown-oxide]
    root_globs = [ "logseq" ]
  #   [zk]
  #   root_globs = [ ".zk" ]
  #   args = [ "lsp" ]
  #   [marksman]
  #   root_globs = [ ".marksman.toml" ]
  #   args = [ "server" ]
  }
}

hook -group lsp-filetype-prisma global BufSetOption filetype=prisma %{
  set-option buffer lsp_servers %exp{
    #opt{lsp_server_lsp_ai}

    [prisma-language-server]
    root_globs = [ ".git", ".hg", "prisma" ]
    args = [ "--stdio" ]
  }
}

declare-option -hidden str lsp_server_basedpyright %{
  [basedpyright-langserver]
  root_globs = [ "requirements.txt", "setup.py", "pyproject.toml", "pyrightconfig.json", ".git", ".hg" ]
  args = [ "--stdio" ]
}

hook -group lsp-filetype-python global BufSetOption filetype=python %{
  set-option buffer lsp_servers %exp{
    #opt{lsp_server_lsp_ai}

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
    #opt{lsp_server_lsp_ai}
  "
}

hook -group lsp-filetype-ruby global BufSetOption filetype=ruby %{
  set-option buffer lsp_servers %exp{
    #opt{lsp_server_lsp_ai}

    [solargraph]
    root_globs = [ "Gemfile" ]
    args = [ "stdio" ]
    settings_section = "_"
    [solargraph.settings._]
    # See https://github.com/castwide/solargraph/blob/master/lib/solargraph/language_server/host.rb
    diagnostics = true

    [ruby-lsp]
    root_globs = [ "Gemfile" ]
    args = [ "stdio" ]
  }
}

hook -group lsp-filetype-sql global BufSetOption filetype=sql %{
  set-option buffer lsp_servers %{
    #opt{lsp_server_lsp_ai}

    [sqls]
    roots = [ ".git", ".hg" ]
  }
}

hook -group lsp-filetype-toml global BufSetOption filetype=toml %{
  set-option buffer lsp_servers %exp{
    #opt{lsp_server_lsp_ai}

    [taplo]
    root_globs = [ ".git", ".hg" ]
    args = [ "lsp", "stdio" ]
  }
}
