#############################################################
## NOTE: You may get PS execution denied in your sessions. ##
## Here are the two options to allow PS in your machine    ##
## Allow PS execution for current session
# Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
## Allow PS execution for current user / all sessions
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#############################################################

# Read configurations, list of packages to download
$jsonFilePath = "config\ExtendConfig.json"

# Read the JSON file for list of files to download
$jsonContent = Get-Content -Path $jsonFilePath -Raw
$ExtendConfig = $jsonContent | ConvertFrom-Json

#read API KEY from the config file.
$apiKey = ""
foreach ($connectionItem in $ExtendConfig.connection) 
{
	if ($connectionItem.id -eq "apikey")
	{
		$apiKey = $connectionItem.value
	}
}

if ("" -eq $apiKey)
{
	Write-Host "Missing Key: !!! Looks like apiKey is not entered. Please add your key in file -> config\ExtendConfig.json"
	while ($readInput -ne "abra ka dabra") #stop user from moving forward.
	{
		$readInput = Read-Host "Exit by pressing ^C, add your key and restart the process"
		#Do nothing. Wait for user to process Ctrl+C to exit.
	}
}

# determine the download location using current directory
$CurrentDirectory = Get-Location

$destinationPath = "$CurrentDirectory\download\"
$baseUrl = "https://extend.castsoftware.com/api/package/"
$baseDownloadUrl = $baseUrl.TrimEnd('/') + "/download/"

# Function to get the size of a remote file
function Get-RemoteFileSize {
    param (
        [string]$url
    )

    try {
        $request = [System.Net.WebRequest]::Create($url)
        $request.Method = "HEAD"
		$request.Headers.Add("x-nuget-apikey", $apiKey)
        $response = $request.GetResponse()
        $contentLength = $response.Headers["Content-Length"]
        $response.Close()
        return [long]$contentLength
    }
    catch {
        Write-Error "Failed to retrieve remote file size: $_"
        return $null
    }
}


Write-host "Initiating file download at $destinationPath."

# Create the destination folder if it does not exist
if (-not (Test-Path -Path $destinationPath)) {
    New-Item -Path $destinationPath -ItemType Directory | Out-Null
}

# class declarations
$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add("x-nuget-apikey", $apiKey)
$webClient.Headers.Add("Accept", "application/json")

#Iterate over each package and download the file
foreach ($package in $ExtendConfig.packages) {
	
	$packageId = $package.id
    $version = $package.version

	$fileInfoURL = "$baseUrl$packageId/$version"
	$fileDownloadURL = "$baseDownloadUrl$packageId/$version"

	#retreive response body for the file we are about to download. We need to get latest version number of file
	$responseBody = $webClient.DownloadString($fileInfoURL)
	$responseJson = $responseBody | ConvertFrom-Json
	$responseVersion = $responseJson.version

	$destinationFilePath = "$destinationPath$packageId.$responseVersion.zip"
	$FileAlreadyExists = $false

	Write-Host "Downloading $packageId version $version (found $responseVersion)..." -NoNewline

	# Get the size of the remote file
	$remoteFileSize = Get-RemoteFileSize -url $fileDownloadURL

	if ($null -eq $remoteFileSize ) 
	{
		Write-Host "Unable to determine remote file size. Skipping."
		continue
	}

	# Check if the file already exists and if its size matches the remote file size
	if (Test-Path -Path $destinationFilePath) {
		$localFileSize = (Get-Item -Path $destinationFilePath).Length
		if ($localFileSize -eq $remoteFileSize) {
			$FileAlreadyExists = $true
			Write-Host "File already exists and is the correct size. Skipping download."
			continue
		}
		else {
			Write-Host "File exists but is a different size. Downloading new file..."
		}
	}

	if (-not $FileAlreadyExists) {

		
		#Download the file from CAST Extend if not already exists or is not the right size
		$webClient.DownloadFile($fileDownloadURL, $destinationFilePath)
		Write-Host "Downloaded."
	}

}

Write-Host "Done"
