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
      HelpMessage = "Will flatten parent-child folders even if they don't have the same name, if the parents path contains the childs folder name")]
    [Alias("agro")]
    [Switch]
    $Agressive,

    [Parameter(
      Mandatory = $false,
      HelpMessage = "Prints what would happen if run")]
    [Switch]
    $WhatIf
)

$ErrorActionPreference = "Stop"

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
  $childFolders = Get-ChildItem -Force -Directory -LiteralPath "$($parentFolder.FullName)\"
  $childItems = Get-ChildItem -Force -LiteralPath "$($parentFolder.FullName)\"

  $onlyChildIsFolder = $childItems.count -eq 1 -and $childFolders.count -eq 1
  $childFolder = if ($childFolders.count -eq 1) { $childFolders[0] }
  $parentNameIsChildName = if ($childFolder) { "$(Split-Path $parentFolder.FullName -Leaf)" -eq "$(Split-Path $childFolders[0].FullName -Leaf)" }
  $parentNameContainsChildName = if ($childFolder) { "$($parentFolder.FullName)".toLower().Contains("$(Split-Path $childFolders[0].FullName -Leaf)") }
  $parentIsEmpty = $childItems.Count -eq 0

  
  if ($onlyChildIsFolder -and (($Agressive -and $parentNameContainsChildName) -or $parentNameIsChildName)) {
    # If there is only one child and its name is the same as the parent, flatten
    checkChildren $childFolder
    Write-Host "$($childFolder.FullName)"
    if (-not $WhatIf) {
      Get-ChildItem -Force -LiteralPath "$($childFolder.FullName)" | Move-Item -Destination "$($parentFolder.FullName)"
      if ("$($childFolder.FullName)".Split("\").Count -le $inputPathDepth) {
        throw "Something went wrong, we were about to delete $($childFolder.FullName)!"
      }
      Remove-Item -LiteralPath "$($childFolder.FullName)"
    }
  } elseif ($parentIsEmpty) {
    # If the child folder is empty, delete it
    Write-Host "$($parentFolder.FullName)"
    if (-not $WhatIf) {
      if ("$($parentFolder.FullName)".Split("\").Count -le $inputPathDepth) {
        throw "Something went wrong, we were about to delete $($parentFolder.FullName)!"
      }
      Remove-Item -LiteralPath "$($parentFolder.FullName)"
    }
  } else {
    # recursion
    foreach($childFolder in $childFolders) {
      checkChildren $childFolder
    }
  }
  
  return
}

checkChildren $parentFolder


