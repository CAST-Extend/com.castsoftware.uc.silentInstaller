
$CurrentDirectory = Get-Location
$pathToInstallers="$CurrentDirectory\download"
$installerID="com.castsoftware.css"
$extractToPath="$CurrentDirectory\download"

# Read configurations, list of packages to download
$jsonInstallConfigFile = "Config\InstallConfig.json"

# Read the JSON file for list of files to download
$jsonContent = Get-Content -Path $jsonInstallConfigFile -Raw
$data = $jsonContent | ConvertFrom-Json

$installDir = $data.InstallParameters.installdir + "\" + $data.InstallParameters.cssdir
$cssport = $data.InstallParameters.cssport

#Time to Install the component
function Install-SilentApp {
    param (
        [string]$installerPath,
        [string]$silentArgs
    )

    # Check if the installer file exists
    if (-Not (Test-Path -Path $installerPath)) {
        Write-Host "Installer not found at: $installerPath"
        return
    }

    # Run the installer as an administrator
    Start-Process -FilePath $installerPath -ArgumentList $silentArgs -Verb RunAs -Wait

    # Check the exit code to confirm the installation was successful
	Write-Host "Installation completed" # with code $LASTEXITCODE"
}

Write-Host "################# Installing CAST CSS #################"

$files = Get-ChildItem -Path $pathToInstallers -File

foreach ($file in $files) {

    # Check if the content contains the search string
    if ($file.Name -like "*$installerID*") {
        $InstallerFullPath = $file.FullName
		$InstallerFileName = [System.IO.Path]::GetFileNameWithoutExtension($InstallerFullPath)
		continue
    }
}

if (![string]::IsNullOrEmpty($InstallerFileName)) 
{
	# Load the required assembly
	Add-Type -AssemblyName "System.IO.Compression.FileSystem"

	# Extract the ZIP file
	$extractToPath = "$extractToPath\$InstallerFileName"
	
	Write-host "Extracting $InstallerFileName at $extractToPath"
	
	#Check if the extraction folder exists
	if (-not (Test-Path -Path $extractToPath)) 
	{
		New-Item -Path $extractToPath -ItemType Directory
	}

	# Check if the folder is empty
	$folderIsEmpty = -not (Get-ChildItem -Path $extractToPath | Where-Object { $_.PSIsContainer })
	if ($folderIsEmpty) 
	{
		[System.IO.Compression.ZipFile]::ExtractToDirectory($InstallerFullPath, $extractToPath)
		Write-Host "INFO: Extraction complete."
	} 
	else 
	{
		Write-Host "INFO: Extraction was already done hence skipping."
	} 
	
	#Time to install the application
	$setuplogfile = "logs\caststorageserviceinstall.log"
	$installerPath = "$extractToPath\setup.bat"
	$setupArgs = "/qn INSTALLDIR=$installDir CSSPORT=$cssport DBDATADIR=$installDir"
	Write-Host "INFO: Starting Installation"
	Install-SilentApp -installerPath $installerPath $setupArgs

}





