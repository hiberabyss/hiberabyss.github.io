" SmartIM

function! ToggleDraft()
    let parent_dir = expand('%:p:h:t')

    if index(["_drafts", "_posts"], parent_dir) >= 0
        if parent_dir == "_drafts"
            execute(":Move " . expand('%:p:h:s?_drafts?_posts?'))
        else
            execute(":Move " . expand('%:p:h:s?_posts?_drafts?'))
        endif
    endif
endfunction

nmap <silent> ,ht :call ToggleDraft()<cr>
nmap <silent> ,hs :HexoServer<cr>
nmap <silent> ,ho :HexoOpen<cr>
nmap <silent> ,hd :Dispatch hexo g && hexo d<cr>
nmap ,nn :HexoNew 
nmap ,nd :HexoNewDraft 

set expandtab
