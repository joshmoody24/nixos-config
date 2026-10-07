# Installs or updates Ship of Harkinian on Windows, pinned to the same release as
# Josh's NixOS config. Run it from PowerShell with:
#   irm https://raw.githubusercontent.com/joshmoody24/nixos-config/main/scripts/soh/install.ps1 | iex

# iex runs this in the caller's session: a scriptblock keeps our settings out of it,
# and throwing instead of `exit` keeps their window open to read errors.
& {
  $ErrorActionPreference = 'Stop'
  # Windows PowerShell 5.1 redraws its progress bar so often that downloads crawl.
  $ProgressPreference = 'SilentlyContinue'
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Add-Type -AssemblyName System.IO.Compression.FileSystem

  $releaseUrl = 'https://raw.githubusercontent.com/joshmoody24/nixos-config/main/shared/pkgs/soh-release.json'
  $installDir = Join-Path $env:LOCALAPPDATA 'ShipOfHarkinian'
  $romExtensions = @('.z64', '.n64', '.v64')

  function Get-InstalledRoms {
    @(Get-ChildItem -LiteralPath $installDir -File | Where-Object { $romExtensions -contains $_.Extension.ToLower() })
  }

  function Install-Game($release) {
    $zipPath = Join-Path $env:TEMP "soh-$($release.version).zip"
    # There's no progress bar (see $ProgressPreference), so the size tells people how long to wait.
    $sizeBytes = (Invoke-WebRequest -Uri $release.windows.url -Method Head -UseBasicParsing).Headers['Content-Length']
    $sizeNote = if ($sizeBytes) { " (about $([math]::Round([long]"$sizeBytes" / 1MB))MB)" } else { '' }
    Write-Host "Downloading Ship of Harkinian $($release.version)$sizeNote..."
    Invoke-WebRequest -Uri $release.windows.url -OutFile $zipPath -UseBasicParsing

    $actualHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
    if ($actualHash -ne $release.windows.sha256) {
      throw "Download of $($release.windows.url) has SHA256 $actualHash, expected $($release.windows.sha256)"
    }

    # Old asset definitions could linger and confuse a newer version. Saves, settings,
    # and the ROM live outside this folder, so they survive.
    $assetsDir = Join-Path $installDir 'assets'
    if (Test-Path -LiteralPath $assetsDir) { Remove-Item -LiteralPath $assetsDir -Recurse -Force }

    Write-Host "Extracting to $installDir..."
    $zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
      # debug/ is a 160MB symbol file only developers need.
      $zip.Entries | Where-Object { $_.Name -and -not $_.FullName.StartsWith('debug/') } | ForEach-Object {
        $destination = Join-Path $installDir $_.FullName
        New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
        [IO.Compression.ZipFileExtensions]::ExtractToFile($_, $destination, $true)
      }
    } finally {
      $zip.Dispose()
    }
    Remove-Item -LiteralPath $zipPath
  }

  function Test-IsZip($path) {
    $header = [byte[]]::new(2)
    $stream = [IO.File]::OpenRead($path)
    try { [void]$stream.Read($header, 0, 2) } finally { $stream.Dispose() }
    $header[0] -eq 0x50 -and $header[1] -eq 0x4B
  }

  function Expand-RomFromZip($zipPath) {
    $zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
      $entry = $zip.Entries | Where-Object { $romExtensions -contains [IO.Path]::GetExtension($_.Name).ToLower() } | Select-Object -First 1
      if (-not $entry) { throw "No .z64, .n64, or .v64 file inside the zip" }
      $destination = Join-Path $env:TEMP $entry.Name
      [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $true)
      $destination
    } finally {
      $zip.Dispose()
    }
  }

  function Get-FreeRomPath($name) {
    $base = [IO.Path]::GetFileNameWithoutExtension($name)
    $extension = [IO.Path]::GetExtension($name)
    $candidates = @($name) + (2..99 | ForEach-Object { "$base-$_$extension" })
    $candidates | ForEach-Object { Join-Path $installDir $_ } | Where-Object { -not (Test-Path -LiteralPath $_) } | Select-Object -First 1
  }

  # Returns the installed file name, or nothing if this exact ROM is already installed.
  function Add-Rom($source) {
    $isUrl = $source -match '^https?://'
    $downloadPath = Join-Path $env:TEMP 'soh-rom-download'
    $localPath = if ($isUrl) {
      Write-Host 'Downloading ROM...'
      Invoke-WebRequest -Uri $source -OutFile $downloadPath -UseBasicParsing
      $downloadPath
    } else {
      if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "No file at $source" }
      $source
    }
    # Download links often hide the file type, so sniff for a zip instead of trusting the name.
    $fromZip = Test-IsZip $localPath
    $romPath = if ($fromZip) { Expand-RomFromZip $localPath } else { $localPath }

    try {
      $sourceName = [IO.Path]::GetFileName($(if ($fromZip) { $romPath } elseif ($isUrl) { ([uri]$source).AbsolutePath } else { $source }))
      # The game reads byte order from the ROM header, so the extension only has to be
      # one it scans for.
      $romName = if ($romExtensions -contains [IO.Path]::GetExtension($sourceName).ToLower()) { $sourceName } else { 'oot.z64' }

      $hash = (Get-FileHash -LiteralPath $romPath -Algorithm SHA256).Hash
      $duplicate = Get-InstalledRoms | Where-Object { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash -eq $hash } | Select-Object -First 1
      if ($duplicate) {
        Write-Host "Already installed as $($duplicate.Name), skipping"
      } else {
        $destination = Get-FreeRomPath $romName
        Copy-Item -LiteralPath $romPath -Destination $destination
        Write-Host "Added $(Split-Path $destination -Leaf)" -ForegroundColor Green
        Split-Path $destination -Leaf
      }
    } finally {
      if ($fromZip) { Remove-Item -LiteralPath $romPath }
      if ($isUrl) { Remove-Item -LiteralPath $downloadPath }
    }
  }

  # Returns the names of ROMs added this run.
  function Request-Roms {
    $installed = Get-InstalledRoms
    Write-Host ''
    if ($installed.Count -gt 0) {
      Write-Host "Installed ROMs: $(($installed | ForEach-Object Name) -join ', ')"
    } else {
      Write-Host 'Ship of Harkinian needs your own copy of the Ocarina of Time ROM.'
      Write-Host 'Paste a download link or a file path (you can drag the file into this window).'
      Write-Host 'Add a Master Quest ROM too if you want both versions.'
    }

    $added = [Collections.Generic.List[string]]::new()
    while ($true) {
      $haveRom = $installed.Count -gt 0 -or $added.Count -gt 0
      $prompt = if ($haveRom) { 'Another ROM link or path (or press Enter to finish)' } else { 'ROM link or path' }
      $source = (Read-Host $prompt).Trim().Trim('"', "'")
      if (-not $source) {
        if ($haveRom) { return $added.ToArray() }
        continue
      }
      try {
        Add-Rom $source | ForEach-Object { $added.Add($_) }
      } catch {
        Write-Host "That didn't work: $($_.Exception.Message)" -ForegroundColor Red
      }
    }
  }

  function New-Shortcut($path) {
    $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($path)
    $shortcut.TargetPath = Join-Path $installDir 'soh.exe'
    # The game keeps saves and settings in its working directory.
    $shortcut.WorkingDirectory = $installDir
    $shortcut.Save()
  }

  $release = Invoke-RestMethod -Uri $releaseUrl -UseBasicParsing
  New-Item -ItemType Directory -Force -Path $installDir | Out-Null
  Install-Game $release

  $newRoms = Request-Roms

  foreach ($folder in @([Environment]::GetFolderPath('Programs'), [Environment]::GetFolderPath('Desktop'))) {
    New-Shortcut (Join-Path $folder 'Ship of Harkinian.lnk')
  }

  $launchArgs = @(foreach ($rom in $newRoms) { "`"$rom`"" })
  Write-Host ''
  Write-Host "Ship of Harkinian $($release.version) is installed." -ForegroundColor Green
  if ($launchArgs.Count -gt 0) {
    Write-Host 'Starting the game. It sets up your new ROMs first, then asks "Run SoH?"; click Yes.'
  } else {
    Write-Host 'Starting the game.'
  }
  # Passing ROMs makes the game process them even when it already has game data from
  # another ROM; otherwise it only looks for ROMs on its very first run.
  $launchOptions = @{ FilePath = (Join-Path $installDir 'soh.exe'); WorkingDirectory = $installDir } +
    $(if ($launchArgs.Count -gt 0) { @{ ArgumentList = $launchArgs } } else { @{} })
  Start-Process @launchOptions

  Write-Host 'This window will close in 10 seconds.'
  Start-Sleep -Seconds 10
  # Only on success: on failure the window stays open so the error can be read.
  # `exit` from iex code is unreliable, so end the host process directly.
  [Environment]::Exit(0)
}
