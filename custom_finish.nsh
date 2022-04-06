; =========================================================
; This file was generated by NSISDialogDesigner 1.5.0.0
; https://coolsoft.altervista.org/nsisdialogdesigner
;
; Do not edit it manually, use NSISDialogDesigner instead!
; =========================================================

; GetDlgItem $0 $HWNDPARENT 3 ; Back Button
; GetDlgItem $1 $HWNDPARENT 1 ; Next/Close Button
; GetDlgItem $2 $HWNDPARENT 2 ; Cancel Button

!include "MUI2.nsh"
!include LogicLib.nsh

; handle variables
; handle variables
Var hCtl_custom_z
Var hCtl_custom_z_Label2
Var hCtl_custom_z_Label1
Var hCtl_custom_z_WizardChk
Var hCtl_custom_z_FolderChk
Var hCtl_custom_z_Bitmap1
Var hCtl_custom_z_Bitmap1_hImage
Var hCtl_custom_z_Font1


; dialog create function
Function fnc_custom_z_Create
  
  ; custom font definitions
  CreateFont $hCtl_custom_z_Font1 "Microsoft Sans Serif" "13.8" "700"
  
  ; === custom_z (type: Dialog) ===
  nsDialogs::Create 1044
  Pop $hCtl_custom_z
  ${If} $hCtl_custom_z == error
    Abort
  ${EndIf}
  SetCtlColors $hCtl_custom_z 0x000000 0xFFFFFF
  !insertmacro MUI_HEADER_TEXT "Dialog title..." "Dialog subtitle..."
  
  ; === Label2 (type: Label) ===
  ${NSD_CreateLabel} 125u 16u 159u 29u "Completing the Adobe User Sync Tool Setup"
  Pop $hCtl_custom_z_Label2
  SendMessage $hCtl_custom_z_Label2 ${WM_SETFONT} $hCtl_custom_z_Font1 0
  SetCtlColors $hCtl_custom_z_Label2 0x000000 0xFFFFFF
  
  ; === Label1 (type: Label) ===
  ${NSD_CreateLabel} 125u 53u 159u 25u "The Adobe User Sync Tool has been installed on your computer.$\r$\n$\r$\nClick Finish to close Setup."
  Pop $hCtl_custom_z_Label1
  SetCtlColors $hCtl_custom_z_Label1 0x000000 0xFFFFFF
  
  ; === WizardChk (type: Checkbox) ===
  ${NSD_CreateCheckbox} 125u 98u 194u 13u "Start the UST Configuration Wizard"
  Pop $hCtl_custom_z_WizardChk
  SetCtlColors $hCtl_custom_z_WizardChk 0x000000 0xFFFFFF
  
  ; === FolderChk (type: Checkbox) ===
  ${NSD_CreateCheckbox} 125u 84u 194u 13u "Open User-Sync folder"
  Pop $hCtl_custom_z_FolderChk
  SetCtlColors $hCtl_custom_z_FolderChk 0x000000 0xFFFFFF
  
  ; === Bitmap1 (type: Bitmap) ===
  ${NSD_CreateBitmap} 0u 0u 109u 193u ""
  Pop $hCtl_custom_z_Bitmap1
  SetCtlColors $hCtl_custom_z_Bitmap1 0x000000 0xFFFFFF
  File "/oname=$PLUGINSDIR\splash.bmp" ${splash}
  ${NSD_SetStretchedImage} $hCtl_custom_z_Bitmap1 "$PLUGINSDIR\splash.bmp" $hCtl_custom_z_Bitmap1_hImage
  
  ${NSD_SetState} $hCtl_custom_z_FolderChk 1

;  Set text on Next button
  GetDlgItem $R0 $HWNDPARENT 1
  SendMessage $R0 ${WM_SETTEXT} 0 `STR:Finish`

  GetDlgItem $R0 $HWNDPARENT 3
  ShowWindow $R0 ${SW_HIDE}

  GetDlgItem $1 $HWNDPARENT 2 
  EnableWindow $1 2 

FunctionEnd



Function fnc_custom_z_Show
  Call fnc_custom_z_Create
  GetDlgItem $0 $HWNDPARENT 1028
  GetDlgItem $1 $HWNDPARENT 1256

# Hide branding
  ShowWindow $0 ${SW_HIDE}
  ShowWindow $1 ${SW_HIDE}

  nsDialogs::Show  
FunctionEnd

Function run_folder
	${NSD_GetState} $hCtl_custom_z_FolderChk $1
	${If} $1 == 1
		ExecShell "open" ""
	${EndIf}
FunctionEnd

Function run_wiz
	${NSD_GetState} $hCtl_custom_z_WizardChk $1
	${If} $1 == 1
		ExecShell "" "Utils\Adobe.UST.Configuration.App.exe"
	${EndIf}
FunctionEnd

Function fnc_custom_z_Leave
  Call run_folder
  Call run_wiz


Quit
FunctionEnd
