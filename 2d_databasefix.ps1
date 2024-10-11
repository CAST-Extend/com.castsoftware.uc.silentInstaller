## This is a bug fix for updating SSO parameters in database
## we needed this fix because installation is not able to use the host url and host name from 
## defaults file. Once that is fixed, we can remove this work around script.

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
$updateQuery1 = "UPDATE aip_config.properties SET value = 'http://localhost:8086' where prop_key = 'keycloak.uri';"
$updateQuery2 = "UPDATE aip_config.properties SET value = 'localhost' where prop_key = 'eureka.host';"
$updateQuery3 = "UPDATE aip_config.properties SET value = 'http://localhost:8087' where prop_key = 'dashboards.url';"

# Use psql to connect to the PostgreSQL server and execute the SQL command
write-host "INFO: Applying keycloak.uri, eureka.host and dashboards.url fix by updating database. Below queries are fired"
write-host "SQL QUERY: " + $updateQuery1

& Utils\PSQL\psql -h $databasehost -p $port -U $username -d $defaultDatabase -c $updateQuery1

write-host "SQL QUERY: " + $updateQuery2
& Utils\PSQL\psql -h $databasehost -p $port -U $username -d $defaultDatabase -c $updateQuery2

write-host "SQL QUERY: " + $updateQuery3
& Utils\PSQL\psql -h $databasehost -p $port -U $username -d $defaultDatabase -c $updateQuery3

# Cleanup environment variable
Remove-Item env:PGPASSWORD