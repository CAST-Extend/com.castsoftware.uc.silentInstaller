#download required CAST installers
& .\1_DownloadCastSoftware.ps1

#unzip components and install
& .\2a_installCSS.ps1
& .\2b_installCASTAIP.ps1
& .\2c_databaseprep.ps1
& .\2c_installCASTConsoleEnt.ps1
& .\2d_databasefix.ps1
& .\2d_installCASTImaging.ps1
& .\3_RestartServicesFix.ps1