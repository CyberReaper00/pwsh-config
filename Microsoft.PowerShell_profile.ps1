# >>==========>> Terminal Greeting
Write-Host "`e[2J`e[H"
Write-Host "Powershell Has Initiated" -Foreground DarkBlue
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineKeyHandler -Key 'Alt+p' -Function AcceptSuggestion

function update {
    param (
	[switch]$c,
	[string]$config_name
    )

    Write-Host "`e[2J`e[H"
    if ( -not $config_name ) {
	Write-Error "Error: Config name was not specified..."
    } else {
	if ( $c ) {
	    Write-Host "Updating Flake...`n"
	    sudo nixos-rebuild switch --flake /home/nixos/nixos#$config --impure
	} else {
	    Write-Host "Updating System...`n"
	    sudo nix flake update --flake /home/nixos/nixos --impure
	    sudo nixos-rebuild switch --flake /home/nixos/nixos#$config --impure
	}
    }
}

#╭╮╰╯│─├
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
    "`n`e[1;${color}m<| ||===|$username|===|$depth_val|===$PWD/===|| |>`e[0m`n`n"
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
    cd "/home/nixos/Documents/Code"
    ls
}

function vfiles {
    cd "/home/nixos/Documents/Veracity Files"
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
    cd "/home/nixos/nixos/user_configs/nvim_config"
    gss
    pgh

    header "Pushing Powershell Config"
    cd "/home/nixos/nixos/user_configs/pwsh_config"
    gss
    pgh

    header "Pushing NixOS Config"
    cd "/home/nixos/nixos"
    gss
    pgh
}

function ssall {
    header "Checking Neovim Config"
    cd "/home/nixos/nixos/user_configs/nvim_config"
    gss

    header "Checking Powershell Config"
    cd "/home/nixos/nixos/user_configs/pwsh_config"
    gss

    header "Checking NixOS Config"
    cd "/home/nixos/nixos"
    gss
}

# >>==========>> Editing Functions
function mkfile {
    param (
	[string]$dir,
	[string[]]$names
    )
    
    foreach ($name in $names) {
	New-Item -Path $dir -Name $name -ItemType "File"
    }
}

function rmit {
    param (
	[switch]$r,
	[string[]]$names
    )

    foreach ($name in $names) {
	if ($r) {
	    rm -r *$name*
	} else {
	    rm *$name*
	}
    }
}

# >>==========>> Helper Functions
function qwe {
    exit
}

function shell {
    param (
	[Parameter(ValueFromRemainingArguments = $true)]
	[string]$args
    )
    if ($args -eq "") {
	nix-shell --command pwsh
    } else {
	$args1 = $args.Split(' ').Trim()
	nix-shell --command pwsh -p $args1
    }
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

function conv_hex {
    param (
	[string[]]$values
    )
    $colors = $values.Split(" ")

    wh ""
    foreach ($color in $colors) {
	$hex = $color.Split("#")[-1]
	$r = [Convert]::ToInt32($hex.Substring(0,2), 16)
	$g = [Convert]::ToInt32($hex.Substring(2,2), 16)
	$b = [Convert]::ToInt32($hex.Substring(4,2), 16)

	wh "`e[48;2;${r};${g};${b}m      `e[0m │ HEX: #${hex}"
    }
}

function hta {
    param (
	[string]$hex
    )

    $text = ""
    for ($i = 0; $i -lt $hex.Length; $i += 2) {
	$char = [char]([Convert]::ToInt32($hex.Substring($i, 2), 16))
	$text += $char
    }
    return $text
}

function rndev {
    param (
	[switch]$h,
	[switch]$info,
	[string]$ftype,
	[string]$dev_name,
	[string]$new_name
    )

    if ( $h ) {
	wh "usage: [ PARAMS... ] [ -h ] [ -info ]"
	wh "`nPARAMS: | All parameters are necessary |"
	wh "[ filesystem ]`tIn this, the filesystem of the device should be written`n`tAccepted formats are 'fat32', 'vfat', 'ext2', 'ext3', 'ext4', 'ntfs'`n"
	wh "[ /dev/name ]`tIn this, the device name of the device should be written`n`tExample: /dev/sda1, /dev/sdc3 etc.`n"
	wh "[ new_name ]`tIn this, the new name that will be given to the drive should be written`n`tExample: 'New Drive', 'something different' etc."
	wh "`nFLAGS:"
	wh "-h`tDisplays this help message"
	wh "-info`tDisplays all info on every connected storage device"
    }
    elseif ( $info ) {
	blkid | sort | awk '{print $1; for (i=2; i<=NF; i++) printf "%s%s", $i, (i==NF ? "" : OFS); print ""; print ""}' | sed 's/://'}
    elseif ( $ftype -eq "" -and $dev_name -eq "" -and $new_name -eq "" ) {
	wh "No parameters were provided, use -h for help"
    }
    else {
	try { sudo umount $dev_name }
	catch { Write-Error "Failed to unmount $dev_name. Ensure its not in use"; return }

	if ( $ftype -eq "fat32" -or "vfat" ) { sudo mlabel "-i" $dev_name "::$new_name" }
	elseif ( $ftype -eq "ext2" -or $ftype -eq "ext3" -or $ftype -eq "ext4" ) { sudo e2label $dev_name $new_name }
	elseif ( $ftype -eq "ntfs" ) { sudo ntfslabel $dev_name $new_name }
	else { Write-Error "Unsupported filesystem type: $ftype`n" }
    }
}

function csn {
    param (
	[switch]$o,
	[switch]$n
    )
    if ($o) {
	mv 'slock.c' '11slock.c'
	mv 'config.def.h' '11config.def.h'
	mv 'config.mk' '11config.mk'

	mv 'orig.c' 'slock.c'
	mv 'orig.h' 'config.def.h'
	mv 'orig.mk' 'config.mk'
    } elseif ($n) {
	mv 'slock.c' 'orig.c'
	mv 'config.def.h' 'orig.h'
	mv 'config.mk' 'orig.mk'

	mv '11slock.c' 'slock.c'
	mv '11config.def.h' 'config.def.h'
	mv '11config.mk' 'config.mk'
    }
}

function rfd {
    param (
	[string]$arg
    )

    $loc = Get-Location
    cd /
    fd $arg
    cd $loc
}

function nkl {
    param (
	[string]$file = ""
    )

    if ($file) {
	$loc = Get-Location
	cd
	nvim $loc'/'$file
	cd $loc
    } else {
	$loc = Get-Location
	cd
	nvim
	cd $loc
    }
}
