# PowerShell-Formatter
Script to format your PowerShell scripts using PSScriptAnalyzer. Used as a Git pre-commit hook and in CI pipelines.

## Usage

### Format Code

```powershell
./FormatCode.ps1
```

### Format Code (Check Only - Don't Modify Files)

```powershell
./FormatCode.ps1 -CheckOnly
```

### Format Code (Check Only - Show Only Files That Need Reformatting)

```powershell
./FormatCode.ps1 -CheckOnly -ShowOnlyReformat
```

### Format Code with Custom Settings and Rules

See [PSScriptAnalyzer rules reference](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/readme?view=ps-modules).

Create a file called `PSScriptAnalyzerSettings.psd1` next to FormatCode.ps1.

Or, specify a custom settings file name using the `-SettingsFile` parameter.

```powershell
./FormatCode.ps1 -SettingsFile settings.psd1
```

## Screenshots

### All Files OK (`FormatCode.ps1`)
![image](https://github.com/user-attachments/assets/2ba4265d-5094-4c1f-b0ef-0b9a83888cca)

### Files Needed Reformatting (`FormatCode.ps1`)
![image](https://github.com/user-attachments/assets/3fcfb10d-8d0d-4eeb-a070-f0da82cbc666)

### Files Need Reformatting (`FormatCode.ps1 -CheckOnly`)

Checks formatting and fails if any files need reformatting.

![image](https://github.com/user-attachments/assets/7dd64dab-f739-42c4-8fad-b9c126dc106e)

### Files Need Reformatting (`FormatCode.ps1 -CheckOnly -ShowOnlyReformat`)
Checks formatting and fails if any files need reformatting. Only outputs files that need reformatting.

![image](https://github.com/user-attachments/assets/b8c8bbbe-6afd-4f28-8b0c-c6801fae9448)
