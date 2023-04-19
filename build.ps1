function Get-TempDir {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    return (Join-Path $parent "ust-installer" $name)
}

function Get-Asset {
    param ($base_url, $filename, $tmpdir, $dest_dir)
    $dl_file = Join-Path $tmpdir $filename
    Invoke-WebRequest -Uri "${base_url}/${filename}" -OutFile $dl_file
    Expand-Archive -LiteralPath $dl_file -DestinationPath $dest_dir -Force
}

# set up temp directory
$tmpdir = Get-TempDir
New-Item -ItemType Directory -Path $tmpdir

# download and extract UST zip and examples
$ust_version = (Get-Content version.txt).trim()
$ust_url = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v${ust_version}"
$ust_filename = "user-sync-v${ust_version}-win64.zip"
Get-Asset $ust_url $ust_filename $tmpdir ".\files\"
md ".\files\examples" -Force
Get-Asset $ust_url "user-sync-examples.zip" $tmpdir ".\files\examples\"

$npp_url = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.3.3"
$npp_filename = "npp.8.3.3.portable.x64.zip"
$npp_dir = ".\files\Utils\Notepad++\"
md $npp_dir -Force
Get-Asset $npp_url $npp_filename $tmpdir $npp_dir

$cfg_app_url = "https://github.com/adobe-dmeservices/ust-configapp-v2/releases/download/v2.0.1/Adobe.UST.Configuration.App.exe"
$cfg_app_file = "Adobe.UST.Configuration.App.exe"
Invoke-WebRequest -Uri $cfg_app_url -OutFile (Join-Path ".\files\Utils\" $cfg_app_file)
