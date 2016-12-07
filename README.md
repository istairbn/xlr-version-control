# xlr-version-control
A collection of scripts to version control XL Release

Update-XLRBackup.ps1 is designed to be run on a schedule or ad-hoc. It polls the XLR API and checks to see if any templates have been amended since the last run. If there have, it iterates over all the templates and compares the latest JSON format with the last known version. If there is a difference, it increments the version number and keeps a new copy in the store. 

You can pass the encoded credentials as an argument, so there will be no interaction. 
