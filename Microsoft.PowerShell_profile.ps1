# >>==========>> Terminal Greeting
Write-Host "Powershell Has Initiated" -Foreground DarkBlue

# Shell Instance Counter
function shell_depth {
    $depth = 0
    $crnt_pid = $PID 

    while ($true) {
	$ppid = (Get-Content "/proc/$crnt_pid/status" | Where-Object { $_ -like "PPid:*" }) -replace 'PPid:\s*', ''
	if (-not (Test-Path "/proc/$ppid")) { break }

	$parent = (Get-Content "/proc/$ppid/comm" -ErrorAction SilentlyContinue)
	if ($parent -eq "pwsh") {
	    $depth++
	    $crnt_pid = $ppid
	} else {
	    break
	}
    }

    return $depth
}

function prompt_change {
    param (
	[int]$color,
	[string]$username,
	[int]$depth_val
   )

    # "`e[1;${color}m[$username] [$depth_val] ===$PWD===>>`n`e[0m"
    "`e[1;${color}m<| |===|$username|===|$depth_val|===$PWD/===| |>`n`e[0m"
}


$user = whoami
$depth = shell_depth
$nix_check = $env:IN_NIX_SHELL

function prompt {
    if ($nix_check) {
	prompt_change 32 "nix-shell" $depth
    } else {
	if ($user -eq "nixos") {
	    prompt_change 34 $user $depth
	} elseif ($user -eq "root") {
	    prompt_change 31 $user $depth
	}
    }
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
	git push -u origin $branch

	if ($LASTEXITCODE -eq 0) {
	    break
	} elseif ($branch -eq "") {
	    break
	} else {
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
#╭╮╰╯│─├
function header {
    param (
	[string]$name
    )

    $name_len = $name.Length
    $width = $name_len + 12
    $border = "─" * $width
    $spacing = $width - $name_len
    $content = (" " * [int]($spacing/2)) + $name + (" " * [int]($spacing/2))

    wh @"


	    ╭${border}╮
            │${content}│
            ╰${border}╯
"@
}

function pegh {
    header "Pushing Neovim Config"
    cd "/home/nixos/nixos/configs/nvim-config"
    pgh

    header "Pushing Powershell Config"
    cd "/home/nixos/nixos/configs/pwsh-config"
    pgh

    header "Pushing NixOS Config"
    cd "/home/nixos/nixos"
    pgh
}

function ssall {
    header "Checking Neovim Config"
    cd "/home/nixos/nixos/configs/nvim-config"
    gss

    header "Checking Powershell Config"
    cd "/home/nixos/nixos/configs/pwsh-config"
    gss

    header "Checking NixOS Config"
    cd "/home/nixos/nixos"
    gss
}

# >>==========>> Editing Functions
function mkfile {
    param (
	    [string]$name
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

function shell {
    param (
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$args
    )
    $args1 = $args.Split(' ').Trim()
    nix-shell --command pwsh $args1
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
