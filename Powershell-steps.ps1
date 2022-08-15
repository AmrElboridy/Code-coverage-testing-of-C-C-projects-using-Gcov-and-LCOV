# Find a file path
Get-Childitem –Path C:\ -Include *lcov_cobertura.py* -Recurse -ErrorAction SilentlyContinue

# Assign env variavble

Set-Variable -Name "GENTHML" -Value ("C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml") -Visibility Public -Scope global 
[System.Environment]::SetEnvironmentVariable('GENTHML','C:\ProgramData\chocolatey\lib\lcov\tools\bin',[System.EnvironmentVariableTarget]::User)

# Rename file
Rename-Item -Path "c:\logfiles\daily_file.txt" -NewName "monday_file.txt"