<#
.SYNOPSIS
Formats PowerShell files in the specified directory or file.

Use cases:
* Run as a local pre-commit hook to auto format code before committing
* Run with -CheckOnly switch as a PR CI build step to ensure all code is formatted correctly

.NOTES
Requires PSScriptAnalyzer module. Install it with:
    ./FormatCode.ps1 -InstallDependencies

.EXAMPLE
    ./FormatCode.ps1

    Formats all PowerShell files in current directory.

.EXAMPLE
    ./FormatCode.ps1 -Directory "src/my_directory"

    Formats all PowerShell files in the specified directory.

.EXAMPLE
    ./FormatCode.ps1 -File "src/my_directory/my_module.psm1"

    Formats a single PowerShell file.
#>

param (
    $Directory = ".",
    $File = $null,
    $SettingsFile = "$PSScriptRoot/PSScriptAnalyzerSettings.psd1",
    [switch] $ShowOnlyReformat, # Only show files that need reformatting
    [switch] $CheckOnly, # Check formatting but don't update files
    [switch] $InstallDependencies # Install required modules
)

$ErrorActionPreference = "Stop"

$BaseDirectory = Split-Path -Parent $PSScriptRoot
$Directory = Resolve-Path $Directory

if ($InstallDependencies) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider NuGet -Force
    Import-PackageProvider NuGet -Force
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    Install-Module -Name PSScriptAnalyzer -SkipPublisherCheck -AllowClobber -Scope CurrentUser -Force -RequiredVersion 1.23.0
}

if ($File) {
    $files = @(Get-Item -Path $File)
    Write-Host "Checking '$File'..."
}
elseif ($Directory) {
    $files = Get-ChildItem -Path $Directory -Include *.ps1, *.psm1 -Recurse
    Write-Host "Checking $($files.Count) PowerShell files in '$Directory'..."
}
else {
    Write-Host "error: must pass -Directory or -File"
    exit 1
}

$errorFiles = @()
$nonFormattedFiles = @()

$files = $files | Sort-Object -Property FullName

$indent = "   "
foreach ($file in $files) {
    $path = ($file.FullName.replace($BaseDirectory, '')) -replace '^(\\|/)', ''
    $content = Get-Content -Raw -Path $file.FullName

    if ($null -eq $content) {
        if (!$ShowOnlyReformat) {
            Write-Host "$indent✅ $path [OK - Empty]"
        }
        continue
    }

    # Invoke-Formatter has showed some flaky behavior, so retry it a few times just in case.
    $maxAttempts = 3
    $attempts = 0
    $success = $false
    while ($attempts -lt $maxAttempts) {
        try {
            $options = @{
                Script = $content
            }
            if (Get-ChildItem -Path $SettingsFile -ErrorAction SilentlyContinue) {
                $options.Settings = $SettingsFile
            }
            $formatted = Invoke-Formatter @options
            $success = $true
            break
        }
        catch {
            $attempts++
            Write-Host $indent -NoNewline
            if ($attempts -eq $maxAttempts) {
                $errorFiles += $file
                Write-Host "❌ $path [ERROR]"
                Write-Host "   Error while formatting '$path': $_`n"
            }
            else {
                Write-Host "❗ Invoke-Formatter failed, retrying for '$path' (attempt $attempts)"
                Start-Sleep -Seconds 1
            }
        }
    }
    if (!$success) {
        continue
    }

    if ($formatted -eq $content) {
        if (!$ShowOnlyReformat) {
            Write-Host "$indent✅ $path  [OK]"
        }
    }
    else {
        Write-Host $indent -NoNewline

        $nonFormattedFiles += $file
        if ($CheckOnly) {
            Write-Host "❌ $path [NEEDS REFORMAT]"
        }
        else {
            Write-Host "⚠️  $path [NEEDS REFORMAT] "  -NoNewline
            Set-Content -Path $file.FullName -Value $formatted -NoNewline
            Write-Host "Reformatted ✅"
        }
    }
}

function Write-ErrorLog ($message) {
    if ($env:TF_BUILD -eq 'True') {
        Write-Host "##vso[task.logissue type=error]$message"
    }
    else {
        Write-Error $message
    }
}

$exitCode = 0

if ($errorFiles.Count -gt 0) {
    Write-Host
    Write-ErrorLog "$($errorFiles.Count) files encountered an error while formatting. See above."
    $exitCode = 1
}

if ($nonFormattedFiles.Count -gt 0) {
    if ($CheckOnly) {
        Write-ErrorLog "$($nonFormattedFiles.Count) files are not formatted properly. Run script FormatCode.ps1 and commit the changes."
        $exitCode = 1
    }
    else {
        Write-Host "✅ $($nonFormattedFiles.Count) files have been reformatted."
    }
}
else {
    Write-Host "✅ All $($files.Count) files are formatted correctly."
}

exit $exitCode
