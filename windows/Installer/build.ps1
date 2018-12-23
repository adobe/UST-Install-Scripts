

param(
    [String]$ustversion="latest",
    [switch]$fetch,
    [switch]$sign,
    [switch]$nopre
    )

# Strict mode -- provides better error messages and stops unwanted behavior
Set-StrictMode -Version 2.0 -Debug
$ErrorActionPreference = "Stop"
$fetch = $fetch.IsPresent
$sign = $sign.IsPresent
$nopre = $nopre.IsPresent


$tokenstring = if ($env:GITHUB_TOKEN) {"?access_token=$env:GITHUB_TOKEN"} {""}

# Check the input arguments for problems
if ($args) {Write-Host "Parameter '$args' not recognized"; exit }

# TLS 1.2 protocol enable - required to download from GitHub, does NOT work on Powershell < 3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$options = @{
    '7zPath' = 'conf\7zip\7z.exe'
    'ust_version' = $ustversion
    'log_level' = 'debug'
    'root' = 'files'
    'examples_fallback' = 'https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.0/example-configurations.tar.gz'
    'uri_cfg' = 'https://api.github.com/repos/adobe/ust-configapp/releases'
    'uri_ust' = 'https://api.github.com/repos/adobe-apiplatform/user-sync.py/releases'
    'python_urls' =  @{
        '3.6' = 'https://www.python.org/ftp/python/3.6.7/python-3.6.7-amd64.exe'    
        '2.7' = 'https://www.python.org/ftp/python/2.7.15/python-2.7.15.amd64.msi'    
    }
    'signing' = @{
        'signing_dir' = 'Signing'
        'unsigned_dir' = 'ToBeSigned'
        'finished_dir' = 'Finished'
    }    
}



$current_cfg = @{
    'USTVersion' = 'v2.3'
    'GUILink' = 'https://github.com/adobe/ust-configapp/releases/download/v1.0.3/Adobe.UST.Configuration.App.exe'
    'GUIVersion' = 'v1.0.3'
    'ExamplesLink' = 'https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.4rc2/examples.tar.gz'
    'NotepadLink' = 'https://notepad-plus-plus.org/repository/7.x/7.6.1/npp.7.6.1.bin.minimalist.7z'
    'VcRedistLink' = 'https://download.microsoft.com/download/9/1/4/914851c6-9141-443b-bdb4-8bad3a57bea9/vcredist_x64.exe'
    'Binaries' = @{
        '2.7' = @{'PythonLink' = $options['python_urls']['2.7']
                'USTLink' = 'https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/user-sync-v2.3-win64-py2715.tar.gz'}
        '3.6' = @{'PythonLink' = $options['python_urls']['3.6']
                'USTLink' = 'https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.3/user-sync-v2.3-win64-py365.tar.gz'}
    }			
}	

function Log($msg, $color){
    $color = if ($color) {$color} else {"white"} 
    Write-Host  "Logger ::: $msg" -ForegroundColor $color 
}

function ExpandArchive($Path, $Output){  

    $Path = [String] (Resolve-Path -Path $Path)
    $Output = [String] (Resolve-Path -Path $Output)       

    Log "Extracting $Path to $Output... "

    Start-Process -FilePath $options['7zPath'] -ArgumentList "x `"$Path`" -aoa -y -o`"$Output`"" -Wait -WindowStyle Hidden
    Remove-Item $Path -Force    

    if ($Path.EndsWith(".tar.gz")){
        $tarPath = $Output + "\" + $Path.split("\")[-1].TrimEnd(".gz")
        Start-Process -FilePath $options['7zPath'] -ArgumentList "x `"$tarPath`" -aoa -ttar -y -o`"$Output`"" -Wait -WindowStyle Hidden        
        Remove-Item $tarPath -Force
    }      
}  

function GetResource($fileURL, $outputFolder, $fileName){    
  
    $outputFolder = Resolve-Path -Path $outputFolder
    New-Item -Path $outputFolder -ItemType "Directory" -Force | Out-Null

    $filename = if ($filename) {$filename} else {$fileURL.split("/")[-1]}
    $filepath = "$outputFolder\$filename"    

    Log "Downloading $fileURL"
    (New-Object Net.Webclient).DownloadFile($fileURL, "$filepath")

    if (($fileURL.EndsWith("zip") -or $fileURL.EndsWith("tar.gz") -or $fileURL.EndsWith("7z"))) {         
        ExpandArchive $filepath $outputFolder
    }
}

function Fetch() { 

    if ($options['ust_version'] -ne "latest") {
        $ust_endpoint = $options['uri_ust'] + "/tags/v" + $options['ust_version']
    } else {
        $ust_endpoint = $options['uri_ust'] + "/latest"
    }

    $ust_data = Invoke-RestMethod -Uri ($ust_endpoint + $tokenstring)
    $cfg_data = Invoke-RestMethod -Uri ($options['uri_cfg'] + $tokenstring)
    $gui_link = $cfg_data[0].assets.browser_download_url       
    $releases = $ust_data.assets.browser_download_url -match ".*(win).*(.tar.gz)"                        
    $examples = ($ust_data.assets.browser_download_url -match ".*(example).*(.tar.gz)")[0]

    if (!$releases -or !$gui_link){
        throw [System.Web.HttpRequestValidationException] ("Failed to retrieve data from github api...")            
    }

    $config = @{
        'GUILink' = $gui_link
        'GUIVersion' = $cfg_data[0].tag_name            
        'USTVersion' = $ust_data.tag_name
        'ExamplesLink' = if ($examples) {$examples} Else {$options['examples_fallback']}
        'NotepadLink' = $current_cfg['NotepadLink']
        'VcRedistLink' = $current_cfg['VcRedistLink']
        'Binaries' = @{}
    }

    foreach ($url in $releases){
        $pyver = if ($url -match "(?<=-py).*(?=.tar.gz)") {$Matches[0].Substring(0, 1) + "." + $Matches[0].Substring(1, 1)} Else {"2.7"}      
        $config['Binaries'].Add($pyver, @{'USTLink' = $url;'PythonLink' = $options['python_urls'][$pyver]})  
    }

    return $config
}

function GetResources ($cfg) {
    GetResource $cfg.GUILink ($options['root'] + "\PreMapped\Utils")
    GetResource $cfg.NotepadLink ($options['root'] + "\PreMapped\Utils\Notepad++")
    GetResource $cfg.ExamplesLink ($options['root'] + "\PreMapped")
    GetResource $cfg.VcRedistLink ($options['root'] + "\Managed")

    foreach ($r in $cfg.Binaries.Keys){    
    $pyFileName = "Python" + $r.SubString(0,1)  + $cfg.Binaries[$r].PythonLink.Substring($cfg.Binaries[$r].PythonLink.LastIndexOf("."))
       GetResource $cfg.Binaries[$r].PythonLink ($options['root'] + "\Managed") $pyFileName
        GetResource $cfg.Binaries[$r].USTLink ($options['root'] + "\Managed")
        Move-Item ($options['root'] + "\Managed\user-sync.pex") ($options['root'] + "\Managed\user-sync-py"+$r.SubString(0,1)+".pex") -Force
    }
}

function CopyFiles(){

    $expath = ($options['root'] + "\PreMapped\examples\config files - basic")
    $outpath = ($options['root'] + "\PreMapped")
    $ymllist = @('user-sync-config.yml', 'connector-ldap.yml', 'connector-umapi.yml')

    foreach ($file in Get-ChildItem $expath) {            
        foreach ($yml in $ymllist){
            if ($file -match (".*($yml)")) {
                Log "Copying $file to $outpath\$yml... "
                Copy-Item "$expath\$file" "$outpath\$yml"  -Force
            }
        }    
    }

    "python user-sync.pex --process-groups --users mapped -t`r`npause" | Out-File ($options['root'] + "\PreMapped\Run_UST_Test_Mode.bat") -Force -Encoding ascii
    "python user-sync.pex --process-groups --users mapped" | Out-File ($options['root'] + "\PreMapped\Run_UST_Live.bat") -Force -Encoding ascii

}


function CreateFolders(){
    Log "Creating folders... "
    $dirlist = @(
        'Managed',
        'PreMapped',
        'PreMapped\Utils',
        'PreMapped\Utils\Notepad++',
        'PreMapped\Utils\Certgen')

    New-Item -ItemType directory -Path $options['root'] -Force | Out-Null
    foreach ($d in $dirlist){ New-Item -ItemType directory -Path ($options['root'] + "\$d") -Force  | Out-Null }


}


function SetSignLocation($root){

    $root = Resolve-Path $root

    $signing = ("$root\" + $options['signing']['signing_dir'])
    $fileinput =  ("$signing\" + $options['signing']['unsigned_dir'])
    $fileoutput = ("$signing\" + $options['signing']['finished_dir'])

    Remove-Item $signing -Force -Recurse -ErrorAction SilentlyContinue

    New-Item -ItemType directory -Path "$signing" -Force | Out-Null    
    New-Item -ItemType directory -Path "$fileinput" -Force | Out-Null
    New-Item -ItemType directory -Path "$fileoutput" -Force | Out-Null

    return $signing

}


function PreBuild(){

    Log "Beginning prebuild..... " "green"

    CreateFolders
    $cfg = if ($fetch) {Fetch} else {$current_cfg}
    GetResources ($cfg)
    CopyFiles

    Log "PreBuild tasks complete..... " "green"

}

function BuildCertGui {

	$cpath = $PWD    

    Set-Location ..\CertGui

	MSBuild.exe .\certgen.sln /p:Configuration=Release /p:Platform="x64" -t:Clean
    MSBuild.exe .\certgen.sln /p:Configuration=Release /p:Platform="x64" -t:Build    

    $signfolder = SetSignLocation "bin"
    $signed = ("$signfolder\" + $options['signing']['finished_dir'])
    $unsigned = ("$signfolder\" + $options['signing']['unsigned_dir'])

    Copy-Item "bin\x64\Release\adobeio-certgen.exe" $unsigned
    Copy-Item "bin\x64\Release\adobeio-certgen.exe.config" $unsigned

    if ($sign) {
        Sign $unsigned "42151"        
     } else {
        Move-Item "$unsigned\*" $signed
     } 

    Copy-Item "$signed\*" "..\Installer\files\PreMapped\Utils\Certgen"

    Set-Location $cpath

}

function BuildMSI(){

    Log "Starting build process..... " "green"

    $signfolder = SetSignLocation "bin"
    $signed = ("$signfolder\" + $options['signing']['finished_dir'])
    $unsigned = ("$signfolder\" + $options['signing']['unsigned_dir'])

    MSBuild.exe .\ust-wix.sln /p:Configuration=Release /p:Platform="x64" -t:Clean
    MSBuild.exe .\ust-wix.sln /p:Configuration=Release /p:Platform="x64" -t:Build
  
    Log "BuildMSI finished: output in bin/en-us/AdobeUSTSetup.msi" "green"

    Copy-Item "bin\en-us\AdobeUSTSetup.msi" $unsigned

    if ($sign) {
        Sign $unsigned "42117"
    } else {
        Move-Item "$unsigned\*" $signed
    } 
}

function Sign($path, $rule){
    $path = Resolve-Path $path
    Log "Begin signing process for $path..... " "green"
    powershell.exe -File C:\signing\sign.ps1 -buildpath $path -ruleid $rule
    Log "Signing complete..... " "green"
}

function Run(){

    Log "Begin build process..... " "green"
  #  if (!$nopre) {PreBuild}
    
	BuildCertGui
    BuildMSI    

    Log "BuildMSI finished.... " "green"

}

Run
