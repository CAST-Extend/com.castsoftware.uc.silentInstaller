# Silent Installer
Silentinstaller is a package that automatically downloads and installs CAST core components, setting up the environment for analysis without user intervention.

# Pre-requisite 
1. Install Java - Java must be installed before running the scripts. If not installed, user will face issues during installation of Enterprise console components.
2. Enable script execution by running following commands in your powershell commandlet before running scripts.

   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process #for current session
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser #current user, all sessions

# How to Run
1. Run Pre-requisities 
2. Edit config/ExtendConfig.json to add your key
3. Edit config/InstallConfig.json to specify the installation directory
4. Run 0_CASTSetup.ps1 as admin i.e open **Powershell prompt as admin**, go to root directory of scripts and run ".\0_CASTSetup.ps1"

# Known Issues
if you get script execution denied issue / script not digitinally signed issue, run following command in your powershell commandlet before running the script.
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
