function Get-TempDir {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    return (Join-Path $parent "ust-installer" $name)
}

# set up temp directory
$version = (Get-Content version.txt).trim()
$ust_filename = "user-sync-v${version}-win64.zip"
$tmpdir = Get-TempDir
New-Item -ItemType Directory -Path $tmpdir

# download UST zip
$ust_dl_dest = Join-Path $tmpdir $ust_filename
$ust_url = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v${version}/${ust_filename}"
Invoke-WebRequest -Uri $ust_url -OutFile $ust_dl_dest

# extract UST zip
Expand-Archive -LiteralPath $ust_dl_dest -DestinationPath .\files\ -Force

Write-Output $ust_url
Write-Output $tmpdir
Write-Output $ust_dl_dest
