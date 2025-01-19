function __systemctl --description 'wraps privileged and user systemctl commands to use sudo when necessary' -w systemctl
    set -l user_commands \
      list-units list-unit-files list-jobs list-timers \
      list-sockets list-dependencies list-machines \
      is-active is-enabled is-failed \
      status show help get-default show-environment cat

    set -l root_commands start stop reload restart try-restart \
        reload-or-restart try-reload-or-restart isolate kill clean \
        set-property reset-failed enable disable reenable preset \
        preset-all mask unmask link revert add-wants add-requires \
        edit set-default cancel set-environment unset-environment import-environment \
        daemon-reload daemon-reexec default rescue emergency halt poweroff reboot \
        kexec exit switch-root suspend hibernate hybrid-sleep suspend-then-hibernate

    if contains -- --user $argv; or not contains -- $argv[1] $root_commands
        command systemctl $argv
    else
        command sudo systemctl $argv
    end
end

alias sc  "__systemctl"
alias scu "__systemctl --user"
alias jr  "journalctl"
alias jru "journalctl --user"
