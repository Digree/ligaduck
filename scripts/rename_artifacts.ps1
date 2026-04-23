# Rename build artifacts to 'Liga Duck Manager'
# Usage: ./scripts/rename_artifacts.ps1

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$extensions = @('apk','ipa','dmg')
foreach ($ext in $extensions) {
    $files = Get-ChildItem -Path "build" -Recurse -Filter "*.$ext" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($files -and $files.Count -gt 0) {
        $file = $files[0]
        $target = Join-Path $file.DirectoryName ("Liga Duck Manager." + $ext)
        if ($file.FullName -ieq $target) {
            Write-Output "Already named: $($file.FullName)"
        } else {
            Copy-Item -Path $file.FullName -Destination $target -Force
            Write-Output "Copied $($file.Name) -> $(Split-Path $target -Leaf)"
        }
    }
}
