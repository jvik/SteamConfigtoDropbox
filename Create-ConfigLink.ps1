<#
.SYNOPSIS
  Backups up steam user profiles and creates a shared storage in your Dropbox folder
.DESCRIPTION
  Backups up steam user profiles and creates a shared storage in your Dropbox folder
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        1.0
  Author:         Jørgen Vik
  Creation Date:  12.09.2018
  Purpose/Change: Initial script development
  
.EXAMPLE
  ./Reset-Profiles.ps1
#>

#Function enables symlinks to be created in powershell without elevation
Function New-SymLink ($link, $target)
{
    if (test-path -pathtype container $target)
    {
        $command = "cmd /c mklink /d"
    }
    else
    {
        $command = "cmd /c mklink"
    }

    invoke-expression "$command $link $target"
}

# Dropbox path is retrieved from JSON file in appdata
function GetDropBoxPathFromInfoJson
{
    $DropboxPath = Get-Content "$ENV:LOCALAPPDATA\Dropbox\info.json" -ErrorAction Stop | ConvertFrom-Json | % 'personal' | % 'path'
    return $DropboxPath
}

# Steam path is retrieved from registry
function GetSteamPathFromRegistry
{
  $SteamPath = Get-ItemPropertyValue -Path HKCU:\Software\Valve\Steam -Name SteamPath
  $SteamPath = $SteamPath -replace  "/", "\"
  $SteamPath = $SteamPath + "\userdata\test\"
  return $SteamPath
}

function CreateFolders($DropboxPath, $BackupPath)
{
  if (!(Test-Path -Path $DropboxPath\SteamConfig)) {
    New-Item -ItemType Directory -Path $DropboxPath\SteamConfig
  }

  if (!(Test-Path -Path $BackupFolder)) 
  {
    New-Item -ItemType Directory -Path $BackupFolder
  }
}

# Function creates necessary folders and backs up userdata, and create symlinks.
function BackupAndCreateSymlink
{
  $SteamProfileDir = GetSteamPathFromRegistry
  $UserProfiles = Get-Childitem $SteamProfileDir
  $BackupFolder = $SteamProfileDir + "scriptbackup"
  $DropboxPath = GetDropBoxPathFromInfoJson
  CreateFolders($DropboxPath,$BackupPath)

  foreach ($profile in $UserProfiles) 
  {
    if (($profile.Name -ne "scriptbackup") -and ($profile.LinkType -ne "SymbolicLink")) 
  {
    $fullPath = $profile.FullName
    Move-item -Path $profile.FullName -Destination $BackupFolder
    New-SymLink '$fullPath' $DropboxPath\SteamConfig
  }
    else {
      Write-Host "Backup of" $profile "not necessary"
    }
  }
  return $UserProfiles
}

BackupAndCreateSymlink

Write-Host "You can now drop your config files into SteamConfig in Dropbox"