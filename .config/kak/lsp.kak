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

declare-option -hidden str lsp_server_tailwind %{
    [tailwindcss-language-server]
    root_globs = [ "tailwind.*" ]
    args = [ "--stdio" ]
    [tailwindcss-language-server.settings.tailwindCSS]
    emmetCompletions = true
    editor.quickSuggestions.strings = "on"
}

hook -group lsp-filetype-css global BufSetOption filetype=(?:css|less|scss) %{
    set-option buffer lsp_servers %exp{
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
        %opt{lsp_server_biome}
        %opt{lsp_server_tailwind}
    }

}

hook -group lsp-filetype-fish global BufSetOption filetype=fish %{
    set-option buffer lsp_servers %{
        [fish-lsp]
        root_globs = [ "*.fish", "config.fish", ".git", ".hg" ]
        args = [ "start" ]
    }
}

hook -group lsp-filetype-html global BufSetOption filetype=html %{
    set-option buffer lsp_servers %exp{
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
        html.mirrorCursorOnMatchingTag = true
        html.validate.scripts = true
        html.validate.styles = true
        css.validate = true
        css.format.enable = true
        css.validProperties = []
        javascript.format.enable = true
        javascript.validate.enable = true
        # This is mainly a linter for HTML and to be used together with vscode-html-language-server
        # https://github.com/kristoff-it/superhtml
        [superhtml]
        root_globs = [ "package.json", ".git", ".hg" ]
        args = [ "lsp" ]
        %opt{lsp_server_biome}
        %opt{lsp_server_tailwind}
    }
}

hook -group lsp-filetype-javascript global BufSetOption filetype=(?:javascript|typescript) %{
    set-option buffer lsp_servers %exp{
        [typescript-language-server]
        root_globs = [ "package.json", "tsconfig.json", "jsconfig.json", ".git", ".hg" ]
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
        %opt{lsp_server_biome}
        %opt{lsp_server_tailwind}
    }
}

hook -group lsp-filetype-markdown global BufSetOption filetype=markdown %{
    set-option buffer lsp_servers %{
        [marksman]
        root_globs = [ ".marksman.toml" ]
        args = [ "server" ]
    }
    # set-option buffer lsp_servers %{
    #     [zk]
    #     root_globs = [ ".zk" ]
    #     args = [ "lsp" ]
    # }
    # set-option buffer lsp_servers %{
    #     [markdown-oxide]
    #     root_globs = [ "logseq" ]
    # }
}

hook -group lsp-filetype-prisma global BufSetOption filetype=prisma %{
    set-option buffer lsp_servers %{
        [prisma-language-server]
        root_globs = [ ".git", ".hg", "prisma" ]
        command = "prisma-language-server"
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
        [pyright-langserver]
        root_globs = [ "requirements.txt", "setup.py", "pyproject.toml", "pyrightconfig.json", ".git", ".hg" ]
        args = [ "--stdio" ]
        [ruff]
        args = [ "server", "--quiet" ]
        root_globs = [ "requirements.txt", "setup.py", "pyproject.toml", ".git", ".hg" ]
        settings_section = "_"
        [ruff.settings._.globalSettings]
        organizeImports = true
        fixAll = true
    }
}

hook -group lsp-filetype-ruby global BufSetOption filetype=ruby %{
    set-option buffer lsp_servers %{
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
        [sqls]
        roots = [ ".git", ".hg" ]
        command = "sqls"
    }
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
        forwardSearch.executable = "zathura"
        forwardSearch.args = [
            "%p",
            "--synctex-forward", # Support texlab-forward-search
            "%l:1:%f",
            "--synctex-editor-command", # Inverse search: use Control+Left-Mouse-Button to jump to source.
            """
                sh -c '
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
        build.args = [ "-pdf", "-interaction=nonstopmode", "-auxdir=.aux", "-synctex=1", "%f" ]
    }
}
