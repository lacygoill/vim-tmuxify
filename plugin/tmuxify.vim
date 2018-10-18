" commands {{{1

" All these commands interact with a pane which is associated to:
"         current buffer  if no bang
"         current session if    bang
"
" Do we use global tmux panes or buffer local ones ? ───────────────┐
"                                                                   │
com! -nargs=0 -bar -bang  TxCancel     call tmuxify#pane_send_key( <bang>0, 'C-c'    )
com! -nargs=0 -bar -bang  TxClear      call tmuxify#pane_send_key( <bang>0, 'C-l'    )
com! -nargs=? -bar -bang  TxCreate     call tmuxify#pane_create(   <bang>0, <args>   )
com! -nargs=0 -bar -bang  TxKill       call tmuxify#pane_kill(     <bang>0           )
com! -nargs=? -bar -bang  TxRun        call tmuxify#pane_run(      <bang>0, <args>   )
com! -nargs=? -bar -bang  TxSend       call tmuxify#pane_send(     <bang>0, <args>   )
com! -nargs=? -bar -bang  TxSendKey    call tmuxify#pane_send_key( <bang>0, <q-args> )
com! -nargs=? -bar        TxSetCmd     call tmuxify#set_cmd(                <args>   )
com! -nargs=? -bar -bang  TxSetPane    call tmuxify#pane_set(      <bang>0, <f-args> )

" mappings {{{1

" TODO:
" Commented for the moment, because it would introduce lag for similar mappings in `vimrc`.
" Integrate/Move tmux mappings from `vimrc` to this plugin.

"         nno <silent>  <bar>xc  :<c-u>TxCancel<cr>
"         nno <silent>  <bar>xk  :<c-u>TxSendKey<cr>
"         nno <silent>  <bar>xl  :<c-u>TxClear<cr>
"         nno <silent>  <bar>xn  :<c-u>TxCreate<cr>
"         nno <silent>  <bar>xp  :<c-u>TxSetPane<cr>
"         nno <silent>  <bar>xq  :<c-u>TxKill<cr>
"         nno <silent>  <bar>xr  :<c-u>TxRun<cr>
"         nno <silent>  <bar>xs  :<c-u>TxSend<cr>
"         nno <silent>  <bar>xt  :<c-u>TxSetCmd<cr>
"
"                       ┌─ do NOT use `!x`, it would prevent you from writing a visual selection
"                       │  on the standard input of a shell command whose name begins with an `x`
"                       │
"                       │  do NOT use `!<c-x>`, it would introduce lag when we press `!` in visual mode
"                       │
"                       │  do NOT use `<c-x>!`, it would introduce lag when we want to decrease numbers
"                       │
"                       │  you COULD use `mx` though
"                       │
"         xno <silent>  <bar>x  "my:TxSend(@m)<cr>
