# theme powerlevel9k setup
# command line 左邊想顯示的內容
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir dir_writable vcs vi_mode) # <= left
# command line 右邊想顯示的內容
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status history ram time) # <= right
#
# nvm setup
source ~/.nvm/nvm.sh
#
# fuck setup 
eval $(thefuck --alias)
#
# You can use whatever you want as an alias, like for Mondays:
eval $(thefuck --alias FUCK)
#
# set default EDITOR
export EDITOR=vim
#
# add my bin PATH
export PATH=$PATH:$HOME/wxsbin
#
# welcome 
welcomewords
#
#java run env
export JAVA_HOME="/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home"
#
#pyenv setup
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

