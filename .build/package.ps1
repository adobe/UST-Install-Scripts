
mkdir release -Force
$zip_filename = "user-sync-${env:VERSION}-${env:BUILD_EDITION}-win64"

If ("${env:SIGNED_RELEASE}" -ne 'true') {
    Copy-Item dist\user-sync.exe release\
    $zip_filename += "-unsigned"
}
Else {
    Copy-Item signed\user-sync.exe release\
}

Set-Location release
7z.exe a "${zip_filename}.zip" user-sync.exe
Set-Location ..
7z.exe a -ttar -r release\examples.tar examples
7z.exe a -tgzip release\examples.tar.gz release\examples.tar
7z.exe a -r release\examples.zip examples\
Remove-Item .\release\user-sync.exe
Remove-Item .\release\examples.tar
Get-ChildItem release
