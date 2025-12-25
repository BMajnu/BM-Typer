; BM Typer NSIS Installer Script
; Version: 1.0.0
; Created: 2025-12-25

;--------------------------------
; Includes
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"

;--------------------------------
; General Settings
!define PRODUCT_NAME "BM Typer"
!define PRODUCT_VERSION "1.0.0"
!define PRODUCT_PUBLISHER "TechZone IT"
!define PRODUCT_WEB_SITE "https://techzoneit.com"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\bm_typer.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; Installer attributes
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "BMTyper_Setup_NSIS_v${PRODUCT_VERSION}.exe"
InstallDir "$LOCALAPPDATA\Programs\${PRODUCT_NAME}"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show
RequestExecutionLevel admin

; Compression
SetCompressor /SOLID lzma

;--------------------------------
; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "..\windows\runner\resources\app_icon.ico"
!define MUI_UNICON "..\windows\runner\resources\app_icon.ico"

; Welcome page
!insertmacro MUI_PAGE_WELCOME

; License page (Bengali EULA)
!insertmacro MUI_PAGE_LICENSE "docs\EULA-bn.txt"

; Info page (Bengali README)
!define MUI_PAGE_HEADER_TEXT "গুরুত্বপূর্ণ তথ্য"
!define MUI_PAGE_HEADER_SUBTEXT "ইনস্টল করার আগে এই তথ্যগুলো পড়ুন"
!insertmacro MUI_PAGE_LICENSE "docs\README-bn.txt"

; Directory page
!insertmacro MUI_PAGE_DIRECTORY

; Instfiles page
!insertmacro MUI_PAGE_INSTFILES

; Finish page
!define MUI_FINISHPAGE_RUN "$INSTDIR\bm_typer.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${PRODUCT_NAME}"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Sections

Section "MainSection" SEC01
    SetOutPath "$INSTDIR"
    SetOverwrite on
    
    ; Install all application files from Release folder
    File /r "..\build\windows\x64\runner\Release\*.*"
    
    ; Install icon
    File "..\windows\runner\resources\app_icon.ico"
    
    ; Install docs folder
    SetOutPath "$INSTDIR\docs"
    File /r "docs\*.*"
    SetOutPath "$INSTDIR"
    
    ; Create shortcuts
    CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
    CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk" "$INSTDIR\bm_typer.exe" "" "$INSTDIR\app_icon.ico"
    CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall ${PRODUCT_NAME}.lnk" "$INSTDIR\uninst.exe"
    CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\bm_typer.exe" "" "$INSTDIR\app_icon.ico"
    
    ; Write registry keys for uninstaller
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\app_icon.ico"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
    
    ; Get installed size
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "EstimatedSize" "$0"
SectionEnd

Section "VC++ Redistributable" SEC02
    ; Check if VC++ Redistributable is already installed
    ReadRegStr $0 HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" "Installed"
    StrCmp $0 "1" vcredist_installed
    
    ; Install VC++ Redistributable
    SetOutPath "$TEMP"
    File "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Redist\MSVC\14.44.35112\vc_redist.x64.exe"
    DetailPrint "Installing Visual C++ Redistributable..."
    ExecWait '"$TEMP\vc_redist.x64.exe" /install /quiet /norestart' $0
    Delete "$TEMP\vc_redist.x64.exe"
    
    vcredist_installed:
SectionEnd

Section "WebView2 Runtime" SEC03
    ; Check if WebView2 is already installed
    ReadRegStr $0 HKLM "SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
    StrCmp $0 "" 0 webview2_installed
    
    ReadRegStr $0 HKCU "Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
    StrCmp $0 "" 0 webview2_installed
    
    ; Install WebView2 Runtime
    SetOutPath "$TEMP"
    File "MicrosoftEdgeWebview2Setup.exe"
    DetailPrint "Installing Microsoft Edge WebView2 Runtime..."
    ExecWait '"$TEMP\MicrosoftEdgeWebview2Setup.exe" /silent /install' $0
    Delete "$TEMP\MicrosoftEdgeWebview2Setup.exe"
    
    webview2_installed:
SectionEnd

Section -Post
    WriteUninstaller "$INSTDIR\uninst.exe"
    WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\bm_typer.exe"
SectionEnd

;--------------------------------
; Uninstaller Section

Section Uninstall
    ; Remove shortcuts
    Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
    RMDir /r "$SMPROGRAMS\${PRODUCT_NAME}"
    
    ; Remove files and directories
    RMDir /r "$INSTDIR"
    
    ; Remove registry keys
    DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
    DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
    
    SetAutoClose true
SectionEnd

;--------------------------------
; Installer Functions

Function .onInit
    ; Check for 64-bit OS
    ${If} ${RunningX64}
        SetRegView 64
    ${Else}
        MessageBox MB_OK|MB_ICONSTOP "This application requires a 64-bit version of Windows."
        Abort
    ${EndIf}
FunctionEnd

Function un.onInit
    MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove ${PRODUCT_NAME} and all of its components?" IDYES +2
    Abort
FunctionEnd

Function un.onUninstSuccess
    HideWindow
    MessageBox MB_ICONINFORMATION|MB_OK "${PRODUCT_NAME} was successfully removed from your computer."
FunctionEnd
