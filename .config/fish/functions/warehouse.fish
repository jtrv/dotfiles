# Defined via `source`
function warehouse

    echo -e "--paru\n"                   > ~/.config/.warehouse
        paru -Qetq | sd "^x[d-o].*\n" "" >> ~/.config/.warehouse
        
    echo -e "\n\n\n--cargo\n"            >> ~/.config/.warehouse
        cargo install --list |\
        sd "v\d.*\n" "\n" |\
        sd "^\s.*\n" ""                  >> ~/.config/.warehouse
      
    echo -e "\n\n\n--fish-plugins\n" 	 >> ~/.config/.warehouse
    /bin/cat ~/.config/fish/fish_plugins >> ~/.config/.warehouse

    config diff ~/.config/.warehouse
    config add ~/.config/.warehouse &&
    config commit -m "Warehousing packages"
end
