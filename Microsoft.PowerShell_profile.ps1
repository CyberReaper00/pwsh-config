# >>==========>> Terminal Greeting
Write-Host "`e[2J`e[H"
Write-Host "Powershell Has Initiated" -Foreground DarkBlue
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineKeyHandler -Key 'Alt+p' -Function AcceptSuggestion

# >>==========>> Aliases
Set-Alias seal Set-Alias
seal rnit Rename-Item
seal show Get-ChildItem
seal b cd..
seal wh Write-Host

# >>==========>> Customization

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

# >>==========>> Traversal Functions
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
	    [switch]$mp,
	    [string]$file,
	    [int]$len = 16
	  )

	if ($nv) {
	    open_editor 'nvim' $file
	} elseif ($np) {
	    open_editor 'mousepad' $file
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

function gt {
	param (
		[string]$loc
	)

	if ( -not $loc ) { write-error "No argument was given"; return; }

	cd
	$places = fd --hidden $loc
    for ($i = 0; $i -lt $places.Count; $i++) { write-host "[$($i+1)] $($places[$i])" }
	write-host ""

	$choice = ""
	for ($choice.GetType().Name -ne "Int32") {

		$input_ = read-host "Choose location"
		try	  { $choice = [Int32]$input_ }
		catch { write-error "Value must be a number, try again..."; continue; }

		if ( [int]$input_ -gt $places.Count ) { write-error "Value out of bounds..."; continue; }
		elseif ( [int]$input_ -eq 0 ) { write-error "Value out of bounds"; continue; }
		break
	}

	$path = $places[$choice - 1]
	$target = split-path -path $path -parent
	cd $target
}

# >>==========>> Github Functions
function gcr {
    param (
		[switch]$e
    )

    $link = (Read-Host 'Enter remote repo link').Trim()

    git init
    git branch -m main
    git remote add origin $link

    if ($e) {
		git pull --rebase origin main
		git add .
		git commit -m "New commit"
		git push --set-upstream origin main
    }
}

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

		if ($LASTEXITCODE -eq 0) { break }
		elseif ($branch -eq "") { break }
		else { wh "An error occurred, try again" }
    }
}

function gss { git status }

function pgh {
    gadd
    gcomm

	wh "`nPushing to github"
    gpo

	wh "`nRepo push was successful"
	Start-Sleep -Seconds 1
}

function pnver {
	$version = read-host "Enter version number"
	pgh
	git tag -a $version -m " "
	git push --tags
}

function header { #╭╮╰╯│─├
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
    write-host "`e[2J`e[H"
    header "Pushing Neovim Config"
    cd "/home/nixos/nixos/user_configs/nvim_config"
    gss
    pgh

    write-host "`e[2J`e[H"
    header "Pushing Powershell Config"
    cd "/home/nixos/nixos/user_configs/pwsh_config"
    gss
    pgh

    write-host "`e[2J`e[H"
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
    
    foreach ($name in $names) { New-Item -Path $dir -Name $name -ItemType "File" }
}

function rmit {
    param (
		[switch]$r,
		[string[]]$names
    )

    foreach ($name in $names) {
		if ($r) { rm -r *$name* }
		else { rm *$name* }
    }
}

function rem {
	param (
		[string[]]$files
	)

	foreach ($file in $files) { mv $file ~/.trash/$file }
}

function tr {
	param (
		[switch]$c, 	# Check for files in trash
		[switch]$r,		# Restore file to current directory
		[switch]$e,		# Empty trash
		[string]$file,
		[string]$path
	)

	$file_check = ls ~/.trash
	if (-not $file_check) { wh "`tTrash is empty"; return; }

	if ($c) { ls ~/.trash }
	elseif ($r -and $file -and $path) { mv ~/.trash/$file $path }
	elseif ($e) { rm -rf ~/.trash/* }
	else { Write-Error "Proper arguments were not specified"; return; }
}

# >>==========>> Helper Functions
function qwe { exit }

function shell {
    param (
		[string]$args_
    )

    if ($args_ -eq "") { nix-shell --command pwsh }
	else {
		$args1 = $args_.Split(' ').Trim()
		nix-shell -p $args1 --command pwsh
    }
}

function p_split {
    param(
	    [string[]]$item = @(':')
	 )
	
	$env:PATH -split $item | ForEach-Object {$_}
}

function psrvr { python ~/Documents/Code/custom_server.py }

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

function rnd { # re-name drive
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

		wh "`n[ filesystem ]`tIn this, the filesystem of the device should be written`n`t" +
			"Accepted formats are 'fat32', 'vfat', 'ext2', 'ext3', 'ext4', 'ntfs'"

		wh "`n[ /dev/name ]`tIn this, the device name of the device should be written`n`t" +
			"Example: /dev/sda1, /dev/sdc3 etc."

		wh "`n[ new_name ]`tIn this, the new name that will be given to the drive should be written`n`t" +
			"Example: 'New Drive', 'something different' etc."

		wh "`nFLAGS:"
		wh "-h`tDisplays this help message"
		wh "-info`tDisplays all info on every connected storage device"
    }
    elseif ( $info ) {
		blkid | sort | awk '{print $1; for (i=2; i<=NF; i++)' +
		'printf "%s%s", $i, (i==NF ? "" : OFS); print ""; print ""}' | sed 's/://'
	}
    elseif ( $ftype -eq "" -and $dev_name -eq "" -and $new_name -eq "" ) {
		wh "No parameters were provided, use -h for help"
    }
    else {
		try { sudo umount $dev_name }
		catch { Write-Error "Failed to unmount $dev_name. Ensure its not in use"; return; }

		if ( $ftype -eq "fat32" -or "vfat" ) { sudo mlabel "-i" $dev_name "::$new_name" }
		elseif ( $ftype -eq "ext2" -or $ftype -eq "ext3" -or $ftype -eq "ext4" ) { sudo e2label $dev_name $new_name }
		elseif ( $ftype -eq "ntfs" ) { sudo ntfslabel $dev_name $new_name }
		else { Write-Error "Unsupported filesystem type: $ftype`n" }
    }
}

function nm { # new mount
    param (
		[switch]$h,
		[switch]$info,
		[string]$device,
		[string]$dir_name
    )

	$hostname = hostname
    $path = "/run/media/$hostname/$dir_name"

	if ( $h ) {
		wh "usage: [ PARAMS... ] [ -h ] [ -info ]"
		wh "example: nm /dev/dev_name /path/to/destination"

		wh "`nPARAMS:"

		wh "`ndev_name:`tThis is the device that you are trying to connect,`n`t" +
			"it can be found out with -info, just look for the device`n`t" +
			"with the same size as the drive you have attached"

		wh "`ndestination:`tThis is just the folder to which the external device`n`t" +
			"will be connecting to, it can be named anything"
		return

	} elseif ( $info ) { lsblk; return; }

    $uid = id -u
    if ( $uid -ne "0" ) { Write-Error "Error: User must be root to use nmount"; return; }
	if ( -not $dir_name -and -not $device ) { Write-Error "Error: No arguments were specified, use -h for details"; return; }

    try {
		mkdir -p $path
		mount $device $path
    } catch { Write-Error "Device $device could not be mounted to $dir_name"; return; }

    Write-Host "Device $device was mounted to $dir_name"
}

function fsr { # file search from the root dir
    param (
		[string]$arg
    )

    $loc = get-location
    cd /
    find . -name $arg
    cd $loc
}

function acodes {
	param (
		[int]$mode
	)

	if ( $mode -eq $null ) { write-error "No mode was specified"; return; }
	if ( $mode -eq 4 -or $mode -eq 10 ) { $preview = "        " }
	else { $preview = "Sample Text" }

    wh "`e[${mode}0m${preview}`e[0m │ ${mode}0"
    wh "`e[${mode}1m${preview}`e[0m │ ${mode}1"
    wh "`e[${mode}2m${preview}`e[0m │ ${mode}2"
    wh "`e[${mode}3m${preview}`e[0m │ ${mode}3"
    wh "`e[${mode}4m${preview}`e[0m │ ${mode}4"
    wh "`e[${mode}5m${preview}`e[0m │ ${mode}5"
    wh "`e[${mode}6m${preview}`e[0m │ ${mode}6"
    wh "`e[${mode}7m${preview}`e[0m │ ${mode}7"
    wh "`e[${mode}8m${preview}`e[0m │ ${mode}8"
    wh "`e[${mode}9m${preview}`e[0m │ ${mode}9"
}

function sound {
    param (
		[int]$p
    )

    if (-not $p) { Write-Error "No argument was specified" }
    pactl set-sink-volume @DEFAULT_SINK@ ${p}%
}

function cloc { get-location | set-clipboard }

# >>==========>> Nix functions
function clsys {
    param (
		[string]$config_name
    )

    if (-not $config_name)
	{ Write-Error "Config name was not specified..."; return; }
    
    sudo nix-collect-garbage -d
    sudo nixos-rebuild boot --flake /home/nixos/nixos#$config_name --impure
}

function switch: {
    param (
		[switch]$f,
		[string]$config_name
    )

    Write-Host "`e[2J`e[H"
    if ( -not $f -and -not $config_name )
		{ Write-Error "Config name was not specified..."; return; }

    elseif ( -not $f -and $config_name ) {
		Write-Host "Updating System...`n"
		sudo nixos-rebuild switch --flake /home/nixos/nixos#$config_name --impure

    } elseif ( $f -and $config_name ) {
		Write-Host "Updating Flake and System...`n"
		sudo nix flake update --flake /home/nixos/nixos --impure
		sudo nixos-rebuild switch --flake /home/nixos/nixos#$config_name --impure
		pegh

    } else { Write-Error "Proper parameters were not given"; return; }
}
