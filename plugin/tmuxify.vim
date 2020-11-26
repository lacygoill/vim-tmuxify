if exists('g:loaded_tmuxify')
    finish
endif
let g:loaded_tmuxify = 1

" commands {{{1

" All these commands interact with a pane which is associated to:
"         current buffer  if no bang
"         current session if    bang
"
" Do we use global tmux panes or buffer local ones ? ──────────────┐
"                                                                  │
com -nargs=0 -bar -bang TxCancel  call tmuxify#pane_send_key( <bang>0, 'C-c'    )
com -nargs=0 -bar -bang TxClear   call tmuxify#pane_send_key( <bang>0, 'C-l'    )
com -nargs=? -bar -bang TxCreate  call tmuxify#pane_create(   <bang>0, <args>   )
com -nargs=0 -bar -bang TxKill    call tmuxify#pane_kill(     <bang>0           )
com -nargs=? -bar -bang TxRun     call tmuxify#pane_run(      <bang>0, <args>   )
com -nargs=? -bar -bang TxSend    call tmuxify#pane_send(     <bang>0, <args>   )
com -nargs=? -bar -bang TxSendKey call tmuxify#pane_send_key( <bang>0, <q-args> )
com -nargs=? -bar       TxSetCmd  call tmuxify#set_cmd(                <args>   )
com -nargs=? -bar -bang TxSetPane call tmuxify#pane_set(      <bang>0, <f-args> )

" mappings {{{1

" TODO:
" Commented for the moment, because it would introduce lag for similar mappings in vimrc.
" Integrate/Move tmux mappings from vimrc to this plugin.

"     nno <bar>xc <cmd>TxCancel<cr>
"     nno <bar>xk <cmd>TxSendKey<cr>
"     nno <bar>xl <cmd>TxClear<cr>
"     nno <bar>xn <cmd>TxCreate<cr>
"     nno <bar>xp <cmd>TxSetPane<cr>
"     nno <bar>xq <cmd>TxKill<cr>
"     nno <bar>xr <cmd>TxRun<cr>
"     nno <bar>xs <cmd>TxSend<cr>
"     nno <bar>xt <cmd>TxSetCmd<cr>
"
"         ┌ do NOT use `!x`, it would prevent you from writing a visual selection
"         │ on the standard input of a shell command whose name begins with an `x`
"         │
"         │ do NOT use `!<c-x>`, it would introduce lag when we press `!` in visual mode
"         │
"         │ do NOT use `<c-x>!`, it would introduce lag when we want to decrease numbers
"         │
"         │ you COULD use `mx` though
"         │
"     xno <bar>x "my<cmd>TxSend(@m)<cr>
