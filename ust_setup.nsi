
;--------------------------------
;Include Modern UI



Unicode True
!include "MUI2.nsh"
!include "custom_finish.nsh"
!define MUI_ICON "resources\images\adobe-logo.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "resources\images\dlgbmp-adobe-thin.bmp"
!define MUI_UI "resources\modern_custom.exe"


!define PATH_OUT "dist"
!system 'md "${PATH_OUT}"'
OutFile "${Path_Out}\AdobeUSTSetup-Beta.exe"

Name "Adobe User Sync Tool"
#Outfile "dist\AdobeUSTSetup-Beta.exe"
RequestExecutionLevel admin
InstallDir "$PROGRAMFILES64\Adobe\Adobe User Sync Tool"  


;--------------------------------
;'Pages

#!insertmacro MUI_PAGE_INSTFILES
;   !define MUI_FINISHPAGE_NOAUTOCLOSE
;   !define MUI_FINISHPAGE_RUN #"Utils\Certgen\AdobeIOCertgen.exe"
;   !define MUI_FINISHPAGE_RUN_FUNCTION "LaunchLink"
;   !define MUI_FINISHPAGE_RUN_CHECKED
;   !define MUI_FINISHPAGE_RUN_TEXT "Start a shortcut"
;  !insertmacro MUI_PAGE_FINISH
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "files\license.rtf"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
Page custom fnc_custom_z_Show fnc_custom_z_Leave


!insertmacro MUI_LANGUAGE "English"


;--------------------------------
;Installer Sections

Section "Install"

SetOutPath $INSTDIR
File /r "files\*"

FileOpen $0 "$INSTDIR\Run_UST_Test_Mode.bat" w
FileWrite $0 'mode 155,50$\r$\ncd /D "%~dp0"$\r$\nuser-sync.exe --process-groups --users mapped -t$\r$\npause'
FileClose $0

FileOpen $0 "$INSTDIR\Run_UST_Live_Mode.bat" w
FileWrite $0 'mode 155,50$\r$\ncd /D "%~dp0"$\r$\nuser-sync.exe --process-groups --users mapped'
FileClose $0

CreateShortCut "$INSTDIR\Configure UST.lnk" "$INSTDIR\Utils\Adobe.UST.Configuration.App.exe" \
"" "$INSTDIR\Utils\Adobe.UST.Configuration.App.exe" 1 SW_SHOWNORMAL \
ALT|CONTROL|SHIFT|F5 "Configure the User Sync Tool"

CreateShortCut "$INSTDIR\Edit YAML.lnk" "$INSTDIR\Utils\Notepad++\notepad++.exe" \
"*.yml" "resources\images\edit-yaml.ico" 2 SW_SHOWNORMAL \
ALT|CONTROL|SHIFT|F5 "Open configuration files in Notepad++"

CreateShortCut "$INSTDIR\Adobe.IO Certgen.lnk" "$INSTDIR\Utils\Certgen\AdobeIOCertgen.exe" \
"" "$INSTDIR\Utils\Certgen\AdobeIOCertgen.exe" 3 SW_SHOWNORMAL \
ALT|CONTROL|SHIFT|F5 "Create a new cert/keypair"

SectionEnd 