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
nmap <silent> ,hb :HexoBrowse<cr>
nmap <silent> ,ho :HexoOpen<cr>
nmap <silent> ,hd :Dispatch hexo recommend && hexo g && hexo d<cr>
nmap ,hn :HexoNew 
nmap ,hd :HexoNewDraft 

" hexo "{{{
function! AutoUpdateTimeStamp()
    let curPos = getpos('.')
    silent! 1,5s#^updated: \zs.*#\=strftime('%F %T')#
    call cursor(curPos[1:])
endfunction
"}}}

autocmd! BufWrite *.md call AutoUpdateTimeStamp()

command! -nargs=0 InsertImg :r !blogimg

set expandtab
