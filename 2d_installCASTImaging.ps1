#package to install and location where it was downloaded
$CurrentDirectory = Get-Location
$pathToInstallers="$CurrentDirectory\download"
$installerID="com.castsoftware.imaging"
$extractToPath="$CurrentDirectory\download"

# installation parameters files
$jsonInstallConfigFile = "config\InstallConfig.json"

$installTemplatesdirectory = "config\installtemplates"
$installtemplateForCASTImaging = $installTemplatesdirectory + "\imagingsetup.inf.template"

$installdefaultsdirectory = "logs\generatedinstallfiles"
$installdefaultsFileForCASTImaging = $installdefaultsdirectory + "\imagingsetup.inf"


# Read the JSON file Install parameters
$jsonContent = Get-Content -Path $jsonInstallConfigFile -Raw
$data = $jsonContent | ConvertFrom-Json
$installDir = $data.InstallParameters.installdir.Replace("\", "/")

# Check if the directory for default settings exists, create if it doesn't exist
if (-not (Test-Path -Path $installdefaultsdirectory)) {
    New-Item -Path $installdefaultsdirectory -ItemType Directory -Force
}


#read cast-imaging specific properties template and generate usable defaults per Installconfig.json
$instaltemplateForCASTImagingContent = Get-Content -Path $installtemplateForCASTImaging -Raw
#generate the new setup file using the install path per the config provided
$outContent = $instaltemplateForCASTImagingContent.Replace("template_installDir", "$installDir")
# Check if the directory exists, and create it if it doesn't
# create output defaults file
$outContent | Out-File -FilePath $installdefaultsFileForCASTImaging 

#Function to Install the component
function Install-SilentApp {
    param (
        [string]$installerPath,
        [string]$silentArgs
    )

	#DEBUG:
	Write-Host "Print Installation command below : ---"
	Write-Host "Start-Process $installerPath $silentArgs -Verb RunAs -Wait"

	# Run the installer as an administrator
    # Start-Process -FilePath java -ArgumentList "-jar", $installerPath, $silentArgs -Verb RunAs -Wait
    Start-Process -FilePath $installerPath -ArgumentList $silentArgs -Verb RunAs -Wait

    # Check the exit code to confirm the installation was successful
	Write-Host "Installation completed"
}

$files = Get-ChildItem -Path $pathToInstallers -File

foreach ($file in $files) {
	
	$fileNameParts = $file.Name.split("[0123456789]")

    if ($fileNameParts[0] -eq "$installerID.") {
        $InstallerFullPath = $file.FullName
		$InstallerFileName = [System.IO.Path]::GetFileNameWithoutExtension($InstallerFullPath)
		continue
    }
}

if (![string]::IsNullOrEmpty($InstallerFileName)) {
	
	# Load the required assembly
	Add-Type -AssemblyName "System.IO.Compression.FileSystem"

	# Append the name of zip file Extract folder
	$extractToPath = "$extractToPath\$InstallerFileName"
	
	Write-host "Extracting $InstallerFileName at $extractToPath"
	
	#Check if the extraction folder exists
	if (-not (Test-Path -Path $extractToPath)) 
	{
		New-Item -Path $extractToPath -ItemType Directory
	}

	# Check if the folder is empty
	$folderIsEmpty = -not (Get-ChildItem -Path $extractToPath)
	if ($folderIsEmpty) 
	{
		[System.IO.Compression.ZipFile]::ExtractToDirectory($InstallerFullPath, $extractToPath)
		Write-Host "INFO: Extraction complete."
	} 
	else 
	{
		Write-Host "INFO: Extraction was already done hence skipping."
	} 
	
	#Now its time to install the application. Multiple installation for Console Service
	$files = Get-ChildItem -Path $extractToPath -File

	Write-Host "################# Installing CAST Imaging #################"
	## Step 3: Install "CAST Imaging" Service
	$InstallerPattern = "^ImagingSystemSetup*"
	$file = $files | Where-Object { $_ -match $InstallerPattern }
	## TODO: install log to be generated and saved
	$setuplogfile = "logs\" + $file.BaseName + "_install.log"
	$setupArgs = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /LOG=" + $setuplogfile + " /LOADINF=" + $installdefaultsFileForCASTImaging
	#DEBUG 
	#$setupArgs = "/SUPPRESSMSGBOXES /LOG=" + $setuplogfile + " /LOADINF=" + $installdefaultsFileForCASTImaging
	$InstallCommand = $extractToPath + "\ImagingSystemSetup.exe"
	Install-SilentApp $InstallCommand $setupArgs
}



