#package to install and location where it was downloaded
$CurrentDirectory = Get-Location
$pathToInstallers="$CurrentDirectory\download"
$installerID="com.castsoftware.aip.console"
$extractToPath="$CurrentDirectory\download"

# installation parameters files
$jsonInstallConfigFile = "config\InstallConfig.json"

$installTemplatesdirectory = "config\installtemplates"
$installtemplateForAIPSSO = $installTemplatesdirectory + "\aip-sso-install-defaults.template"
$installtemplateForAIPRegistry = $installTemplatesdirectory + "\aip-registry-install-defaults.template"
$installtemplateForAIPGateway = $installTemplatesdirectory + "\aip-gateway-install-defaults.template"
$installtemplateForAIPNode = $installTemplatesdirectory + "\aip-node-install-defaults.template"
$installtemplateForAIPHDED = $installTemplatesdirectory + "\aip-hded-install-defaults.template"

$installdefaultsdirectory = "logs\generatedinstallfiles"
$installdefaultsFileForAIPSSO = $installdefaultsdirectory+ "\aip-sso-install.defaults"
$installdefaultsFileForAIPRegistry = $installdefaultsdirectory + "\aip-registry-install.defaults"
$installdefaultsFileForAIPGateway = $installdefaultsdirectory + "\aip-gateway-install.defaults"
$installdefaultsFileForAIPNode = $installdefaultsdirectory + "\aip-node-install.defaults"
$installdefaultsFileForAIPHDED = $installdefaultsdirectory + "\aip-hded-install.defaults"


# Read the JSON file Install parameters
$jsonContent = Get-Content -Path $jsonInstallConfigFile -Raw
$data = $jsonContent | ConvertFrom-Json
$installDir = $data.InstallParameters.installdir.Replace("\", "/")

# Check if the directory for default settings exists, create if it doesn't exist
if (-not (Test-Path -Path $installdefaultsdirectory)) {
    New-Item -Path $installdefaultsdirectory -ItemType Directory -Force
}


#read AIP-SSO specific properties template and generate usable defaults per Installconfig.json
$instaltemplateForAIPSSOContent = Get-Content -Path $installtemplateForAIPSSO -Raw
#generate the new setup file using the install path per the config provided
$outContent = $instaltemplateForAIPSSOContent.Replace("template_installDir", "$installDir")
# create output defaults file
$outContent | Out-File -FilePath $installdefaultsFileForAIPSSO 

#read AIP-Registry specific properties template and generate usable defaults per Installconfig.json
$instaltemplateForAIPRegistryContent = Get-Content -Path $installtemplateForAIPRegistry -Raw
#generate the new setup file using the install path per the config provided
$outContent = $instaltemplateForAIPRegistryContent.Replace("template_installDir", "$installDir")
# create output defaults file
$outContent | Out-File -FilePath $installdefaultsFileForAIPRegistry 

#read AIP-Gateway specific properties template and generate usable defaults per Installconfig.json
$instaltemplateForAIPGatwayContent = Get-Content -Path $installtemplateForAIPGateway -Raw
#generate the new setup file using the install path per the config provided
$outContent = $instaltemplateForAIPGatwayContent.Replace("template_installDir", "$installDir")
# Check if the directory exists, and create it if it doesn't
# create output defaults file
$outContent | Out-File -FilePath $installdefaultsFileForAIPGateway 

#read AIP-Node specific properties template and generate usable defaults per Installconfig.json
$instaltemplateForAIPNodeContent = Get-Content -Path $installtemplateForAIPNode -Raw
#generate the new setup file using the install path per the config provided
$outContent = $instaltemplateForAIPNodeContent.Replace("template_installDir", "$installDir")
# Check if the directory exists, and create it if it doesn't
# create output defaults file
$outContent | Out-File -FilePath $installdefaultsFileForAIPNode 

#read AIP-HDED specific properties template and generate usable defaults per Installconfig.json
$instaltemplateForAIPHDEDContent = Get-Content -Path $installtemplateForAIPHDED -Raw
#generate the new setup file using the install path per the config provided
$outContent = $instaltemplateForAIPHDEDContent.Replace("template_installDir", "$installDir")
# Check if the directory exists, and create it if it doesn't
# create output defaults file
$outContent | Out-File -FilePath $installdefaultsFileForAIPHDED 

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

	# Here is the installation sequence
	# 	"AIP-SSO*" = 1
	# 	"AIP-Service-Registry*" = 2
	# 	"AIP-Gateway*" = 3
	# 	"AIP-Node*" = 4
	# 	"cast-integrated-health-engineering*" = 5
	$AIP_SSO_Install = $True
	$AIP_Service_Registry = $True
	$AIP_Gateway = $True
	$AIP_Node = $True
	$cast_integrated_health_engineering = $False

	#Below if situations are only for testing. They should all be true in normal situations
	if ($AIP_SSO_Install -eq $True)
	{
		Write-Host "################# Installing AIP-SSO #################"
		## Step 1: Install "AIP-SSO*" Service
		$InstallerPattern = "^AIP-SSO*"
		$file = $files | Where-Object { $_ -match $InstallerPattern }
		## TODO: install log to be generated and saved
		## $setuplogfile = "logs\" + $file + ".log"
		$setupArgs = "-jar " + $file.FullName + " -defaults-file " + $installdefaultsFileForAIPSSO + " -auto"
		$InstallCommand = "java"
		Install-SilentApp $InstallCommand $setupArgs
	} 

	if ($AIP_Service_Registry -eq $True)
	{
		Write-Host "################# Installing AIP-Registry #################"
		## Step 2: Install "AIP-Service-Registry*" Service
		$InstallerPattern = "^AIP-Service-Registry*"
		$file = $files | Where-Object { $_ -match $InstallerPattern }
		## TODO: install log to be generated and saved
		## $setuplogfile = "logs\" + $file + ".log"
		$setupArgs = "-jar " + $file.FullName + " -defaults-file " + $installdefaultsFileForAIPRegistry + " -auto"
		$InstallCommand = "java"
		Install-SilentApp $InstallCommand $setupArgs
	}

	if ($AIP_Gateway -eq $True)
	{
		Write-Host "################# Installing AIP-Gateway #################"
		## Step 3: Install "AIP-Gateway*" Service
		$InstallerPattern = "^AIP-Gateway*"
		$file = $files | Where-Object { $_ -match $InstallerPattern }
		## TODO: install log to be generated and saved
		## $setuplogfile = "logs\" + $file + ".log"
		$setupArgs = "-jar " + $file.FullName + " -defaults-file " + $installdefaultsFileForAIPGateway + " -auto"
		$InstallCommand = "java"
		Install-SilentApp $InstallCommand $setupArgs
	}

	if ($AIP_Node -eq $True)
	{
		Write-Host "################# Installing AIP-Node #################"
		## Step 3: Install "AIP-Gateway*" Service
		$InstallerPattern = "^AIP-Node*"
		$file = $files | Where-Object { $_ -match $InstallerPattern }
		## TODO: install log to be generated and saved
		## $setuplogfile = "logs\" + $file + ".log"
		$setupArgs = "-jar " + $file.FullName + " -defaults-file " + $installdefaultsFileForAIPNode + " -auto"
		$InstallCommand = "java"
		Install-SilentApp $InstallCommand $setupArgs
	}

	if ($cast_integrated_health_engineering -eq $True)
	{
		Write-Host "################# Installing AIP-HDED #################"
		## Step 3: Install "AIP-HDED*" Service
		$InstallerPattern = "^cast-integrated-health-engineering*"
		$file = $files | Where-Object { $_ -match $InstallerPattern }
		## TODO: install log to be generated and saved
		## $setuplogfile = "logs\" + $file + ".log"
		$setupArgs = "-jar " + $file.FullName + " -defaults-file " + $installdefaultsFileForAIPHDED + " -auto"
		$InstallCommand = "java"
		Install-SilentApp $InstallCommand $setupArgs
	}
}





