# Force UTF-8 environment
set -gx LANG en_IN.UTF-8
set -gx LC_ALL en_IN.UTF-8

# Commands to run in interactive sessions can go here
if status is-interactive
    fastfetch
    # No greeting
    set fish_greeting ''

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end
    
    # Colors
    if test -f ~/.local/state/matugen/user/generated/terminal/sequences.txt
        cat ~/.local/state/matugen/user/generated/terminal/sequences.txt
    end
    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias btop 'command btop --force-utf'
    if test "$TERM" != "linux"
        alias ls 'eza --icons=auto'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
    function agy
        if test (count $argv) -eq 0
            cd ~/Documents
            command agy
        else if test -d "$argv[1]"
            cd "$argv[1]"
            command agy $argv[2..-1]
        else
            command agy $argv
        end
    end
    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and test -n "$cwd"; and test "$cwd" != "$PWD"
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

    # Fast directory jumping with zoxide (z <folder-fragment>, zi for interactive)
    zoxide init fish | source

    # Native fzf integration
    fzf --fish | source

    # Search user files and directories only (skip hidden dotfiles/caches like .gemini, .cargo, .cache)
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --exclude .git'
    set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
    set -gx FZF_ALT_C_COMMAND 'fd --type d --exclude .git'

    # Fuzzy find any file in ~/Documents and insert its path at cursor via Ctrl+F
    function fzf-documents-widget
        set -l file (fd --type f . ~/Documents | fzf --preview 'bat --style=numbers --color=always --line-range :500 {}')
        if test -n "$file"
            commandline -i (string escape -- "$file")
        end
        commandline -f repaint
    end

    function fish_user_key_bindings
        fzf_key_bindings
        bind \cf fzf-documents-widget
        bind -M insert \cf fzf-documents-widget
    end

    # Let cd find folders inside ~/Documents without typing the full path
    set -g CDPATH . ~/Documents ~
    for f in ~/.local/state/*/user/generated/terminal/sequences.txt
        test -f $f; and cat $f
    end
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f $HOME/miniconda3/bin/conda
    eval $HOME/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
        . "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "$HOME/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<



# Added by Antigravity CLI installer
set -gx PATH "$HOME/.local/bin" $PATH

fish_add_path $HOME/.spicetify
