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
		if ($user -eq "nixos") { prompt_change 34 $user $depth }
		elseif ($user -eq "root") { prompt_change 31 $user $depth }
    }
}

# >>==========>> Traversal Functions
function format {
    param (
	    [object[]]$items
	  )

	$len = 16
	if ($items -and $items.Count -gt 0) {
	    $terminal_width = [math]::Floor($Host.UI.RawUI.BufferSize.Width * 0.98)
		$current_line = "`n⎪"

		foreach ($entry in $items) {
		    $name = $entry.Name
			if ($name.Length -gt $len) { $name = $name.Substring(0, $len - 3) + "..." }
			elseif ($name.Length -lt $len) { $name = $name.PadRight($len) }

		    if (($current_line.Length + $name.Length) -gt $terminal_width) {
				write-host $current_line
			    $current_line = "⎪"
		    }

		    $current_line += " $name ⎪"
		}

	    if ($current_line -ne "") { write-host $current_line }

	} else { write-host "`n`tNo such files found`n" }
}

function l {
	param (
		[switch]$h,
	    [switch]$s,
		[switch]$d,
		[switch]$f,
	    [string]$input_ = @('none')
	)

	if ($input_ -eq 'help') {
		"usage: [-h] [-s] [-d] [-f] <command>"

		"`n`e[7m COMMANDS `e[0m"
		"  help`tdisplay this message and exit"
		"  name`tthe name of the file or directory that you want to open"
		"`tthis is set to 'none' by default"

		"`n`e[7m OPTIONS `e[0m"
		"  -h`tthis shows all hidden items in the current directory"
		"  -s`tthis acts as a search function in conjunction with other"
		"`toptions"
		"  -d`tthis is used for showing a list of all visible sub-directories"
		"`tin the current directory"
		"  -f`tthis is used for showing a list of all visible files in the"
		"`tcurrent dierectory"
		return
	}

	if ($h) { show -Hidden; return; }

	elseif ($d -and $input_ -eq 'none') {
	    $list = show -directory
		format $list
		return

	} elseif ($f -and $input_ -eq 'none') {
	    $list = show -file
		format $list
		return

	} elseif ($d -and $input_ -ne 'none') {
		if ($s) { $list = show -directory *$input_*; format $list; return; }
		$list = show -directory
		format $list
		return

	} elseif ($f -and $input_ -ne 'none') {
		if ($s) { $list = show -file *$input_*; format $list; return; }
		$list = show -file
		format $list
		return

	} elseif ($input_ -eq 'none') { show; return; }

	else { write-error "Proper arguments were not specified, try 'l help'" }
}

function codes {
    cd "/home/nixos/Documents/Code"
    l
}

function gt {
	param (
		[switch]$r,
		[switch]$h,
		[switch]$d,
		[string]$pat
	)

	if ($h) {
		"usage: [-h] [-r] [-d] <pattern>"

		"`n`e[7m PARAMS `e[0m"
		"  pattern:`tthis is the pattern that gt will search for throughout"
		"`t`tyour home folder"

		"`n`e[7m OPTIONS `e[0m"
		"  -h`t`tdisplay this help message and exit"
		"  -r`t`tswitches the path to search in from '~/' to '/'"
		"  -d`t`tsearch through all dot files along with the normal files"
		return
	}

	if ( -not $pat ) { write-error "No argument was given, use -h for help"; return; }

	if ($r) { cd / }
	else { cd }

	if ($d) { $places = fd --hidden --full-path $pat }
	else { $places = fd --full-path $pat }

    for ($i = 0; $i -lt $places.Count; $i++) { write-host "[$($i+1)] $($places[$i])" }
	""

	$choice = ""
	$check = 0
	while ($check -eq 0) {

		$input_ = read-host "Choose location"
		$inp = @($input_.Substring(0, 1), $input_.Substring(1, $input_.Length - 1))

		if ($inp[0] -eq "d") {
			$check = 1
			if ([int]$inp[1] -gt $places.Count -or [int]$inp[1] -le 0)
				{ write-error "Value out of bounds..."; continue; }

			try	  { $choice = [int]$inp[1] }
			catch { write-error "Valid option was not given, use -h for help" }
			break

		} elseif ($inp[0] -match '\d') {
			$check = 2
			$choice = [int]$input_

		} else { write-error "Valid option was not given, use -h for help" }

	}

	$path = $places[$choice - 1]
	if ($check -eq 1) {
		$target = split-path -path $path -parent
		cd $target

	} elseif ($check -eq 2) { less $path }
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
		else { write-error "An error occurred, try again" }
    }
}

function gss { git status }

function pgh {
    gadd
    gcomm

	"`nPushing to github"
    gpo

	"`nRepo push was successful"
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

    write-host @"

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
		[switch]$c, 	# Check and show all files in trash
		[switch]$r,		# Restore file to current directory
		[switch]$e,		# Empty trash
		[switch]$h,		# Help
		[string]$file,
		[string]$path
	)

	if ($h) {
		"usage: [-h] [-c] [-e] [-r] <param>"
		"e.g. tr -c"
		"e.g. tr -r file.txt /home/username/folder"

		"`n`e[7m PARAMS `e[0m"

		"  file:`tThe name of the file that is to be restored,"
		"`tthis can only be used alongside the -r option"
		"  path:`tThe path in which the file selected is to be"
		"`trestored"

		"`n`e[7m OPTIONS `e[0m"

		"  -h:`tShow this message and exit"

		"  -c:`tCheck if there are any files in trash, if true then"
		"`tlist all files, otherwise print message 'Trash is empty'"

		"  -e:`tEmpty the trash"

		"  -r:`tRestore a file from trash"
		return
	}

	$file_check = ls ~/.trash
	if (-not $file_check -and $c) { "`tTrash is empty"; return; }

	if ($c) { ls ~/.trash }
	elseif ($r -and $file -and $path) { mv ~/.trash/$file $path }
	elseif ($e) { rm -rf ~/.trash/* }
	else { write-error "Proper arguments were not specified, use -h for help"; return; }
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

function psrvr { python ~/Documents/Code/custom_server.py }

function lcltnl {
    Param (
	    [int]$port = 8000
	)
	
	cloudflared tunnel --url localhost:$port
}

function conv_hex {
    param (
		[string[]]$values
    )

    $colors = $values.Split(" ")
    ""

    foreach ($color in $colors) {
		$hex = $color.Split("#")[-1]
		$r = [Convert]::ToInt32($hex.Substring(0,2), 16)
		$g = [Convert]::ToInt32($hex.Substring(2,2), 16)
		$b = [Convert]::ToInt32($hex.Substring(4,2), 16)

		"`e[48;2;${r};${g};${b}m      `e[0m │ HEX: #${hex}"
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
		[switch]$i,
		[string]$ftype,
		[string]$dev_name,
		[string]$new_name
    )

    if ( $h ) {
		"usage: [-h] [-i] <params>`n"
		"e.g. rnd ext4 /dev/sda1 new-device"

		"`n`e[7m PARAMS `e[0m`n"

		"  filesystem:`tthe filesystem of the device to be renamed,"
		"`t`taccepted formats are:"
		"`t`t  'fat32', 'vfat', 'ext2', 'ext3', 'ext4', 'ntfs'"
		"  /dev/name:`tthe name of the device that is to be renamed"
		"  new_name:`tthe new name that will be given to the drive,"
		"`t`tit can be named anything"

		"`n`e[7m OPTIONS `e[0m`n"

		"  -h`tdisplay this help and exit"
		"  -i`tdisplay info on all connected storage devices"
    }
    elseif ( $i ) { lsblk }
    elseif ( $ftype -eq "" -and $dev_name -eq "" -and $new_name -eq "" ) {
		"No parameters were provided, use -h for help"
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
		[switch]$i,
		[string]$device,
		[string]$dir_name
    )

    $uid = id -u
    if ( $uid -ne "0" ) { Write-Error "Error: User must be root to use nmount"; return; }

	$hostname = hostname
    $path = "/run/media/$hostname/$dir_name"

	if ( $h ) {
		"usage: [-h] [-i] <params>"
		"example: nm /dev/dev_name /path/to/destination"

		"`n`e[7m PARAMS `e[0m`n"

		"  dev_name:`tthis is the device that you are trying to connect,"
		"`t`tit can be found out with [-i], just look for the device"
		"`t`twith a similar size as the drive you have attached"

		"  destination:`tThis is just the folder to which the external device"
		"`t`twill be connecting to, it can be named anything"

		"`n`e[7m OPTIONS `e[0m`n"
		"  -h`tdisplay this help and exit"
		"  -i`tdisplay device info"
		return

	} elseif ( $i ) { lsblk; return; }

	if ( -not $dir_name -and -not $device ) { Write-Error "Error: No arguments were specified, use -h for details"; return; }
    try {
		mkdir -p $path
		mount $device $path

    } catch { Write-Error "Device $device could not be mounted to $dir_name"; return; }

    Write-Host "Device $device was mounted to $dir_name"
}

function acodes {
	param (
		[int]$mode
	)

	if ( $mode -eq $null ) { write-error "No mode was specified"; return; }
	if ( $mode -eq 4 -or $mode -eq 10 ) { $preview = "        " }
	else { $preview = "Sample Text" }

    "`e[${mode}0m${preview}`e[0m │ ${mode}0"
    "`e[${mode}1m${preview}`e[0m │ ${mode}1"
    "`e[${mode}2m${preview}`e[0m │ ${mode}2"
    "`e[${mode}3m${preview}`e[0m │ ${mode}3"
    "`e[${mode}4m${preview}`e[0m │ ${mode}4"
    "`e[${mode}5m${preview}`e[0m │ ${mode}5"
    "`e[${mode}6m${preview}`e[0m │ ${mode}6"
    "`e[${mode}7m${preview}`e[0m │ ${mode}7"
    "`e[${mode}8m${preview}`e[0m │ ${mode}8"
    "`e[${mode}9m${preview}`e[0m │ ${mode}9"
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
