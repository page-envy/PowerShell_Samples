# eBookDL.ps1  #
# Author: Nick Page    #
# Version: 2.0         #
# Date: 11 July 2017 #
#-------------------------------------------------------------------------------
# >>> MUST PERFORM FIRST-RUN USING INTERNET EXPLORER PRIOR TO USE <<<
# This script is intended to be a helpful tool in acquiring the eBooks offered
# by Eric Ligman on the MSDN on July 11, 2017. Running this tool will 
# automatically download and sort all eBooks that are offered. 
#-------------------------------------------------------------------------------
$dest="C:\Users\$env:Username\Downloads\eBooks\"
 
# Find Book Titles
$webPage = 'https://blogs.msdn.microsoft.com/mssmallbiz/2017/07/11/largest-free-microsoft-ebook-giveaway-im-giving-away-millions-of-free-microsoft-ebooks-again-including-windows-10-office-365-office-2016-power-bi-azure-windows-8-1-office-2013-sharepo/'
$webPageHTML = Invoke-WebRequest -URI $webPage
$tableList = $webPageHTML.ParsedHtml.getElementsByTagName('td') | where width -eq "673"
$webPageLinks = $webPageHTML.ParsedHtml.getElementsByTagName('td') | where innerHTML -match '<a'

# Create folder for each title and download the respective files into said folder
for($i = 1; $i -lt $tableList.length; $i++){
    [System.Collections.ArrayList]$downloadList = @()

    # Create folder for each book title
    New-Item -Path $dest -Name $tableList[$i].innerText.replace(":","-") -ItemType Directory

    # Pull each link out of HTML source and add to download queue
    $explodedLinks = $webPageLinks[$i-1].innerHTML.Split('"')
    foreach($link in $explodedLinks){
        if($link.StartsWith('http://')){
            $downloadList.add($link)
        }
    }

    # Download each file associated with the current title
    foreach($download in $downloadList){
        $hdr = Invoke-WebRequest $download -Method Head 
        $title = $hdr.BaseResponse.ResponseUri.Segments[-1] 
        $title = [uri]::UnescapeDataString($title) 
        $saveTo = $dest + $tableList[$i].innerText.replace(":","-") + "\" + $title 
        Invoke-WebRequest $download -OutFile $saveTo 
    }
}
