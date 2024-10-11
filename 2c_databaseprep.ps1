# Define connection parameters
# Read configurations, list of packages to download
$jsonInstallConfigFile = "Config\InstallConfig.json"

# Read the JSON file for list of files to download
$jsonContent = Get-Content -Path $jsonInstallConfigFile -Raw
$data = $jsonContent | ConvertFrom-Json

$databasehost = $data.InstallParameters.csshostname
$port = $data.InstallParameters.cssport
$username = $data.InstallParameters.cssuser
$password = $data.InstallParameters.csspassword
$newDatabase = $data.InstallParameters.keycloakdb
$defaultDatabase = "postgres" #default database already exists hence no need to move this to config file.

# Name of the new database to create

# Store PostgreSQL password securely (optional)
$env:PGPASSWORD = $password

# SQL command to create the database
$sqlCreateDatabase = "CREATE DATABASE $newDatabase;"

# Use psql to connect to the PostgreSQL server and execute the SQL command
write-host "INFO: Creating database using below command:"
write-host "INFO: Utils\PSQL\psql -h $databasehost -p $port -U $username -c $sqlCreateDatabase"
& Utils\PSQL\psql -h $databasehost -p $port -U $username -d $defaultDatabase -c $sqlCreateDatabase

# Cleanup environment variable
Remove-Item env:PGPASSWORD