$null = Get-Command
Write-Host "Powershell Has Initiated" -Foreground DarkBlue

Set-Alias seal Set-Alias
seal rmit Remove-Item
seal gloc Get-Location
seal show Get-ChildItem
seal rnit Rename-Item
seal bk	cd..

function cloc {
    Get-Location | Select-Object -ExpandProperty Path | clip
}

function lsd {
    param (
	    [string]$Name = @('none')
	  )

	if ($Name -eq 'none') {
	    show -directory
	} else {
	    cd *$Name*
	}
}

function lsf {
    param (
	    [string]$File = @('none')
	  )

	if ($File -eq 'none') {
	    show -File
	} else {
	    show -File *$File*
	}
}

function codes {
    cd 'C:\users\windows 11\documents\code'
	ls
}

function qwe {
    exit
}

function lad {
    cd $env:LOCALAPPDATA
}

function nconf {
    cd 'C:\users\windows 11\appdata\local\nvim'
	nvim init.lua
}

function pgh {
	gadd
	gcomm
	gpo
}

function nplgn {
    cd 'C:\tools\neovim\nvim-win64\share\nvim\runtime\plugin'
	ls
}

function prfl {
    nvim $PROFILE
}

function pushprfl {
    cd 'C:\Users\Windows 11\documents\windowspowershell'
	pgh
}

function path_split {
    param(
	    [string[]]$Item
	 )
	$env:PATH -split $Item | ForEach-Object {$_}
}

function navs {
    nvim .
}

function iop {
    explorer .
}

function hm {
    cd ~/
}

function mkfile {
    param (
	    [string[]]$Name
	  )
	New-Item -Path . -Name $Name -ItemType "File"
}

function gadd {
	$Files = (Read-Host 'Enter File Names').Split(',').Trim()
	git add $Files
}

function gcomm {
	$Message = Read-Host 'Enter Commit Message'
	git commit -m $Message
}

function gss {
    git status
}

function gpo {
    $Branch = Read-Host 'Enter Branch'
    git push -u origin $Branch
}

function psrvr {
    param (
	    [int]$Port = 8000 # Default value
	  )
	python -m http.server $Port
}

function chart {
    cd 'C:\Users\Windows 11\documents\veracity files\st chart'
}

function vfiles {
    cd 'C:\users\windows 11\documents\veracity files'
	lsd
}

function lcltnl {
    Param (
	    [int]$Port = 8000
	  )
	cloudflared tunnel --url localhost:$Port
}

function startup {
    cd 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup'
}

function admin {
    Start-Process powershell -Verb runAs
}
