# Overview
In this config i have powershell as extensive as possible so that i can have a seamless dev environment to do whatever i want, whenever i want and go wherever i want with one command
## Terminal Greeting
``` Write-Host "`e[2J`e[H" ```
- Everytime the terminal opened or i needed to refresh the terminal because i changed something, the terminal would have some gap on the top which moved the prompt a little down
- But i wanted the prompt to always be at the top so placed this line at the top of my profile to erase anything above it on launch

I also placed a simple `Powershell Has Initiated` so that i know when powershell was done loading things in the background since the profile runs at the very last
## Aliases
- In powershell you can alias something if its one command, if it has multiple commands then you have to create a function to use it
- When its done, you can call that function in the shell as an alias
- Here are my aliases

```
set-alias     -> seal
rename-item   -> rnit
get-childitem -> show
cd ..         -> b
```
## Prompt Overhaul
- I wanted a new prompt that actually looked nice or at least different, so i sat down for a few hours and created a new prompt with some useful features and some nice touches
	<img width="512" height="auto" alt="Pasted image 20250816003512" src="https://github.com/user-attachments/assets/b9e2bdb1-1893-4614-9054-548f122cc215" />
- The first section shows the current user
	- My system only has two users, me and root, so i've set it up to when i am logged in the color is blue but when root is logged in it turns red
	- There is also a third color of green, but that is not for any user but for a nix-shell
- The second section shows the depth of the shell
	- This is a bit nuanced
	- When i, or anyone, make a change to the shell config, the entire shell needs to be refreshed to have the changes take effect
	- This can be done by restarting the terminal or by creating another instance of the shell
	- I personally prefer the second option and so i created this counter that keeps tabs on how deep i am in the path of refreshals
	- The deeper i go the higher the counter gets
	- Its pretty useful to have, when your doing a bunch of tiny changes over and over again and you lose count of how far down you've gone
- The third section shows the current path
## Traversal Functions
As i said before, aliases cannot hold more than one value so here are all the functions/aliases that i have created
- `l`
	- Powershell does not have the `l` command like sh or bash and i really liked the functionality of that so ended up recreating it in powershell, but i did make some tweaks to make it more usable
- `codes`
	- Just a `cd` command to take me directly to my folder where i put all my code files
## Github Functions
- `gt`
	- My own custom fuzzy finder so that i can move to any folder on my system with one command
	- I had thought of creating it from scratch and making a new program but then i realized it would be too much effort for something i can just hack together in the shell
- `gcr`
	- This command just creates a new repo with some default settings that i always use
- `gadd`
	- git add
- `gcomm`
	- git commit -m
- `gpo`
	- Pushes the code to a remote origin
- `gss`
	- git status
- `pgh`
	- Does all of the above
- `pnver`
	- 'Push new version', i built this to push new tags for a project when i need to update its versioning
- `pegh`
	- I have just simply configured this to go into all the most commonly used repos on my system and then push them all to github one by one
- `ssall`
	- This gets the status from all my repos
## Editing Functions
- `mkfile`
	- I just wanted the commands to create files and dirs to have similar names
- `rmit`
	- This allows me to remove multiple items from a dir with pattern matching, instead of my having to type out the entire name of each file
- `rem`
	- I didnt like using the original `rm` command because it didnt have an undo function, so i built this to remove files but also to have a way to undo a remove
	- All this does is, instead of deleting anything from my machine, it just moves it to a local trash folder from which i can just "restore" the file into any dir
- `tr`
	- This is the command i use to restore files from the `rem` commands' trash folder
## Helper Functions
- `qwe`
	- This is an alias for exit, i wanted to just make it a direct alias but powershell wouldnt let me do that for some reason
- `psrvr`
	- This starts a barebones python server in the current directory
- `conv_hex`
	- I love this function, with it i can place any number of hex codes into it and converts all of them into their rgb representations, outputs them in the terminal and lets me see the colors that those hex codes represent
	- This has come in handy alot of times when creating or updating a new theme for something
- `hta`
	- This converts, or tries to convert, any hexadecimal value into ASCII text
- `rnd`
	- I've had a lot of problems on my system where i just cant get some things to work and one of those things is the ability to rename an external drive from a file manager
	- This allows me to do so manually
- `nm`
	- Another problem, where sometimes an external drive will just refuse to connect
	- This allows me to mount new drives manually with ease
- `acodes`
	- This is pretty cool, i built this so that i can see all the ansii codes that a terminal can support but maybe doesnt
	- Like bolding, striking, underlining or blinking text
	- Coloring the background
	- Coloring text
	- Coloring in both bright and dull colors etc
- `cloc`
	- This just gets the current location and then places it in the clipboard
## Nix Functions
- `clsys`
	- This is a nixos specific function, it checks how much trash and extra programs i have stored on my machine and deletes them all
- `switch:`
	- The functionality for this is two-fold
		- I can update my system including or excluding my flake and switch to a new generation
		- I can switch my entire environment and switch to a new state completely