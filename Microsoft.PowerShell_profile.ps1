Write-Host "Powershell Has Initiated" -Foreground DarkBlue

# >>==========>> Aliases

Set-Alias seal Set-Alias
seal rnit Rename-Item
seal rmit Remove-Item
seal show Get-ChildItem
seal bk	cd..
seal wh Write-Host

# >>==========>> Aliases

# >>==========>> Traversal Functions

function hm {
    cd ~/
}

function navs {
    nvim .
}

function lsd {
    param (
	    [switch]$gt,
	    [string]$name = @('none')
	  )

	if ($name -eq 'none') {
	    show -directory
	} elseif ($gt -and $name) {
	    cd *$name*
	} else {
	    show -directory *$name*
	}
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
	[object[]]$items,
	[int]$w_len = 16
    )

    if ($items -and $items.Count -gt 0) {
	$terminal_width = [math]::Floor($Host.UI.RawUI.BufferSize.Width * 0.8)
	$current_line = "`n| "

	foreach ($entry in $items) {
	    $name = $entry.Name
	    if ($name.Length -gt $w_len) {
		$name = $name.Substring(0, $w_len - 3) + "..."
	    } elseif ($name.Length -lt $w_len) {
		$name = $name.PadRight($w_len)
	    }

	    if (($current_line.Length + $name.Length) -gt $terminal_width) {
		wh $current_line
		$current_line = "| "
	    }

	    $current_line += " $name |"
	}

	if ($current_line -ne "") { wh $current_line }
    } else {
	wh "`n`tNo such files found`n"
    }
}

function lsf {
    param (
	    [switch]$nv,
	    [switch]$np,
	    [string]$file
	  )

	if ($nv) {
	    open_editor 'nvim' $file
	} elseif ($np) {
	    open_editor 'notepad' $file
	} elseif ($file) {
	    $matched = show -File *$file*
	    format $matched
	} else {
	    $all_files = show -File
	    format $all_files
	}
}

function codes {
    cd 'C:\users\windows 11\documents\code'
	ls
}

function lad {
    cd $env:LOCALAPPDATA
}

function nplgn {
    cd 'C:\tools\neovim\nvim-win64\share\nvim\runtime\plugin'
	ls
}

function vfiles {
    cd 'C:\users\windows 11\documents\veracity files'
	lsd
}

function startup {
    cd 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup'
}

function admin {
    Start-Process powershell -Verb runAs
}

# >>==========>> Traversal Functions

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
    $branch = Read-Host 'Enter Branch'
	git push -u origin $branch
}

function pushprfl {
    cd 'C:\Users\Windows 11\documents\windowspowershell'
	pgh
}

function gss {
    git status
}

function pgh {
    gadd
	gcomm
	gpo
}

# >>==========>> Github Functions

# >>==========>> Editing Functions

function prfl {
    nvim $PROFILE
}

function nconf {
    cd 'C:\users\windows 11\appdata\local\nvim'
	nvim init.lua
}

function mkfile {
    param (
	    [string[]]$name
	  )
	New-Item -Path . -Name $name -ItemType "File"
}

# >>==========>> Editing Functions

# >>==========>> Helper Functions

function qwe {
    exit
}

function cloc {
    Get-Location | Select-Object -ExpandProperty Path | clip
}

function iop {
    explorer .
}

function path_split {
    param(
	    [string[]]$item
	 )
	$env:PATH -split $item | ForEach-Object {$_}
}

function psrvr {
    param (
	    [int]$port = 8000 # Default value
	  )
	python -m http.server $Port
}

function lcltnl {
    Param (
	    [int]$port = 8000
	  )
	cloudflared tunnel --url localhost:$Port
}
# >>==========>> Helper Functions



