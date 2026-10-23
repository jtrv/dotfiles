function clip-scrub --description 'pick clipcat history entries with fzf and delete them'
    set -l ids (clipcatctl list | fzf --multi --no-sort --prompt 'delete> ' \
        --header 'tab: mark  enter: delete marked' \
        --delimiter ': ' --preview 'clipcatctl get {1}' | string split -f1 ': ')
    test (count $ids) -gt 0; or return 0
    clipcatctl remove $ids
end
