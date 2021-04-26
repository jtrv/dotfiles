# Defined via `source`
function warehouse

    echo -e "--paru\n"                     > ~/.warehouse
    paru -Qetq                            >> ~/.warehouse

    echo -e "\n\n\n--cargo\n"             >> ~/.warehouse
        cargo install --list |\
        sd "v\d.*\n" "\n" |\
        sd "^\s.*\n" ""                   >> ~/.warehouse
      
    echo -e "\n\n\n--fisher\n" 	          >> ~/.warehouse
    /bin/cat ~/.config/fish/fish_plugins    >> ~/.warehouse

    echo -e "\n\n\n--Oh-My-Fish\n"          >> ~/.warehouse
    /bin/ls ~/.config/fish/conf.d/          >> ~/.warehouse

    config diff ~/.warehouse &&
    config add ~/.warehouse &&
    config commit -m "Warehousing packages"
end
