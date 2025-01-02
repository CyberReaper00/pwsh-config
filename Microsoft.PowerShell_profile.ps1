$null = Get-Command
Write-Host "Some text is written" -Background Green

Set-Alias seal Set-Alias
seal rmit Remove-Item
seal gloc Get-Location
seal show Get-ChildItem
seal rnit Rename-Item
seal fn function

function cloc {
    Get-Location | Select-Object -ExpandProperty Path | clip
}

function lsf {
    show -directory
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

function nplgn {
    cd 'C:\tools\neovim\nvim-win64\share\nvim\runtime\plugin'
	ls
}

function prfl {
    nvim $PROFILE
}
function cmtprfl {
    cd 'C:\Users\Windows 11\documents\windowspowershell'
    gadd
    gcomm
    gpm
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

function newit {
    param (
	    [string]$Name
	  )
	New-Item -Path . -Name $Name -ItemType "File"
}

function gadd {
    param (
	    [string[]]$Files = @('.') # Default value
	  )
	git add $Files
}

function gcomm {
    param (
	    [string[]]$Message = @('New commit') # Default value
	  )
	$Message = Read-Host 'Enter Commit Message'
	git commit -m $Message
}

function gss {
    git status
}

function gpm {
    git push -u origin main
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
	lsf
}

function lcltnl {
    Param (
	    [int]$Port = 8000
	  )
	cloudflared tunnel --url localhost:$Port
}

function lsfN {
    Param (
	    [int]$Index = 1
	  )
	$Dir = Get-ChildItem -Path . -Directory | Select-Object -Skip ($Index-1) -First 1
	cd $Dir
}
