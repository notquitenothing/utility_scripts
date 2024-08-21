Param (
    [Parameter(
      Mandatory = $true,
      HelpMessage = "Path to zip file or folder with zip files")]
      # TODO: read from pipe and default
    [Alias("i")]
    [String]
    $inputPath
)

if (-not (Test-Path $inputPath)) {
  throw "Input file or folder does not exist"
}

$inputPath = Convert-Path $inputPath
$inputFile = Get-Item $inputPath
$queue = [System.Collections.Generic.Queue[hashtable]]::new()
if ($inputFile.PSIsContainer) {
  $hasZips = $inputFile.FullName | Get-ChildItem -Include "*.zip","*.7z","*.rar" -Recurse
  foreach ($zip in $hasZips) {
    try {
      $queue.Enqueue(@{
        LiteralPath     = $zip.FullName
        DestinationPath = Join-Path $zip.DirectoryName $zip.BaseName
      })
    } catch {
      Write-Host "An error occurred in file: $($zip)"
      Write-Host $_
      Return
    }
  }
} else {
  try {
    $queue.Enqueue(@{
      LiteralPath     = $inputFile.FullName
      DestinationPath = Join-Path $inputFile.DirectoryName $inputFile.BaseName
    })
  } catch {
    Write-Host "An error occurred in file: $($inputFile)"
    Write-Host $_
    Return
  }
}

while ($queue.Count) {
  $current = $queue.Dequeue()
  try {
    if (-not (Test-Path -LiteralPath "$($current['LiteralPath'])")) {
      throw "Archive was not found: $($current['LiteralPath'])"
    }

    # Expand-Archive @current
    7z.exe x -y -o"$($current['DestinationPath'])" "$($current['LiteralPath'])"
    if ($? -eq $false) {
      throw "There was an error while unzipping using 7zip"
    }
    $hasZips = "$current['DestinationPath']" | Get-ChildItem -Include "*.zip","*.7z","*.rar" -Recurse

    foreach ($zip in $hasZips) {
      $queue.Enqueue(@{
        LiteralPath     = $zip.FullName
        DestinationPath = Join-Path "$($zip.DirectoryName)" "$($zip.BaseName)"
      })
    }
    
    Remove-Item -Force -LiteralPath "$($current['LiteralPath'])"

    if (Test-Path -LiteralPath "$($current['LiteralPath'])") {
      throw "Archive was not deleted: $($current['LiteralPath'])"
    }
  } catch {
    Write-Host "An error occurred in file: $($current['LiteralPath'])"
    Write-Host $_
    Break
  }
}