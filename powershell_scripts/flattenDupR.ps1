Param (
    [Parameter(
      Mandatory = $true,
      HelpMessage = "Path to zip file or folder with zip files")]
      # TODO: read from pipe and default
    [Alias("i")]
    [String]
    $inputPath,

    [Parameter(
      Mandatory = $false,
      HelpMessage = "Prints what would happen if run")]
    [Switch]
    $WhatIf
)

if (-not (Test-Path -LiteralPath "$($inputPath)")) {
  Write-Host "$($inputPath)"
  throw "Input folder does not exist."
}

$inputPath = Convert-Path $inputPath
$inputPathDepth = $inputPath.Split("\").Count
$parentFolder = Get-Item $inputPath

if (!($parentFolder.PSIsContainer)) {
  throw "Input path is not a folder."
}

function checkChildren($parentFolder) {
  # Get all direct children of input path
  $childFolders = Get-ChildItem -Directory -LiteralPath "$($parentFolder.FullName)\"
  $childItems = Get-ChildItem -LiteralPath "$($parentFolder.FullName)\"

  # If there is only one child and its name is the same as the parent, flatten
  if ($childItems.count -eq 1 -and $childFolders.count -eq 1 -and $(Split-Path $childFolders[0].FullName -Leaf) -eq $(Split-Path $parentFolder.FullName -Leaf)) {
    $childFolder = $childFolders[0]
    checkChildren $childFolder
    Write-Host "$($childFolder.FullName)"
    if (-not $WhatIf) {
      Get-ChildItem -LiteralPath "$($childFolder.FullName)" | Move-Item -Destination "$($parentFolder.FullName)"
      if ("$($childFolder.FullName)".Split("\").Count -le $inputPathDepth) {
        throw "Something went wrong, we were about to delete $($childFolder.FullName)!"
      }
      if ($Error.Count) {
        throw "There was some kind of error, lets not continue."
      }
      Remove-Item -Force -LiteralPath "$($childFolder.FullName)"
    }
  } else {
    foreach($childFolder in $childFolders) {
      checkChildren $childFolder
    }
  }
  
  return
}

$Error.Clear()

checkChildren $parentFolder


