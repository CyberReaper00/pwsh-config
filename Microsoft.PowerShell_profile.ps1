# >>==========>> Terminal Greeting
"`e[2J`e[H"
write-host "Powershell Has Initiated" -Foreground DarkBlue
Set-PSReadLineKeyHandler -Key 'Alt+o' -Function AcceptNextSuggestionWord

# >>==========>> Aliases
sal rnit Rename-Item
sal show Get-ChildItem
sal b cd..

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

		} else { break }
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

		[switch]$sf,
		[switch]$sd,

	    [string]$input_ = 'none'
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

	if ($sd -or ($s -and $d)) { $list = show -directory *$input_*; format $list; return; }
	if ($sf -or ($s -and $f)) { $list = show -file *$input_*; format $list; return; }

	if ($d -and $input_ -eq 'none') {
	    $list = show -directory
		format $list
		return

	} elseif ($f -and $input_ -eq 'none') {
	    $list = show -file
		format $list
		return

	} elseif ($input_ -eq 'none') { show; return; }

	else { write-error "Proper arguments were not specified, try 'l help'" }
}

function gt {
	param (
		[switch]$r,
		[switch]$h,
		[switch]$d,
		[switch]$a,

		[string]$pattern
	)

	# Help menu
	if ($h) {
		"usage: [-h] [-r] [-d] [-a] <pattern>"

		"`n`e[7m PARAMS `e[0m"
		"  pattern:`tthis is the pattern that gt will search for throughout"
		"`t`tyour home folder"

		"`n`e[7m OPTIONS `e[0m"
		"  -h`tdisplay this help message and exit"
		"  -r`tswitches the path to search in, from '~/' to '/'"
		"  -d`tonly searches through and gives a list of directories"
		"  -a`tsearch through all dot files along with the normal files"

		return
	}

	# Give error if no input is given
	if ( -not $pattern )
		{ write-error "No argument was given, use -h for help"; return; }

	# Change the starting search directory based on user input
	# default is set to the home directory
	if ($r) { $search_path = '/'; }
	else	{ $search_path = '~/'; }
	
	# Display all the resulting paths with corresponding numbers
	# This displays the full path upto the last directory
	if ($d) {
		# Change the search parameters based on user input
		# default is set to search only for visible files
		if ($a) { $places = fd -H -p --no-ignore -t d "$pattern" $search_path }
		else	{ $places = fd -p --no-ignore -t d "$pattern" $search_path }
		$folders = @($places)

		# If there are no matches then give error and exit
		if ($folders.Length -eq 0) { write-error "No matches were found"; return; }
		
		# Sort everything alphabetically
		$dir_paths = @($folders | sort-object)
		
		# Print the list immediately if the list only has 1 item
		if ($dir_paths.count -eq 1) {
			cd $folders[0]
			return
			
		# Display list with a pager if its length is greater than 15
		} elseif ($dir_paths.count -gt 15) {
			$stored_paths = @()
			for ($i = 0; $i -lt $dir_paths.count; $i++)
				{ $stored_paths += "[$($i+1)] $($dir_paths[$i])" }
			$stored_paths | less -i
			
		# Print the list if its length is less than 15
		} else {
			for ($i = 0; $i -lt $dir_paths.count; $i++)
				{ "[$($i+1)] $($dir_paths[$i])" }
		}

	# Display all the files with corresponding numbers
	# This displays the full path
	} else {
		# Change the search parameters based on user input
		# default is set to search only for visible files
		if ($a) { $places = fd -H -p --no-ignore -t f "$pattern" $search_path }
		else	{ $places = fd -p --no-ignore -t f "$pattern" $search_path }
		$files = @($places)

		# If there are no matches then give error and exit
		if ($files.Length -eq 0) { write-error "No matches were found"; return; }
		
		# Sort everything alphabetically
		$file_paths = @($files | sort-object)

		# Print the list immediately if the list only has 1 item
		if ($files.count -eq 1) {
			less -i $file_paths[0]
			return

		# Display the list with a pager if its length is greater than 15
		} elseif ($file_paths.count -gt 15) {
			$stored_paths = @()
			for ($i = 0; $i -lt $file_paths.count; $i++)
				{ $stored_paths += "[$($i+1)] $($file_paths[$i])" }
			$stored_paths | less -i

		# Print the list if its length is less than 15
		} else {
			for ($i = 0; $i -lt $file_paths.count; $i++)
				{ "[$($i+1)] $($file_paths[$i])" }
		}
	}

	# Initialize variable that checks if the user wants to see a file or
	# go to a directory
	$check = 0

	# Loop to check if the user gave a correct input, if not then an error displays
	# and instead of exiting the user is allowed to enter a value again
	while ($check -eq 0) {

		# Ask the user to choose a location from the list
		$input_ = read-host "Choose location"
		if ($input_ -eq "") { return; }

		# Check if the value is a number
		try		{ $inp = [int]$input_ }
		catch	{ write-error "Value must be a number"; continue; }

		# Check if the value is out of bounds
		if ($inp -gt $places.count -or $inp -le 0)
			{ write-error "Value out of bounds..."; continue; }

		# Checks that the user wants to access a directory or a file
		# Gets the location that the user chose
		if ($d) { $check = 1; $dir_path  = $dir_paths[$inp - 1]; }
		else	{ $check = 2; $file_path = $file_paths[$inp - 1]; }
	}

	# When going to a directory, get rid of the filename from the path that was chosen
	# and go directly to that directory
	if ($check -eq 1) { cd $dir_path }

	# When going to a file, open it directly to be viewed
	# Might change later to open with either nvim or less 
	elseif ($check -eq 2) { less -i $file_path }
}

# >>==========>> Github Functions
function gcr {
    param (
		[switch]$h,
		[switch]$p
    )

	if ($h) {
		"usage: [-h] [-p]"
		"  -h`tdisplay this message and exit"
		"  -p`tpull the latest commit and join it with the local repo"
		return
	}

    $link = (read-host 'Enter remote repo link').Trim()

    git init
    git remote add origin $link

    if ($p) {
		git pull --rebase origin main
		git add .
		git commit -m 'New commit'
		git push
		return
    }

    git branch -m main
	git add .
	git commit -m 'Initial commit'
	git push

}

function pgh {
	git status
	"`n`n-----------------------------------------"
	$message = read-host "`n`nEnter Commit Message"
	
	if ($message -eq "") { "`n`nSkipping repo..."; start-sleep -seconds 0.5; return; }

	else {
		git add .
		git commit -m $message
		"`n`n-----------------------------------------"
		"`n`nPushing to github"

		while ($true) {
			$branch = read-host 'Enter Branch'
			git push -u origin $branch

			if ($LASTEXITCODE -eq 0) { break }
			elseif ($branch -eq "") { break }
			else { write-error "An error occurred, try again" }
		}

		"`n`n-----------------------------------------"
		"`n`nRepo push was successful"

		start-sleep -seconds 0.5
	}
}

function pnver {
	param (
		[float]$version
	)

	if ( -not $version ) { write-error "new version was not provided..."; return; }

	pgh
	git tag -a $version -m " "
	git push --tags
}

function header { #╭╮╰╯│─├
    param (
		[switch]$p,
		[string]$name
    )

    $name_len	= $name.Length
    $width 		= $name_len + 12
    $border 	= "─" * $width
    $spacing 	= $width - $name_len
    $content 	= (" " * [int]($spacing/2)) + $name + (" " * [int]($spacing/2))

    if ($p) {
    @"

	    ╭${border}╮
            │${content}│
            ╰${border}╯
"@
	} else {
    @"

	    	╭${border}╮
            │${content}│
            ╰${border}╯
"@
	}
}

function get_git_repos {
	$accepted_paths = [System.Collections.ArrayList]::new()
	$folder_names = $new_names = @()

	pushd ~/
	$original_places = fd -H -p --no-ignore "\.git$"
	popd

	$places = foreach ($place in $original_places) {
		for ($i = 0; $i -lt $place.Length; $i++) {
			if ($place[$i] -eq ".") { $place[0..($i-1)] -join '' }
		}
	}

	foreach ($place in $places) {
		if ($place[0] -ne ".") {
			[void]$accepted_paths.Add($place)

			$counter = [System.Collections.ArrayList]::new()
			for ($i = 0; $i -lt $place.Length; $i++) {
				if ($place[$i] -eq "/") { [void]$counter.Add($i) }
			}

			if ($counter[-2] -eq $null) { [void]$counter.Insert(0, -1) }
			$base_name = ($place[($counter[-2]+1)..($counter[-1]-1)] -join '')
			$folder_names += $base_name
		}
	}

	$textinfo = [System.Threading.Thread]::CurrentThread.CurrentCulture.TextInfo
	foreach ($folder in $folder_names) {
		$name_change = $folder.Replace('_', '-')
		$new_names += $textinfo.ToTitleCase($name_change)
	}
	return $new_names,$accepted_paths
}

function ssall {
	$folder_names,$path_names = get_git_repos

	$output = for ($i = 0; $i -lt $folder_names.Length; $i++) {
		header "Checking $($folder_names[$i])"

		pushd "~/$($path_names[$i])"
		git status
		popd
	}

	$output | bat --style="header,grid" --theme gruvbox-dark -l meminfo
}

function pegh {
	$folder_names,$path_names = get_git_repos

	for ($i = 0; $i -lt $folder_names.Length; $i++) {
		"`e[2J`e[H"
		header -p "Pushing $($folder_names[$i])"

		pushd "~/$($path_names[$i])"
		git status
		pgh
		popd
	}
}

# >>==========>> Editing Functions
function mkfile {
    param (
		[string[]]$names,
		[string]$dir
    )

	if ($dir -eq "") { $dir = "." }
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

function psrvr { python ~/Documents/Projects/custom_server.py }

function lcltnl {
    Param (
	    [int]$port = 8000
	)
	
	cloudflared tunnel --url localhost:$port
}

function show_hex {
    param (
		[string[]]$values
    )

    $colors = $values.Split(" ")
    ""

	foreach ($color in $colors) {
		$hex = $color.Split("#")[-1]

		if ($hex.Length -eq 6) {
			$r = [Convert]::ToInt32($hex.Substring(0,2), 16)
			$g = [Convert]::ToInt32($hex.Substring(2,2), 16)
			$b = [Convert]::ToInt32($hex.Substring(4,2), 16)

			"`e[48;2;${r};${g};${b}m      `e[0m │ HEX: #${hex}"

		} elseif ($hex.Length -eq 3) {
			$r = $hex[0]
			$g = $hex[1]
			$b = $hex[2]

			try 	{ $r1 = [int]$r+$($r*10) }
			catch 	{ $r1 = $r+$r }

			try 	{ $g1 = [int]$g+$($g*10) }
			catch 	{ $g1 = $g+$g }

			try 	{ $b1 = [int]$b+$($b+10) }
			catch 	{ $b1 = $b+$b }

			$r2 = [Convert]::ToInt32($r1, 16)
			$g2 = [Convert]::ToInt32($g1, 16)
			$b2 = [Convert]::ToInt32($b1, 16)

			"`e[48;2;${r2};${g2};${b2}m      `e[0m │ HEX: #${hex}"

		} else { write-error 'Invalid input was defined'; return; }
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

	if ( -not $dir_name -and -not $device ) { write-error "Error: No arguments were specified, use -h for details"; return; }
    try {
		mkdir -p $path
		mount $device $path

    } catch { write-error "Device $device could not be mounted to $dir_name"; return; }

    "Device $device was mounted to $dir_name"
}

function acodes { # ASCII Codes
	param (
		[int]$mode
	)

	if (-not $PSBoundParameters.ContainsKey('mode')) { write-error "No mode was specified"; return; }
	if ($mode -eq 4 -or $mode -eq 10) { $preview = "        " }
	else { $preview = "Sample Text" }

	$preview_distance = "─" * ($preview.Length + 2)
	$mode_distance = "─" * (($mode).ToString().Length + 3)

	#╭╮╰╯│┤├ ┬ ┴ ─
	"╭${preview_distance}┬$mode_distance╮"
    "│ `e[${mode}0m${preview}`e[0m │ ${mode}0 │"
    "│ `e[${mode}1m${preview}`e[0m │ ${mode}1 │"
    "│ `e[${mode}2m${preview}`e[0m │ ${mode}2 │"
    "│ `e[${mode}3m${preview}`e[0m │ ${mode}3 │"
    "│ `e[${mode}4m${preview}`e[0m │ ${mode}4 │"
    "│ `e[${mode}5m${preview}`e[0m │ ${mode}5 │"
    "│ `e[${mode}6m${preview}`e[0m │ ${mode}6 │"
    "│ `e[${mode}7m${preview}`e[0m │ ${mode}7 │"
    "│ `e[${mode}8m${preview}`e[0m │ ${mode}8 │"
    "│ `e[${mode}9m${preview}`e[0m │ ${mode}9 │"
	"╰${preview_distance}┴$mode_distance╯"
}

function cloc { get-location | set-clipboard }

function phelp {
	[AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
		-not $_.IsDynamic -and -not $_.Location.Contains('PowerShell')
	} | ForEach-Object {
		try   { $_.GetTypes() }
		catch { } # Suppress errors by doing nothing in the catch block
	} | Where-Object {
		$_.Namespace -eq "System" -and $_.IsClass
	} | Sort-Object Name | less 
}

function Get-FileHeader {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
		[int]$amount = 100
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-Error "The specified path is not a file or does not exist."
        return
    }

    try {
        # Read the first few bytes from the file as a byte array
        [byte[]]$bytes = [System.IO.File]::ReadAllBytes($Path) | Select-Object -First $amount

		# Convert the bytes to text and display them in the terminal
		$text = [System.Text.Encoding]::UTF8.GetString($bytes)
		"$text"

    } catch {
        # Catch and display any errors during file access
        Write-Error "An error occurred while reading the file: $($_.Exception.Message)"
    }
}

function da {
	param (
		[switch]$p,
		[string]$link,
		[string]$format = 'wav'
	)

	if ($p -and $link -eq "cp") {
		set-clipboard "/home/nixos/Documents/Projects/yt-dlp/"
		return
	}

	if (-not $link) { write-error "Link not provided"; return; }

	pushd /home/nixos/Music/songs
	/nix/store/hqz4lga5j1qw2v3jvf0aii1801paa7gz-yt-dlp-2025.09.26/bin/yt-dlp -x --audio-format $format $link
	popd
}

function upack {
	param(
		[switch]$h,
		[switch]$u,
		[switch]$v
	)

	if ($h) {
		"usage: [-v] [-u]"
		"`n`e[7m OPTIONS `e[0m"
		"`n  -v`tchecks the versions both locally and online then prints them"
		"`n  -u`tthis just rebuilds the local package.nix file"
		"`n  NOTE: the local package cannot be updated automatically the hash for"
		"`tthe latest version must be taken manually and then the package.nix"
		"`tfile must be updated with the new hash and version"
		return
	}

	if ($v) { /nix/store/hqz4lga5j1qw2v3jvf0aii1801paa7gz-yt-dlp-2025.09.26/bin/yt-dlp -U; return; }
	if ($u) {
		pushd /home/nixos/Documents/Projects/yt-dlp
		nix-build
		popd

	} else { write-error "Invalid arguments, try -h" }
}

function fil {
	param ( [string]$name)
	file $name | sed 's/, /\n/g' | sed 's/^\(.*\)/\t[ \1 ]/g'
}

# >>==========>> Nix functions
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

    } else { Write-Error "Proper parameters were not given"; return; }
}
