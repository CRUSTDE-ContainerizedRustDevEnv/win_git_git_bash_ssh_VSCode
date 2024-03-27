# .bashrc is used by git-bash.exe to start a session
# Here we start ssh-agent.exe in a background process that is accessible from windows.
# It is used by ssh client, git and VSCode remote extension.

# Luciano 2024-03-17: I added some commands for my configuration of git-bash (for Rust development)
# ~/.bashrc is executed by bash for non-login interactive shells every time.  (not for login non-interactive scripts)

alias l="ls -al"
alias ll="ls -l"

# region: ssh-agent and sshadd

env=~/.ssh/agent.env

agent_load_env () { test -f "$env" && . "$env" | /dev/null ; }

agent_start () {
    (umask 077; ssh-agent >| "$env")
    . "$env" >| /dev/null ; }

agent_load_env

# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2= agent not running
agent_run_state=$(ssh-add -l >| /dev/null 2>&1; echo $?)

if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
    printf "  \033[33m Starting ssh-agent as a windows process in the background (look up in Task Manager)  \033[0m\n"
    agent_start
    # printf "Setting Windows SSH user environment variables (pid: $SSH_AGENT_PID, sock: $SSH_AUTH_SOCK)\n"
    setx SSH_AGENT_PID "$SSH_AGENT_PID" > /dev/null
    setx SSH_AUTH_SOCK "$SSH_AUTH_SOCK" > /dev/null
fi

printf "  \033[33m Use the global command 'sshadd' to simply add your private SSH keys to ssh-agent $SSH_AGENT_PID. \033[0m\n"
alias sshadd="printf 'sh ~/.ssh/sshadd.sh\n'; sh ~/.ssh/sshadd.sh"

# endregion: ssh-agent and sshadd

printf " \n"

unset env

# shorten the prompt
export PS1='\[\033[01;35m\]\u@git-bash\[\033[01;34m\]:\w\[\033[00m\]\$ '
