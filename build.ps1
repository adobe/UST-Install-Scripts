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
