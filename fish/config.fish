
alias pamcan=pacman


set -x PAGER less
set -x EDITOR nvim
set -x VISUAL nvim

set -gx XDG_RUNTIME_DIR /run/user/$(id -u)

# set -gx GOPATH $HOME/go
# set -gx CARGO_HOME $HOME/.cargo
# set -gx JAVA_HOME /usr/lib/jvm/java-21-graalvm
# set -gx SYMFONY $HOME/.symfony5

set -x CFLAGS "-I/usr/include"
set -x LDFLAGS "-L/usr/lib"

# path
# set -gx PATH $HOME/.local/bin $PATH
# set -gx PATH $CARGO_HOME/bin $PATH
set -gx PATH $GOPATH/bin $PATH
set -gx PATH $JAVA_HOME/bin $PATH
set -gx PATH $SYMFONY/bin $PATH



# enable ibus bamboo start with system
set -gx WAYLAND_DISPLAY wayland-0
set -gx GDK_BACKEND wayland,x11
set -gx QT_QPA_PLATFORM wayland

# electron app
set -gx ELECTRON_OZONE_PLATFORM wayland


starship init fish | source

set -gx PATH "/run/user/1000/fnm_multishells/11015_1745077986855/bin" $PATH;
set -gx FNM_MULTISHELL_PATH "/run/user/1000/fnm_multishells/11015_1745077986855";
set -gx FNM_VERSION_FILE_STRATEGY "local";
set -gx FNM_DIR "/home/phuoc/.local/share/fnm";
set -gx FNM_LOGLEVEL "info";
set -gx FNM_NODE_DIST_MIRROR "https://nodejs.org/dist";
set -gx FNM_COREPACK_ENABLED "false";
set -gx FNM_RESOLVE_ENGINES "true";
set -gx FNM_ARCH "x64";



set fzf_fd_opts --hidden --max-depth 5 --no-ignore

# Set up fzf key bindings
fzf --fish | source
