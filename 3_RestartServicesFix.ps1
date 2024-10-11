write-host '##== Restarting services for workaround fix to to take effect ==##' 
Restart-Service -Name aip-sso-service
Restart-Service -Name aip-service-registry-service
Restart-Service -Name aip-node-service
Restart-Service -Name aip-gateway-service
write-host '##== All Done ==##'