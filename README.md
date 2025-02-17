# win_git_git_bash_ssh_VSCode

**Windows utils for CRUSTDE: git, git-bash, SSH, VSCode**  
***version: 2024.323.1347 date: 2024-03-23 author: [bestia.dev](https://bestia.dev) repository: [GitHub](https://github.com/CRUSTDE-ContainerizedRustDevEnv/win_git_git_bash_ssh_VSCode)***  

 ![tutorial](https://img.shields.io/badge/tutorial-yellow)
 ![License](https://img.shields.io/badge/license-MIT-blue.svg)
 ![win_git_git_bash_ssh_VSCode](https://bestia.dev/webpage_hit_counter/get_svg_image/1099152408.svg)

**WARNING !!! This is a public repository: never write or save secrets here!!!**

 ![logo](https://raw.githubusercontent.com/CRUSTDE-ContainerizedRustDevEnv/CRUSTDE_Containerized_Rust_DevEnv/main/images/crustde_250x250.png)
 win_git_git_bash_ssh_VSCode is a member of the [CRUSTDE-ContainerizedRustDevEnv](https://github.com/orgs/CRUSTDE-ContainerizedRustDevEnv/repositories?q=sort%3Aname-asc) project.

 [![Lines in md](https://img.shields.io/badge/Lines_in_markdown-267-green.svg)](https://github.com/CRUSTDE-ContainerizedRustDevEnv/win_git_git_bash_ssh_VSCode/)

Hashtags: #rustlang #tutorial #buildtool #developmenttool  
My projects on GitHub are more like a tutorial than a finished product: [bestia-dev tutorials](https://github.com/bestia-dev/tutorials_rust_wasm).

## Git for Windows and git-bash

Git is the legendary version control and I use it everywhere: in Windows, Debian and inside the CRUSTDE container.  
In Windows, install from <https://git-scm.com/download/win>  

When you install Git for Windows it comes prepacked with Git Bash, a Linux terminal emulator. Git Bash is particularly useful because it lets you run both Linux and Windows commands from the same terminal and access the underlying Windows file system.

I will use git-bash for all my terminal needs in Windows. I despise command prompt and PowerShell. Avoid them as much as possible.  

Add to Windows env var path ( right-click on Start - System- Advanced system settings - Environment variables - User variables - Path - Edit - New...)  
`C:\Program Files\Git`  
So the command `git-bash` will work globally in Windows.  

Config git in `git-bash`:

```bash
git --version
# git version 2.44.0.windows.1
ssh -V
# OpenSSH_9.6p1, OpenSSL 3.2.1 30 Jan 2024

# config git globally
git config --global user.name "Your Name"
git config --global user.email "youremail@yourdomain.com"
# for Windows only:
git config --global core.eol lf
git config --global core.autocrlf input
# VSCode is my primary editor
git config --global core.editor "C:\Users\luciano\AppData\Local\Programs\Microsoft VS Code\bin\code" --wait
git config --global -l
```

## git-bash and path conversion

Very sadly, the paths in Windows are different than the paths in Linux.  
Unix came first, so I blame Microsoft for not sticking to the standard. Microsoft being Microsoft, has to "EEE" Embrace, Extend, and Extinguish. Instead of a natural `/` slash they decided to use `\` backslash. Just so to be different. I am sure there was no other reason. They repeated this strategy over and over again with different standards.  

Now that we have `bash` inside windows this was a tough thing to solve. The solution is "path conversion". When `git-bash` finds the `/` slash symbol it assumes it is a path and makes the conversion. So `/home/foobar/` becomes `C:/Users/user/AppData/Local/Git/home/foobar`. Horrible, but it works for Linux commands because they don't use `/` for anything else, just paths.

If we want to run some Windows commands inside `git-bash` it becomes a problem because Microsoft decided that using `/` for arguments is very smart. Bad Microsoft.

The solution is to use a special environment variable to disable the path conversion: MSYS_NO_PATHCONV. If this variable exists (the content does not matter at all) then `git-bash` does not perform path conversion.

Running one Windows command inside `git-bash`:

```bash
# set env var just for one command
MSYS_NO_PATHCONV=1 dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

Running many Windows commands inside `git-bash`:

```bash
# export env var for many command and unset it after
export MSYS_NO_PATHCONV=1

dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --set-default-version 2

unset MSYS_NO_PATHCONV
```

With this knowledge, we are ready to run Linux and Windows commands from `git-bash` and avoid using Command prompt and PowerShell at all.

## SSH in Windows (Git SSH)

SSH is great. In Linux, it works seamlessly. In Windows, it came late to the party and this brought some problems.

### Remove incompatible solutions

**WARNING:** there are many incompatible SSH solutions for Windows and it can be a mess if there is more than one solution installed. I chose to use only the **SSH** that comes with [git for Windows](https://git-scm.com/download/win).  

1. First I removed the "OpenSSH components in Optional Features".  
In `Manage Optional Features` uninstall OpenSSH client and Server. They are some old versions anyway. Sadly, it will leave some files behind:  
Delete the folder `c:\Windows\System32\OpenSSH\`. The owner is TrustedInstaller, so first you have to change the owner to you and then give permission to administrators to have Full Control. Then you can finally delete it as administrator.

2. I tried and disliked the newer OpenSSH from `Winget search "Openssh beta"`. Microsoft was so bold to store the private SSH keys "unprotected" in the registry. So they survive a reboot of the system. That is shockingly different from the way ssh-agent works in Linux. Bad Microsoft! Unsecure by default!  
Uninstalled it with `Winget uninstall "Openssh beta"`  
Check if the folder `c:\Program Files\OpenSSH` does not exist.

3. Check if git for Windows didn't change the default ssh executable.
If misconfigured, this could disallow VSCode to push to GitHub.  

```bash
git config --get core.sshCommand
```

This must return "empty".  
And check that the env variable GIT_SSH is not set in git-bash.

```bash
printf "$GIT_SSH\n"
```

This must return "empty".

4. To be sure, I searched all my `C:` disks and found only one `ssh.exe` in `C:\Program Files\Git\usr\bin\ssh.exe`. Good!

### ssh-agent in Windows

Every time I connect over SSH I must input the passphrase for my SSH identity. Even `git push` works over SSH, so every time I have to input the password. This is great for security, but it is an awful user experience. You can choose to be less secure with some ssh keys and be more productive with ssh-agent. Your choice.  

Git-bash comes with `ssh-agent` and I could use it just the same as in Linux bash to avoid retyping the passphrase every time. ssh-agent asks for the passphrase only once and then stores securely the unencrypted private key in memory until the session is terminated or the timeout expires.  

I want the ssh-agent to start when I manually run the git-bash console. I wrote a little script in `~/.bashrc` file for git-bash in Windows. Find the code [here](configuration_files/win_files/c/Users/luciano/.bashrc).  

Maybe it looks confusing, but git-bash by default translates Linux paths into Windows paths. `~` is the home folder and slash `/` instead of the `\` backslash. Smart!  

Now every time I open the terminal for `git-bash` it will start the agent. Use the command `sshadd` to store the ssh keys in ssh-agent.  
The ssh-agent is a Windows background process. It retains the keys in memory until we stop the process or command `ssh-add -D`. And most important, it cannot survive a reboot of any kind.  

Warning: Git-bash and ssh-agent must run before VSCode. If a window of VSCode is opened before, it will not use it. Nor the newly opened Windows of VSCode. Close all VSCode Windows and try again.

### SSH config for Windows

It is recommended to use the `~/.ssh/config` file to assign explicitly one ssh key to one ssh server.  
If not, the ssh-agent will send all the keys to the server and the server could refute the connection because of too many bad keys.  

In Windows, I use SSH for:

- connect over SSH to CRUSTDE - Containerized Rust Development Environment
- push to GitHub over SSH  
- sync files with my Web server on Google Cloud

This configuration worked for me:

I have 2 separate config files for Windows and WSL, but I use only the private keys from inside WSL. So I don't have to copy them into Windows.  
In Linux `~\.ssh\config` I used the paths like `~/.ssh/key`.

In Windows "C:\Users\luciano\.ssh\config" I used the paths like `//wsl.localhost/Debian/home/luciano/.ssh/key`. Find the code [here](configuration_files/win_files/c/Users/luciano/.ssh/config).

### Unsuccessful combinations

1. I tried to use SSH from WSL and it didn't work just because the path of `~/.ssh/config` in Windows is different than the path in Linux. If this small difference could be overcome somehow (in the VSCode extension), it would probably work! Abandoned!

2. I tried to use the git-bash ssh with the config from WSL. It didn't work because the paths inside the config are different in Windows than the paths in Linux. Not working!

3. Standard ssh-add has some options like -c and -t, but they are not recognized by the Windows ssh. Instead of a reasonable error, it writes only that the agent failed. Then you have to guess why and spend a lot of time experimenting. Bad error messages!  

## VSCode for Windows

<https://code.visualstudio.com/download>  
Backup and sync settings with my GitHub account bestia-dev.  

WARNING: Don't install `WSL extension``. It is not needed for work in WSL folders from Windows and it disables the remote ssh connection for VSCode!  

I have an opinionated configuration file I use:  
I want git-bash to be my default terminal inside VSCode for Windows.  
In VSCode I specify the use of Git ssh-agent and config files explicitly, to avoid any confusion.  
I want always to use LF instead of CRLF.  
And so on...

Press F1 - Preferences: Open user settings (JSON) and add the json template from [here](configuration_files/win_files/c/Users/luciano/AppData/Roaming/Code/User/settings.json).  

## VSCode extensions

My favorite extensions for VSCode:

- [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)
- [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer)
- [markdownlint](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint)
- [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker)
- [crates](https://marketplace.visualstudio.com/items?itemName=serayuzgur.crates)
- [Live Preview](https://marketplace.visualstudio.com/items?itemName=ms-vscode.live-server)
- [XML Tools](https://marketplace.visualstudio.com/items?itemName=DotJoshJohnson.xml)

### VSCode Markdown

One peculiarity of Markdown is that a single NewLine is completely ignored and transformed into a space.  
If you want to make a new paragraph you need to write 2 Newlines characters and that is ok.  
But if you want a `<br>` soft-newline then you need to write space+space+newline. This is very peculiar.  
I like this soft-newline a lot and use it very often. But it is very easy to forget and impossible to see because space is invisible.  
I created a shortcut `ctrl+shift+ć` that opens a `search and replace` with the regex to correct this if I forgot it somewhere.  

Write key bindings in "C:\Users\luciano\AppData\Roaming\Code\User\keybindings.json".  
Find the code [here](configuration_files/win_files/c/Users/luciano/AppData/Roaming/Code/User/keybindings.json).

## Rust on Windows

I don't want to install rust on my Windows machine.  
I will try to use [cross-compile inside the CRUSTDE container](https://github.com/CRUSTDE-ContainerizedRustDevEnv/cross_compile_crustde_container).  

## LF or CRLF

Linux uses end-of-line (EOL) LF, but Windows uses CRLF. It can be super confusing because some tools even make auto-corrections and magically transform them.  
I want to have LF everywhere. It makes sense.  
In VSCode I changed the setting `files.eol` to LF. So, this is fixed for new files.  
In Windows, I fixed `git` to always use LF:

```bash
# globally
 git config --global core.eol lf
 git config --global core.autocrlf input
 ```

Just once, in every project separately I used dos2unix to repair if there were CRLF:

```bash
 git rm --cached -r . 
 git reset --hard
 
 copy ..\dos2unix.exe .  
 for /R %G in (*.txt) do dos2unix "%G"
 for /R %G in (*.md) do dos2unix "%G"
 for /R %G in (*.rs) do dos2unix "%G"
 for /R %G in (*.toml) do dos2unix "%G"
 for /R %G in (*.html) do dos2unix "%G"
 for /R %G in (*.css) do dos2unix "%G"
 for /R %G in (*.js) do dos2unix "%G"
 for /R %G in (*.svg) do dos2unix "%G"
 for /R %G in (*.json) do dos2unix "%G"
 for /R %G in (*.yml) do dos2unix "%G"
 for /R %G in (LICENSE) do dos2unix "%G"
 for /R %G in (.gitignore) do dos2unix "%G"
 del dos2unix.exe
 ```

Nowadays I put this file `.gitattributes` in every project:

```conf
# Specific git config for the project

# Declare files that will always have LF line endings on checkout.
*.rs text eol=lf
*.toml text eol=lf
*.md text eol=lf
*.json text eol=lf
*.json5 text eol=lf
*.lock text eol=lf
*.yml text eol=lf
*.html text eol=lf
*.js text eol=lf
*.css text eol=lf
LICENSE text eol=lf
.gitignore text eol=lf
.gitattributes text eol=lf
```

## Open-source and free as a beer

My open-source projects are free as a beer (MIT license).  
I just love programming.  
But I need also to drink. If you find my projects and tutorials helpful, please buy me a beer by donating to my [PayPal](https://paypal.me/LucianoBestia).  
You know the price of a beer in your local bar ;-)  
So I can drink a free beer for your health :-)  
[Na zdravje!](https://translate.google.com/?hl=en&sl=sl&tl=en&text=Na%20zdravje&op=translate) [Alla salute!](https://dictionary.cambridge.org/dictionary/italian-english/alla-salute) [Prost!](https://dictionary.cambridge.org/dictionary/german-english/prost) [Nazdravlje!](https://matadornetwork.com/nights/how-to-say-cheers-in-50-languages/) 🍻

[//bestia.dev](https://bestia.dev)  
[//github.com/bestia-dev](https://github.com/bestia-dev)  
[//bestiadev.substack.com](https://bestiadev.substack.com)  
[//youtube.com/@bestia-dev-tutorials](https://youtube.com/@bestia-dev-tutorials)  
