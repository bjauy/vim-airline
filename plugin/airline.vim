" MIT License. Copyright (c) 2013 Bailey Ling.
" vim: et ts=2 sts=2 sw=2

if &cp || v:version < 702 || (exists('g:loaded_airline') && g:loaded_airline)
  finish
endif
let g:loaded_airline = 1

" autocmd VimEnter * call airline#deprecation#check()

function! s:check_defined(variable, default)
  if !exists(a:variable)
    let {a:variable} = a:default
  endif
endfunction

let s:airline_initialized = 0
let s:airline_theme_defined = 0
function! s:init()
  if !s:airline_initialized
    let s:airline_initialized = 1

    call s:check_defined('g:airline_left_sep', get(g:, 'airline_powerline_fonts', 0)?"":">")
    call s:check_defined('g:airline_left_alt_sep', get(g:, 'airline_powerline_fonts', 0)?"":">")
    call s:check_defined('g:airline_right_sep', get(g:, 'airline_powerline_fonts', 0)?"":"<")
    call s:check_defined('g:airline_right_alt_sep', get(g:, 'airline_powerline_fonts', 0)?"":"<")
    call s:check_defined('g:airline_detect_modified', 1)
    call s:check_defined('g:airline_detect_paste', 1)
    call s:check_defined('g:airline_detect_iminsert', 0)
    call s:check_defined('g:airline_inactive_collapse', 1)
    call s:check_defined('g:airline_exclude_filenames', ['DebuggerWatch','DebuggerStack','DebuggerStatus'])
    call s:check_defined('g:airline_exclude_filetypes', [])
    call s:check_defined('g:airline_exclude_preview', 0)

    call s:check_defined('g:airline_symbols', {})
    call extend(g:airline_symbols, {
          \ 'paste': get(g:, 'airline_paste_symbol', 'PASTE'),
          \ 'readonly': get(g:, 'airline_readonly_symbol', get(g:, 'airline_powerline_fonts', 0) ? '' : 'RO'),
          \ 'whitespace': get(g:, 'airline_powerline_fonts', 0) ? '✹' : '!',
          \ 'linenr': get(g:, 'airline_linecolumn_prefix', get(g:, 'airline_powerline_fonts', 0) ? '' : ':' ),
          \ 'branch': get(g:, 'airline_branch_prefix', get(g:, 'airline_powerline_fonts', 0) ? '' : ''),
          \ }, 'keep')

    call airline#parts#define_function('mode', 'airline#parts#mode')
    call airline#parts#define_function('iminsert', 'airline#parts#iminsert')
    call airline#parts#define_function('paste', 'airline#parts#paste')
    call airline#parts#define('readonly', {
          \ 'function': 'airline#parts#readonly',
          \ 'highlight': 'airline_file',
          \ })
    call airline#parts#define_raw('file', '%f%m')

    call s:check_defined('g:airline_parts', {})
    call extend(g:airline_parts, {
          \ 'ffenc': '%{printf("%s%s",&fenc,strlen(&ff)>0?"[".&ff."]":"")}',
          \ 'tagbar': 'airline#parts#empty',
          \ 'syntastic': 'airline#parts#empty',
          \ 'whitespace': 'airline#parts#empty',
          \ }, 'keep')

    call s:check_defined('g:airline_mode_map', {})
    call extend(g:airline_mode_map, {
          \ '__' : '------',
          \ 'n'  : 'NORMAL',
          \ 'i'  : 'INSERT',
          \ 'R'  : 'REPLACE',
          \ 'v'  : 'VISUAL',
          \ 'V'  : 'V-LINE',
          \ 'c'  : 'COMMAND',
          \ '' : 'V-BLOCK',
          \ 's'  : 'SELECT',
          \ 'S'  : 'S-LINE',
          \ '' : 'S-BLOCK',
          \ }, 'keep')

    call s:check_defined('g:airline_theme_map', {})
    call extend(g:airline_theme_map, {
          \ 'Tomorrow.*': 'tomorrow',
          \ 'mo[l|n]okai': 'molokai',
          \ 'wombat.*': 'wombat',
          \ '.*solarized.*': 'solarized',
          \ }, 'keep')

    call airline#extensions#load()

    if !exists('g:airline_section_a')
      let g:airline_section_a = airline#section#create_left(['mode', 'paste', 'iminsert'])
    endif
    if !exists('g:airline_section_b')
      let g:airline_section_b = airline#section#create(['hunks', 'branch'])
    endif
    let g:airline_section_c = airline#section#create(['%<', 'file'])
    let g:airline_section_gutter = airline#section#create([' ', 'readonly', '%='])
    let g:airline_section_x = airline#section#create(['tagbar', '%{&filetype}'])
    let g:airline_section_y = airline#section#create(['ffenc'])
    let g:airline_section_z = airline#section#create(['%3p%% %{g:airline_symbols.linenr} %3l:%3c '])
    let g:airline_section_warning = airline#section#create(['syntastic', 'whitespace'])

    let s:airline_theme_defined = exists('g:airline_theme')
    if s:airline_theme_defined || !airline#switch_matching_theme()
      let g:airline_theme = get(g:, 'airline_theme', 'dark')
      call airline#switch_theme(g:airline_theme)
    endif
  endif
endfunction

function! s:on_window_changed()
  if pumvisible()
    return
  endif
  call <sid>init()
  call airline#update_statusline()
endfunction

function! s:on_colorscheme_changed()
  call <sid>init()
  if !s:airline_theme_defined
    if airline#switch_matching_theme()
      return
    endif
  endif

  " couldn't find a match, or theme was defined, just refresh
  call airline#load_theme()
endfunction

function airline#cmdwinenter(...)
  call airline#extensions#apply_left_override('Command Line', '')
endfunction

function! s:airline_toggle()
  if exists("#airline")
    augroup airline
      au!
    augroup END
    augroup! airline
      if exists("s:stl")
        let &stl = s:stl
      endif
    else
      let s:stl = &stl
      augroup airline
        autocmd!

        autocmd CmdwinEnter *
              \ call airline#add_statusline_func('airline#cmdwinenter')
              \ | call <sid>on_window_changed()
        autocmd CmdwinLeave * call airline#remove_statusline_func('airline#cmdwinenter')

        autocmd ColorScheme * call <sid>on_colorscheme_changed()
        autocmd WinEnter,BufWinEnter,FileType,BufUnload,ShellCmdPost,VimResized *
              \ call <sid>on_window_changed()

        autocmd BufWritePost */autoload/airline/themes/*.vim
              \ exec 'source '.split(globpath(&rtp, 'autoload/airline/themes/'.g:airline_theme.'.vim', 1), "\n")[0]
              \ | call airline#load_theme()
      augroup END
      if s:airline_initialized
        call <sid>on_window_changed()
      endif
    endif
  endfunction

  function! s:get_airline_themes(a, l, p)
    let files = split(globpath(&rtp, 'autoload/airline/themes/'.a:a.'*'), "\n")
    return map(files, 'fnamemodify(v:val, ":t:r")')
  endfunction
  function! s:airline_theme(...)
    if a:0
      call airline#switch_theme(a:1)
    else
      echo g:airline_theme
    endif
  endfunction
  command! -nargs=? -complete=customlist,<sid>get_airline_themes AirlineTheme call <sid>airline_theme(<f-args>)
  command! AirlineToggleWhitespace call airline#extensions#whitespace#toggle()
  command! AirlineToggle call <sid>airline_toggle()

  call <sid>airline_toggle()

