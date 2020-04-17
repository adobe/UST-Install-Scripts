!include MUI2.nsh   # change this to !include MUI.nsh to see how the code works successfully for MUI1
!include WinMessages.nsh
!include "LogicLib.nsh"

; Local bitmap path.
!define BITMAP_FILE "G:\Repositories\Resources\images\remix_wallpaper\out\red_door.bmp"

; --------------------------------------------------------------------------------------------------
; Installer Settings
; --------------------------------------------------------------------------------------------------
Name "Background Bitmap"
OutFile "bgbitmap.exe"
ShowInstDetails show

; --------------------------------------------------------------------------------------------------
; Modern UI Settings
; --------------------------------------------------------------------------------------------------
!define MUI_COMPONENTSPAGE_NODESC
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_CUSTOMFUNCTION_GUIINIT MyGUIInit

; --------------------------------------------------------------------------------------------------
; Definitions
; --------------------------------------------------------------------------------------------------
!ifndef LR_LOADFROMFILE
    !define LR_LOADFROMFILE     0x0010
!endif
!ifndef LR_CREATEDIBSECTION
    !define LR_CREATEDIBSECTION 0x2000
!endif
!ifndef IMAGE_BITMAP
    !define IMAGE_BITMAP        0
!endif
!ifndef SS_BITMAP
    !define SS_BITMAP           0x0000000E
!endif
!ifndef WS_CHILD
    !define WS_CHILD            0x40000000
!endif
!ifndef WS_VISIBLE
    !define WS_VISIBLE          0x10000000
!endif
!define HWND_TOP            0
!define SWP_NOSIZE          0x0001
!define SWP_NOMOVE          0x0002
!define IDC_BITMAP          1500
!define stRECT "(i, i, i, i) i"
Var hBitmap

; --------------------------------------------------------------------------------------------------
; Pages
; --------------------------------------------------------------------------------------------------
!define MUI_PAGE_CUSTOMFUNCTION_SHOW WelcomePageShow
!insertmacro MUI_PAGE_WELCOME

!insertmacro MUI_LANGUAGE English

; --------------------------------------------------------------------------------------------------
; Macros
; --------------------------------------------------------------------------------------------------
; Destroy a window.
!macro DestroyWindow HWND IDC
    GetDlgItem $R0 ${HWND} ${IDC}
    System::Call `user32::DestroyWindow(i R0)`
!macroend

; Give window transparent background.
!macro SetTransparent HWND IDC
    GetDlgItem $R0 ${HWND} ${IDC}
    SetCtlColors $R0 0x444444 transparent
!macroend

; Refresh window.
!macro RefreshWindow HWND IDC
    GetDlgItem $R0 ${HWND} ${IDC}
    ShowWindow $R0 ${SW_HIDE}
    ShowWindow $R0 ${SW_SHOW}
!macroend

; --------------------------------------------------------------------------------------------------
; Functions
; --------------------------------------------------------------------------------------------------
Function MyGUIInit

    ; Extract bitmap image.
    InitPluginsDir
    ReserveFile `${BITMAP_FILE}`
    File `/ONAME=$PLUGINSDIR\bg.bmp` `${BITMAP_FILE}`

    ; Get the size of the window.
    System::Call `*${stRECT} .R0`
    System::Call `user32::GetClientRect(i $HWNDPARENT, i R0)`
    System::Call `*$R0${stRECT} (, , .R1, .R2)`
    System::Free $R0

    ; Create bitmap control.
    System::Call `kernel32::GetModuleHandle(i 0) i.R3`
    System::Call `user32::CreateWindowEx(i 0, t "STATIC", t "", i ${SS_BITMAP}|${WS_CHILD}|${WS_VISIBLE}, i 0, i 0, i R1, i R2, i $HWNDPARENT, i ${IDC_BITMAP}, i R3, i 0) i.R1`
    System::Call `user32::SetWindowPos(i R1, i ${HWND_TOP}, i 0, i 0, i 0, i 0, i ${SWP_NOSIZE}|${SWP_NOMOVE})`

    ; Set the bitmap.
    System::Call `user32::LoadImage(i 0, t "$PLUGINSDIR\bg.bmp", i ${IMAGE_BITMAP}, i 0, i 0, i ${LR_CREATEDIBSECTION}|${LR_LOADFROMFILE}) i.s`
    Pop $hBitmap
    SendMessage $R1 ${STM_SETIMAGE} ${IMAGE_BITMAP} $hBitmap

    ; Set transparent backgrounds.
    !insertmacro SetTransparent $HWNDPARENT 3
    !insertmacro SetTransparent $HWNDPARENT 1
    !insertmacro SetTransparent $HWNDPARENT 2
    !insertmacro SetTransparent $HWNDPARENT 1034
    !insertmacro SetTransparent $HWNDPARENT 1037
    !insertmacro SetTransparent $HWNDPARENT 1038

    ; Remove unwanted controls.
    !insertmacro DestroyWindow  $HWNDPARENT 1256
    !insertmacro DestroyWindow  $HWNDPARENT 1028
    !insertmacro DestroyWindow  $HWNDPARENT 1039

FunctionEnd

Function RefreshParentControls

    !insertmacro RefreshWindow  $HWNDPARENT 1037
    !insertmacro RefreshWindow  $HWNDPARENT 1038

FunctionEnd

Var hCtl_custom_z_Bitmap1
Var hCtl_custom_z_Bitmap1_hImage

Function WelcomePageShow
        # Sets background image
    #System::Call `user32::LoadImage(i 0, t "$PLUGINSDIR\wb.bmp", i ${IMAGE_BITMAP}, i 0, i 0, i ${LR_CREATEDIBSECTION}|${LR_LOADFROMFILE}) i.s`
    #Pop $hBitmap
    #SendMessage $bitmapWindow ${STM_SETIMAGE} ${IMAGE_BITMAP} $hBitmap
    #${NSD_SetStretchedImage} $bitmapWindow ${STM_SETIMAGE} ${IMAGE_BITMAP} $hBitmap
    #${NSD_SetStretchedImage} $hCtl_custom_z_Bitmap1  ${IMAGE_BITMAP} $hCtl_custom_z_Bitmap1_hImage
    
      ; === Bitmap1 (type: Bitmap) ===
  ${NSD_CreateBitmap} 0u 0u 309u 193u ""
  Pop $hCtl_custom_z_Bitmap1
  SetCtlColors $hCtl_custom_z_Bitmap1 0x000000 0xFFFFFF
  File "/oname=$PLUGINSDIR\dlgbmp-adobe-thin.bmp" "G:\Repositories\Resources\images\remix_wallpaper\out\red_door.bmp"
  ${NSD_SetStretchedImage} $hCtl_custom_z_Bitmap1 "$PLUGINSDIR\dlgbmp-adobe-thin.bmp" $hCtl_custom_z_Bitmap1_hImage
    
        # Start solution
    SetCtlColors $mui.WelcomePage ${CTRL_COLOUR} transparent
    SetCtlColors $mui.WelcomePage.text 0xFFFFFF transparent
    SetCtlColors $mui.WelcomePage.title 0x333333 transparent

    !insertmacro DestroyWindow  $HWNDPARENT 1037
    !insertmacro DestroyWindow  $HWNDPARENT 1038
    !insertmacro DestroyWindow  $HWNDPARENT 1036 
    System::Call `user32::DestroyWindow(i $mui.WelcomePage.Image)`
    Call RefreshParentControls
FunctionEnd

; Free loaded resources.
Function .onGUIEnd

    ; Destroy the bitmap.
    System::Call `gdi32::DeleteObject(i s)` $hBitmap

FunctionEnd

; --------------------------------------------------------------------------------------------------
; Dummy section
; --------------------------------------------------------------------------------------------------
Section "Dummy Section"
SectionEnd


