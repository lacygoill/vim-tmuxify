fu s:complete_descriptor(...) abort "{{{1
    sil return system('tmux list-panes -aF "#S:#I.#P"')
endfu

fu s:fixstr(line) abort "{{{1
    let line = substitute(a:line, '\t', ' ', 'g')

    " remove possible spaces after an ending backslash;
    " necessary if we want to send a visual block of shell code;
    " without, the trailing whitespace prevent the commands from working
    " properly (at least in zsh)
    let line = substitute(a:line, '\\\s\+$', '\', '')

    " if line ends with a semicolon, escape it, to prevent tmux from
    " interpreting it as a separator between 2 commands (and remove it)
    "
    " https://github.com/jebaum/vim-tmuxify/issues/11
    "
    " Compare:
    "                                          ┌ removed
    "                                          │
    " pfx : send-keys -t study:1.2 -l 'echo foo;'
    " pfx : send-keys -t study:1.2 -l 'echo foo\;'
    "                                           │
    "                                           └ NOT removed
    return line[-1:] == ';' ? line[:-2] .. '\;' : line
endfu

fu s:get_pane_descriptor_from_id(pane_id) abort "{{{1
    sil let descriptor_list = systemlist(
        \  "tmux list-panes -a -F '#D #S #I #P' | awk 'substr($1, 2) == "
        \ .. a:pane_id
        \ .. " { print $2, $3, $4 }'"
        \ )

    if empty(descriptor_list) || descriptor_list[0] == 'failed to connect to server: Connection refused'
        return ''
    else
        " there should only ever be one item in descriptor_list, since it was
        " filtered for matching the unique pane_id
        let [session, window, pane] = split(descriptor_list[0],' ')
        return session .. ':' .. window .. '.' .. pane
    endif
endfu

" NOTE:
" Here's a bit of code showing how to build a pane descriptor from a pane ID.
"
" A pane ID begins with a `%` sign; ex:
"
"     %456
"
" A pane descriptor follows the format `session_name:window_index.pane_index`; ex:
"
"     study:1.2
"
"     sil let descriptor_list = systemlist(
"         \ "tmux list-panes -a -F '#D #S #I #P'"
"         \ ."| awk 'substr($1, 2) == ".s:pane_id." { print $2, $3, $4 }'"
"         \ )
"
"     let [ session, window, pane ] = split(descriptor_list[0], ' ')
"     let pane_descriptor = session .. ':' .. window .. '.' .. pane
"
" I got this code by reading the plugin `vim-tmuxify`:
" https://github.com/jebaum/vim-tmuxify/blob/master/autoload/tmuxify.vim
"
" In particular the function `s:get_pane_descriptor_from_id()`.
" The functions `pane_create()` and `pane_kill()` are also interesting.
"
" Explanation:
" Example of command executed by `systemlist()`:
"
"                      ┌ list all the panes, not just the ones in the current window
"                      │  ┌ format the output of the command; here according to the string:
"                      │  │          '#D #S #I #P'
"                      │  │            │  │  │  │
"                      │  │            │  │  │  └ index of pane
"                      │  │            │  │  └ index of window
"                      │  │            │  └ name of session
"                      │  │            └ unique pane ID (ex: %42)
"                      │  │
"     tmux list-panes -a -F '#D #S #I #P' | awk 'substr($1, 2) == 456 { print $2, $3, $4 }'
"                                                │                            │
"                                                │                            └ print:
"                                                │                                 session name
"                                                │                                 window index
"                                                │                                 pane index
"                                                │
"                                                └ remove the `%` prefix from the 1st field
"                                                  and compare the pane ID with `456`;
"                                                  `456` is the unique pane ID of the pane
"                                                  we're interested in
"
" Example of output for the command `tmux list-panes -a -F '#D #S #I #P'`:
"
"         %0 fun 1 1
"         %123 study 1 2
"         %456 study 1 2

fu tmuxify#pane_command(bang, ...) abort "{{{1
    let scope = !a:bang ? 'b:' : 'g:'

    if !exists(scope .. 'pane_id')
        echom "tmuxify: I'm not associated with any pane! Run :TxCreate, or check whether you're using bang commands consistently."
        return
    endif

    let pane_id = {scope}pane_id
    let pane_descriptor = s:get_pane_descriptor_from_id(pane_id)
    if empty(pane_descriptor)
        echom 'tmuxify: The associated pane was already closed! Run :TxCreate.'
        return
    endif

    sil call system('tmux ' .. a:1 .. ' -t ' .. pane_descriptor)
endfu

fu tmuxify#pane_create(bang, ...) abort "{{{1
    let scope = !a:bang ? 'b:' : 'g:'

    if !exists('$TMUX')
        echom 'tmuxify: This Vim is not running in a tmux session!'
        return

    elseif exists(scope .. 'pane_id')
        let pane_descriptor = s:get_pane_descriptor_from_id({scope}pane_id)
        if !empty(pane_descriptor)
            echom "tmuxify: I'm already associated with pane " .. pane_descriptor .. '!'
            return
        endif
    endif

    " capture the pane_id, as well as session, window, and pane index information
    " pane_id is unique, pane_index will change if the pane is moved
    let cmd = get(g:, 'tmuxify_custom_command', 'tmux split-window -d')
        \ .. " -PF '#D #S #I #P' | awk '{id=$1; session=$2; window=$3; pane=$4} END { print substr(id, 2), session, window, pane }'"
    sil let [ pane_id, session, window, pane ] = map(
        \  system(cmd)->split(' '),
        \  'str2nr(v:val)'
        \ )

    if exists('a:1')
        call tmuxify#pane_send(a:bang, a:1)
    endif

    let [ {scope}pane_id, {scope}session, {scope}window, {scope}pane ] = [ pane_id, session, window, pane]
    return 1
endfu

fu tmuxify#pane_kill(bang) abort "{{{1
    let scope = !a:bang ? 'b:' : 'g:'

    if !exists(scope .. 'pane_id')
        echom "tmuxify: I'm not associated with any pane! Run :TxCreate, or check whether you're using bang commands consistently."
        return
    endif

    let pane_id = {scope}pane_id
    let pane_descriptor = s:get_pane_descriptor_from_id(pane_id)
    if empty(pane_descriptor)
        echom 'tmuxify: The associated pane was already closed! Run :TxCreate.'
    else
        sil call system('tmux kill-pane -t ' .. pane_descriptor)
    endif

    unlet! {scope}pane_id
endfu

fu tmuxify#pane_run(bang, ...) abort "{{{1
    let scope = !a:bang ? 'b:' : 'g:'

    if !exists(scope .. 'pane_id') && !tmuxify#pane_create(a:bang)
        return
    endif

    let ft = !empty(&ft) ? &ft : ' '

    if exists('a:1')
        let action = a:1
    elseif exists('g:tmuxify_run') && has_key(g:tmuxify_run, ft) && !empty(g:tmuxify_run[ft])
        let action = g:tmuxify_run[ft]
    else
        let action = input('TxRun> ')
    endif

    let g:tmuxify_run = get(g:, 'tmuxify_run', {})
    let g:tmuxify_run[ft] = action

    call substitute(g:tmuxify_run[ft], '%', expand('%:p')->resolve(), '')
        \ ->tmuxify#pane_send(a:bang)
endfu

fu tmuxify#pane_send(lines = [], bang) abort "{{{1
    let scope = !a:bang ? 'b:' : 'g:'

    if !exists(scope .. 'pane_id') && !tmuxify#pane_create(a:bang)
        return
    endif

    let pane_id = {scope}pane_id
    let pane_descriptor = s:get_pane_descriptor_from_id(pane_id)
    if empty(pane_descriptor)
        echom 'tmuxify: The associated pane was already closed! Run :TxCreate.'
        return
    endif

    if !empty(a:lines)
        for line in split(a:lines, '\n')
            " `-l` disables key name lookup and sends the keys literally
            sil call system(
                \ 'tmux send-keys -t ' .. pane_descriptor
                \ .. ' -l ' .. s:fixstr(line)->shellescape()
                \ .. ' && tmux send-keys -t ' .. pane_descriptor
                \ .. ' C-m')
        endfor
    else
        sil call system(
            \ 'tmux send-keys -t ' .. pane_descriptor
            \ .. ' ' .. input('TxSend> ')->s:fixstr()->shellescape()
            \ .. ' C-m')
    endif
endfu

fu tmuxify#pane_send_key(bang, cmd) abort "{{{1
    let scope = !a:bang ? 'b:' : 'g:'

    "  ┌ if we don't have any info about a pane
    "  │                              ┌ and we can't even create one
    "  │                              │
    if !exists(scope .. 'pane_id') && !tmuxify#pane_create(a:bang)
        " gtfo
        return
    endif

    let pane_descriptor = s:get_pane_descriptor_from_id({scope}pane_id)
    if empty(pane_descriptor)
        echom 'tmuxify: The associated pane was already closed! Run :TxCreate.'
        return
    endif

    let keys = empty(a:cmd) ? input('TxSendKey> ') : a:cmd
    sil call system('tmux send-keys -t ' .. pane_descriptor .. ' ' .. string(keys))
endfu

fu tmuxify#pane_set(bang, ...) abort "{{{1
    let scope = !a:bang ? 'b:' : 'g:'

    if a:0 == 1
        if a:1[0] == '%'
            let descriptor_string = strpart(a:1, 1)->s:get_pane_descriptor_from_id()
            if empty(descriptor_string)
                echo 'tmuxify: Invalid Pane ID!'
                return
            endif
            let [session, window, pane] = split(descriptor_string, '\W')
        else
            let [session, window, pane] = split(a:1, '\W')
        endif
    else
        let descriptor = input('Session:Window.Pane> ', '', 'custom,<SNR>' .. expand('<SID>') .. '_complete_descriptor')
        let [session, window, pane] = split(descriptor, '\W')
    endif

    let [ {scope}session, {scope}window, {scope}pane ] = [session, window, pane]

    sil let pane_id = system(
        \  "tmux list-panes -a -F '#D #S #I #P' | awk '$2 == \""
        \ .. session
        \ .. "\" && $3 == \""
        \ .. window
        \ .. "\" && $4 == \""
        \ .. pane
        \ .. "\" {print substr($1, 2)}'"
        \ )

    if empty(pane_id)
        redraw | echom 'tmuxify: There is no pane ' .. pane .. '!'
        return
    endif

    let {scope}pane_id = str2nr(pane_id)
endfu

fu tmuxify#set_cmd(...) abort "{{{1
    let g:tmuxify_run = get(g:, 'tmuxify_run', {})
    let ft = !empty(&ft) ? &ft : ' '
    let g:tmuxify_run[ft] = exists('a:1') ? a:1 : input('TxSet(' .. ft .. ')> ')
endfu

