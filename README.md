# xlr-version-control
A collection of scripts to version control XL Release

Update-XLRBackup.ps1 is designed to be run on a schedule or ad-hoc. It polls the XLR API and checks to see if any templates have been amended since the last run. If there have, it iterates over all the templates and compares the latest JSON format with the last known version. If there is a difference, it increments the version number and keeps a new copy in the store. 

You can pass the encoded credentials as an argument, so there will be no interaction. 
The user will only be able to version control templates it can see. I recommend you create a fresh user with read only rights.

Update-XLRJsonTemplate.ps1 is for uploading the JSON into your environment. XLR expects a JSON Array, meaning it should have leading and trailing brackets "[" but of course we have archived them as individual objects. This script simply wraps it and posts it - of course the user will need write power here so you may well wish to have this on your desktop for when you need it. 

Yes, this could be done in a cleaner manner - for a start it should be possible to do it in a single API call rather than 1 per template. The advantage of this method is that as of Version 6, we get a nice folder structure in the store generated automatically. It also means not worrying about crawling the output trying to determine the start of each template. 

Next logical steps:
 - Rewriting in Java or Python to make it Linux compatible.
 - Running as a service, rather than as a scheduled task. 
 - Adding the resulting additions to source control automatically. 
