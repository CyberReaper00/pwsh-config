# >>==========>> Terminal Greeting
Write-Host "Powershell Has Initiated" -Foreground DarkBlue
$user = whoami
if ($user -eq "nixos") {
    function prompt {"`e[1;34m$user ===$PWD===>>`n`e[0m"}
} elseif ($user -eq "root") {
    function prompt {"`e[1;31m$user ===$PWD===>>`n`e[0m"}
}

# >>==========>> Aliases
Set-Alias seal Set-Alias
seal rnit Rename-Item
seal show Get-ChildItem
seal B cd..
seal wh Write-Host

# >>==========>> Traversal Functions
function hm {
    cd ~/
}

function navs {
    nvim .
}

function open_editor {
    param (
	    [string]$editor,
	    [string]$flag
	  )

	if ($flag) {
	    $matched = show -File *$flag*
		if ($matched) {
		    & $editor $matched.Fullname
		} else {
		    wh "`n`tNo such file exists`n"
		}
	} else {
	    wh "`n`tPlease specify a file to open`n"
	}
}

function format {
    param (
	    [int]$w_len = 16,
	    [object[]]$items
	  )

	if ($items -and $items.Count -gt 0) {
	    $terminal_width = [math]::Floor($Host.UI.RawUI.BufferSize.Width * 0.98)
		$current_line = "`n⎪ "

		foreach ($entry in $items) {
		    $name = $entry.Name
			if ($name.Length -gt $w_len) {
			    $name = $name.Substring(0, $w_len - 3) + "..."
			} elseif ($name.Length -lt $w_len) {
			    $name = $name.PadRight($w_len)
			}

		    if (($current_line.Length + $name.Length) -gt $terminal_width) {
			wh $current_line
			    $current_line = "⎪ "
		    }

		    $current_line += " $name ⎪"
		}

	    if ($current_line -ne "") { wh $current_line }
	} else {
	    wh "`n`tNo such files found`n"
	}
}

function lsd {
    param (
	    [switch]$s,
	    [string]$name = @('none'),
	    [int]$len = 16
	  )

	if ($name -eq 'none') {
	    $matched = show -directory
		format $len $matched
	} elseif ($s -and $name) {
	    show -directory *$name*
	} else {
	    cd *$name*
	}
}

function lsf {
    param (
	    [switch]$nv,
	    [switch]$np,
	    [string]$file,
	    [int]$len = 16
	  )

	if ($nv) {
	    open_editor 'nvim' $file
	} elseif ($np) {
	    open_editor 'notepad' $file
	} elseif ($file) {
	    $matched = show -File *$file*
		format $len $matched
	} else {
	    $all_files = show -File
		format $len $all_files
	}
}

function codes {
    cd "/home/nixos/documents/code"
    ls
}

function vfiles {
    cd "/home/nixos/documents/veracity files"
    lsd
}

# >>==========>> Github Functions
function gadd {
    $files = (Read-Host 'Enter File Names').Split(',').Trim()
    git add $files
}

function gcomm {
    $message = Read-Host 'Enter Commit Message'
    git commit -m $message
}

function gpo {
    while ($true) {
	$branch = Read-Host 'Enter Branch'

	try {
	    git push -u origin $branch
	    break
	} catch {
	    wh "An error occurred, try again"
	}
    }
}

function gss {
    git status
}

function pgh {
    gadd
    gcomm
    gpo
}

function pegh {
    wh "Pushing Neovim Config"
    cd "/home/nixos/nixos/configs/nvim-config"
    pgh

    wh "Pushing Powershell Config"
    cd "/home/nixos/nixos/configs/pwsh-config"
    pgh

    wh "Pushing NixOS Config"
    cd "/home/nixos/nixos"
    pgh
}

# >>==========>> Editing Functions
function mkfile {
    param (
	    [string[]]$name
	  )
	New-Item -Path . -Name $name -ItemType "File"
}

function rmit {
    param (
	[switch]$r,
	[string[]]$name
    )
    if ($r) {
	rm -r *$name*
    } else {
	rm *$name*
    }
}

# >>==========>> Helper Functions
function qwe {
    exit
}

function p_split {
    param(
	    [string[]]$item = @(':')
	 )
	$env:PATH -split $item | ForEach-Object {$_}
}

function psrvr {
    param (
	    [int]$port = 8000 # Default value
	  )
	python -m http.server $port
}

function lcltnl {
    Param (
	    [int]$port = 8000
	  )
	cloudflared tunnel --url localhost:$port
}

function stop_proc {
    Param (
	    [string]$process
	  )
	Get-Process $process | Stop-Process -Force
}
