
;--------------------------------
;Include Modern UI

RequestExecutionLevel admin
Unicode True

!define splash "resources\images\logo_6.bmp"
!define /file VERSION "version.txt"
!define PATH_OUT "bin"
!system 'md "${PATH_OUT}"'

!include "MUI2.nsh"
!include "custom_finish.nsh"

Name "Adobe User Sync Tool ${VERSION}"
OutFile "${Path_Out}\AdobeUSTSetup.exe"
InstallDir "$PROGRAMFILES64\Adobe\Adobe User Sync Tool"  
BrandingText "User Sync ${VERSION}"


!define MUI_ICON "resources\images\adobe-logo.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP ${splash}
!define MUI_UI "resources\modern_custom.exe"

;--------------------------------
;'Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE LICENSE
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
Page custom fnc_custom_z_Show fnc_custom_z_Leave

;--------------------------------
;Installer Sections

Section "Install"

    SetOutPath $INSTDIR
    File /r "files\*"

    FileOpen $0 "$INSTDIR\Run_UST_Test_Mode.bat" w
    FileWrite $0 'mode 155,50$\r$\ncd /D "%~dp0"$\r$\nuser-sync.exe -t$\r$\npause'
    FileClose $0

    FileOpen $0 "$INSTDIR\Run_UST_Live_Mode.bat" w
    FileWrite $0 'mode 155,50$\r$\ncd /D "%~dp0"$\r$\nuser-sync.exe'
    FileClose $0

    CopyFiles "$INSTDIR\examples\config files - basic\connector-ldap.yml" "$INSTDIR"
    CopyFiles "$INSTDIR\examples\config files - basic\connector-umapi.yml" "$INSTDIR"
    CopyFiles "$INSTDIR\examples\config files - basic\user-sync-config.yml" "$INSTDIR"

    CreateShortCut "$INSTDIR\Configure UST.lnk" "$INSTDIR\Utils\Adobe.UST.Configuration.App.exe" \
    "" "$INSTDIR\Utils\configapp-logo.ico" 0 SW_SHOWNORMAL \
    ALT|CONTROL|SHIFT|F5 "Configure the User Sync Tool"

    CreateShortCut "$INSTDIR\Edit YAML.lnk" "$INSTDIR\Utils\Notepad++\notepad++.exe" \
    "*.yml" "$INSTDIR\Utils\edit-yaml.ico" 0 SW_SHOWNORMAL \
    ALT|CONTROL|SHIFT|F5 "Open configuration files in Notepad++"

    CreateShortCut "$INSTDIR\Adobe.IO Certgen.lnk" "$INSTDIR\Utils\Certgen\AdobeIOCertgen.exe" \
    "" "$INSTDIR\Utils\Certgen\AdobeIOCertgen.exe" 0 SW_SHOWNORMAL \
    ALT|CONTROL|SHIFT|F5 "Create a new cert/keypair"

    AccessControl::GrantOnFile \
        "$INSTDIR\" "(S-1-1-0)" "GenericRead + GenericWrite + GenericExecute + Delete"
    Pop $0

SectionEnd 
!insertmacro MUI_LANGUAGE "English"