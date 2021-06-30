if exists('g:loaded_tmuxify')
    finish
endif
let g:loaded_tmuxify = v:true

" commands {{{1

" All these commands interact with a pane which is associated to:
"
"     current buffer  if no bang
"     current session if    bang
"
"     Do we use global tmux panes or buffer local ones ? ──────────────┐
"                                                                      │
command -nargs=0 -bar -bang TxCancel  call tmuxify#pane_send_key( <bang>0, 'C-c'    )
command -nargs=0 -bar -bang TxClear   call tmuxify#pane_send_key( <bang>0, 'C-l'    )
command -nargs=? -bar -bang TxCreate  call tmuxify#pane_create(   <bang>0, <args>   )
command -nargs=0 -bar -bang TxKill    call tmuxify#pane_kill(     <bang>0           )
command -nargs=? -bar -bang TxRun     call tmuxify#pane_run(      <bang>0, <args>   )
command -nargs=? -bar -bang TxSend    call tmuxify#pane_send(     <bang>0, <args>   )
command -nargs=? -bar -bang TxSendKey call tmuxify#pane_send_key( <bang>0, <q-args> )
command -nargs=? -bar       TxSetCmd  call tmuxify#set_cmd(                <args>   )
command -nargs=? -bar -bang TxSetPane call tmuxify#pane_set(      <bang>0, <f-args> )

" mappings {{{1

" TODO:
" Commented for the moment, because it would introduce lag for similar mappings in vimrc.
" Integrate/Move tmux mappings from vimrc to this plugin.

"     nnoremap <Bar>xc <Cmd>TxCancel<CR>
"     nnoremap <Bar>xk <Cmd>TxSendKey<CR>
"     nnoremap <Bar>xl <Cmd>TxClear<CR>
"     nnoremap <Bar>xn <Cmd>TxCreate<CR>
"     nnoremap <Bar>xp <Cmd>TxSetPane<CR>
"     nnoremap <Bar>xq <Cmd>TxKill<CR>
"     nnoremap <Bar>xr <Cmd>TxRun<CR>
"     nnoremap <Bar>xs <Cmd>TxSend<CR>
"     nnoremap <Bar>xt <Cmd>TxSetCmd<CR>
"
"              ┌ do NOT use `!x`, it would prevent you from writing a visual selection
"              │ on the standard input of a shell command whose name begins with an `x`
"              │
"              │ do NOT use `!<C-X>`, it would introduce lag when we press `!` in visual mode
"              │
"              │ do NOT use `<C-X>!`, it would introduce lag when we want to decrease numbers
"              │
"              │ you COULD use `mx` though
"              │
"     xnoremap <Bar>x "my<Cmd>TxSend(@m)<CR>
