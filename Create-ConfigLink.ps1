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
  $SteamPath = $SteamPath + "\userdata\"
  return $SteamPath
}

function GetUserProfiles
{
  $SteamProfileDir = GetSteamPathFromRegistry
  $UserProfiles = Get-Childitem $SteamProfileDir
  $BackupFolder = $SteamProfileDir + "scriptbackup"
  $DropboxPath = GetDropBoxPathFromInfoJson
  if (!(Test-Path -Path $DropboxPath\SteamConfig)) {
    New-Item -ItemType Directory -Path $DropboxPath\SteamConfig
  }

  if (!(Test-Path -Path $BackupFolder)) 
  {
    New-Item -ItemType Directory -Path $BackupFolder
  }

  foreach ($profile in $UserProfiles) 
  {
    if ($profile.Name -ne "scriptbackup") 
  {
    $fullPath = $profile.FullName
    Move-item -Path $profile.FullName -Destination $BackupFolder
    New-SymLink '$fullPath' $DropboxPath\SteamConfig
  }
  }
  return $UserProfiles
}

GetUserProfiles

Write-Host "You can now drop your config files into SteamConfig in Dropbox"