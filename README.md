# warp-directory
A powershell port of the ZSH utility Warp Directory (wd)

# Installation
- Create a folder in your PowerShell modules directory named `warp-directory`.  Drop this in.
- Execute `Import-Module warp-directory`

# Supported Commands
```
wd <warp-name>         Warp to the specified directory
wd add <name>          Add current directory as warp point
wd addcd <dir> [name]  Add warp point for specific directory
wd rm <name>           Remove warp point
wd list                List all warp points
wd ls <name>           List files in given warp point
wd path <name>         Show path of given warp point
wd show                List warp points for the current directory
wd clean [--force]     Remove warp points to non-existent directories
wd --version           Show version information
```
