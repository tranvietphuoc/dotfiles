@echo off
chcp 65001 >nul 2>&1
title Kiem tra Ban quyen Windows va Office
color 0e
setlocal enabledelayedexpansion

:: ---------------------------------------------------------
:: 1. KIEM TRA QUYEN ADMIN
:: ---------------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Can quyen Administrator de chay script.
    echo Dang tu dong kich hoat quyen Admin...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/k ""%~f0""", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /b
)

:: ---------------------------------------------------------
:: SETUP LOG FILE
:: ---------------------------------------------------------
set "LOG_FILE=%~dp0check_license_log_%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%.txt"
set "LOG_FILE=%LOG_FILE: =0%"

cls
echo ==========================================================
echo    KIEM TRA BAN QUYEN WINDOWS VA OFFICE
echo    Ngay: %date% - %time%
echo ==========================================================
echo.

set "CRACK_COUNT=0"
set "GENUINE_COUNT=0"
set "UNKNOWN_COUNT=0"
set "CRACK_DETAILS="

:: Verdict cho popup
set "WIN_VERDICT=UNKNOWN"
set "WIN_DETAIL=Khong xac dinh"
set "OFF_VERDICT=NOT_FOUND"
set "OFF_DETAIL=Khong tim thay Office tren may"

:: ==========================================================
:: PHAN A: KIEM TRA WINDOWS
:: ==========================================================
echo [A] WINDOWS LICENSE
echo ----------------------------------------------------------

set "WIN_TMP=%temp%\win_lic_dli.tmp"
set "WIN_DLV=%temp%\win_lic_dlv.tmp"
set "WIN_XPR=%temp%\win_lic_xpr.tmp"

:: --- A1: Lay thong tin co ban (slmgr /dli) ---
cscript //nologo %windir%\system32\slmgr.vbs /dli > "%WIN_TMP%" 2>&1

findstr /i /c:"License Status" "%WIN_TMP%" >nul 2>&1
if %errorlevel% neq 0 (
    echo   [LOI] Khong the doc thong tin Windows License.
    set "WIN_VERDICT=UNKNOWN"
    set "WIN_DETAIL=Khong the doc thong tin license"
    echo.
    goto :win_done
)

echo.
echo   --- Thong tin co ban ---
findstr /i /c:"Name:" /c:"Description:" /c:"License Status:" /c:"Partial Product Key:" "%WIN_TMP%"
echo   ------------------------
echo.

:: --- A2: Kiem tra kich hoat ---
findstr /i /c:"License Status: Licensed" "%WIN_TMP%" >nul 2>&1
if %errorlevel% neq 0 (
    echo   [X] Windows CHUA KICH HOAT hoac da het han.
    set /a UNKNOWN_COUNT+=1
    set "WIN_VERDICT=NOT_ACTIVATED"
    set "WIN_DETAIL=Chua kich hoat hoac da het han"
    echo.
    goto :win_done
)

:: --- A3: Kiem tra vinh vien hay tam thoi (slmgr /xpr) ---
echo   --- Kiem tra tinh trang kich hoat ---
cscript //nologo %windir%\system32\slmgr.vbs /xpr > "%WIN_XPR%" 2>&1

findstr /i /c:"permanently activated" "%WIN_XPR%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [V] Windows duoc KICH HOAT VINH VIEN.
    set "WIN_PERMANENT=1"
) else (
    echo   [!] Windows co NGAY HET HAN - dau hieu KMS/crack.
    findstr /i /c:"expir" /c:"Volume" "%WIN_XPR%"
    set "WIN_PERMANENT=0"
)
echo.

:: --- A4: Lay chi tiet (slmgr /dlv) ---
cscript //nologo %windir%\system32\slmgr.vbs /dlv > "%WIN_DLV%" 2>&1

:: --- A5: Xac dinh kenh kich hoat ---
echo   --- Danh gia kenh kich hoat ---

:: Check GVLK (Generic Volume License Key) - dau hieu KMS
findstr /i "GVLK" "%WIN_DLV%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [!!!] Phat hien GVLK [Generic Volume License Key].
    echo        Tren may ca nhan, day la dau hieu su dung KMS crack.
    set /a CRACK_COUNT+=1
    set "CRACK_DETAILS=!CRACK_DETAILS! Windows:GVLK"
    set "WIN_VERDICT=CRACK"
    set "WIN_DETAIL=GVLK - key KMS crack"
    echo.
    goto :win_kms_detail
)

:: Check VOLUME_KMSCLIENT
findstr /i "VOLUME_KMSCLIENT" "%WIN_TMP%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [!] Kenh kich hoat: VOLUME_KMSCLIENT [KMS Client].
    goto :win_kms_detail
)

:: Check RETAIL
findstr /i /c:"RETAIL channel" "%WIN_TMP%" >nul 2>&1
if !errorlevel! equ 0 (
    if "!WIN_PERMANENT!"=="1" (
        echo   [V] Ban quyen RETAIL [chinh hang] - VINH VIEN.
        set /a GENUINE_COUNT+=1
        set "WIN_VERDICT=GENUINE"
        set "WIN_DETAIL=RETAIL chinh hang - kich hoat vinh vien"
    ) else (
        echo   [?] Kenh RETAIL nhung khong vinh vien - bat thuong.
        set /a UNKNOWN_COUNT+=1
        set "WIN_VERDICT=UNKNOWN"
        set "WIN_DETAIL=RETAIL nhung khong vinh vien - bat thuong"
    )
    echo.
    goto :win_done
)

:: Check OEM
findstr /i "OEM" "%WIN_TMP%" >nul 2>&1
if !errorlevel! equ 0 (
    if "!WIN_PERMANENT!"=="1" (
        echo   [V] Ban quyen OEM [tich hop san may] - VINH VIEN.
        set /a GENUINE_COUNT+=1
        set "WIN_VERDICT=GENUINE"
        set "WIN_DETAIL=OEM tich hop san may - vinh vien"
    ) else (
        echo   [?] Kenh OEM nhung khong vinh vien - bat thuong.
        set /a UNKNOWN_COUNT+=1
        set "WIN_VERDICT=UNKNOWN"
        set "WIN_DETAIL=OEM nhung khong vinh vien - bat thuong"
    )
    echo.
    goto :win_done
)

:: Check MAK
findstr /i "VOLUME_MAK" "%WIN_TMP%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [~] Ban quyen MAK [key doanh nghiep].
    set /a GENUINE_COUNT+=1
    set "WIN_VERDICT=GENUINE"
    set "WIN_DETAIL=MAK - key doanh nghiep"
    echo.
    goto :win_done
)

echo   [?] Da kich hoat nhung khong xac dinh kenh.
set /a UNKNOWN_COUNT+=1
set "WIN_VERDICT=UNKNOWN"
set "WIN_DETAIL=Da kich hoat nhung khong xac dinh kenh"
echo.
goto :win_done

:: --- A6: Phan tich chi tiet KMS ---
:win_kms_detail
echo   --- Phan tich KMS server ---

:: Doc KMS machine name tu /dlv
set "KMS_HOST="
for /f "tokens=2 delims=:" %%a in ('findstr /i /c:"KMS machine name" "%WIN_DLV%" 2^>nul') do (
    set "KMS_HOST=%%a"
    set "KMS_HOST=!KMS_HOST: =!"
)

if defined KMS_HOST (
    echo   KMS Server: !KMS_HOST!
) else (
    echo   KMS Server: [khong tim thay]
)

:: Check localhost / loopback
findstr /i /c:"127.0.0.1" /c:"0.0.0.0" /c:"localhost" "%WIN_DLV%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [!!!] KMS GIA LAP [localhost/loopback] - DAY LA CRACK!
    set /a CRACK_COUNT+=1
    set "CRACK_DETAILS=!CRACK_DETAILS! Windows:KMS-localhost"
    set "WIN_VERDICT=CRACK"
    set "WIN_DETAIL=KMS gia lap localhost - CRACK"
    echo.
    goto :win_done
)

:: Check private IP ranges (RFC 1918)
:: 192.168.x.x
findstr /i /c:"192.168." "%WIN_DLV%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [!] KMS server dung IP noi bo [192.168.x.x].
    echo       Neu day la may CA NHAN - co kha nang la CRACK.
    echo       Neu trong mang DOANH NGHIEP - co the hop le.
    set /a UNKNOWN_COUNT+=1
    set "WIN_VERDICT=UNKNOWN"
    set "WIN_DETAIL=KMS server IP noi bo - nghi ngo"
    echo.
    goto :win_done
)

:: 10.x.x.x
findstr /i /c:"10." "%WIN_DLV%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [!] KMS server dung IP noi bo [10.x.x.x].
    echo       Neu day la may CA NHAN - co kha nang la CRACK.
    echo       Neu trong mang DOANH NGHIEP - co the hop le.
    set /a UNKNOWN_COUNT+=1
    set "WIN_VERDICT=UNKNOWN"
    set "WIN_DETAIL=KMS server IP noi bo - nghi ngo"
    echo.
    goto :win_done
)

:: 172.16.x.x - 172.31.x.x
findstr /i /c:"172.16." /c:"172.17." /c:"172.18." /c:"172.19." /c:"172.20." /c:"172.21." /c:"172.22." /c:"172.23." /c:"172.24." /c:"172.25." /c:"172.26." /c:"172.27." /c:"172.28." /c:"172.29." /c:"172.30." /c:"172.31." "%WIN_DLV%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [!] KMS server dung IP noi bo [172.16-31.x.x].
    echo       Neu day la may CA NHAN - co kha nang la CRACK.
    echo       Neu trong mang DOANH NGHIEP - co the hop le.
    set /a UNKNOWN_COUNT+=1
    set "WIN_VERDICT=UNKNOWN"
    set "WIN_DETAIL=KMS server IP noi bo - nghi ngo"
    echo.
    goto :win_done
)

:: Khong xac dinh duoc KMS server
if "!WIN_PERMANENT!"=="0" (
    echo   [!] KMS activation khong vinh vien, server khong ro.
    echo       CO THE LA CRACK [KMS emulator].
    set /a UNKNOWN_COUNT+=1
    set "WIN_VERDICT=CRACK"
    set "WIN_DETAIL=KMS khong vinh vien - nghi crack"
) else (
    echo   [?] KMS nhung kich hoat vinh vien - can xem xet them.
    set /a UNKNOWN_COUNT+=1
    set "WIN_VERDICT=UNKNOWN"
    set "WIN_DETAIL=KMS vinh vien - can xem xet them"
)
echo.

:win_done
:: Don dep file tam Windows
del "%WIN_TMP%" 2>nul
del "%WIN_DLV%" 2>nul
del "%WIN_XPR%" 2>nul

:: ==========================================================
:: PHAN B: KIEM TRA OFFICE
:: ==========================================================
echo [B] OFFICE LICENSE
echo ----------------------------------------------------------

set "target="

:: Tim kiem de quy file ospp.vbs trong toan bo thu muc Microsoft Office de chac chan 100%
for %%D in ("%ProgramFiles%\Microsoft Office" "%ProgramFiles(x86)%\Microsoft Office") do (
    if exist "%%~D" (
        for /f "tokens=*" %%F in ('dir /b /s "%%~D\ospp.vbs" 2^>nul') do (
            set "target=%%~dpF"
            :: Xoa ky tu \ o cuoi duong dan
            set "target=!target:~0,-1!"
            goto :found_ospp
        )
    )
)
:found_ospp

if not defined target (
    echo   [THONG BAO] Khong tim thay Office tren may nay.
    echo.
    goto :crack_tools_section
)

echo   Da tim thay: %target%
echo.

set "OFF_TMP=%temp%\office_lic.tmp"
cscript //nologo "%target%\ospp.vbs" /dstatus > "%OFF_TMP%" 2>&1

findstr /i /c:"LICENSE NAME" "%OFF_TMP%" >nul 2>&1
if %errorlevel% neq 0 (
    echo   [LOI] Khong doc duoc du lieu license Office.
    set "OFF_VERDICT=UNKNOWN"
    set "OFF_DETAIL=Khong doc duoc du lieu license"
    echo.
    goto :office_done
)

echo   --- Thong tin license ---
findstr /i /c:"LICENSE NAME" /c:"LICENSE STATUS" /c:"LICENSE DESCRIPTION" /c:"REMAINING GRACE" /c:"ERROR CODE" /c:"Last 5" "%OFF_TMP%"
echo   -------------------------
echo.

echo   --- Danh gia ---

:: -------------------------------------------------------
:: BUOC 1: Kiem tra trang thai kich hoat
:: -------------------------------------------------------

:: Check Grace / OOB_GRACE / NOTIFICATIONS (chua kich hoat / het han)
findstr /i /c:"OOB_GRACE" /c:"NOTIFICATIONS" /c:"OOT_GRACE" "%OFF_TMP%" >nul 2>&1
if !errorlevel! equ 0 (
    findstr /i /c:"---LICENSED---" "%OFF_TMP%" >nul 2>&1
    if !errorlevel! neq 0 (
        echo   [X] Office dang o trang thai GRACE / NOTIFICATIONS.
        echo       Chua kich hoat hoac ban dung thu het han.
        set /a CRACK_COUNT+=1
        set "CRACK_DETAILS=!CRACK_DETAILS! Office:Unlicensed-Grace"
        set "OFF_VERDICT=CRACK"
        set "OFF_DETAIL=Chua kich hoat - trang thai Grace/het han"
        echo.
        goto :office_done
    )
)

:: Check da kich hoat chua
findstr /i /c:"---LICENSED---" "%OFF_TMP%" >nul 2>&1
if %errorlevel% neq 0 (
    echo   [X] Office CHUA DUOC KICH HOAT.
    set /a CRACK_COUNT+=1
    set "CRACK_DETAILS=!CRACK_DETAILS! Office:NotActivated"
    set "OFF_VERDICT=CRACK"
    set "OFF_DETAIL=Chua duoc kich hoat"
    echo.
    goto :office_done
)

:: -------------------------------------------------------
:: BUOC 2: Da kich hoat - Phat hien CRACK ro rang
:: -------------------------------------------------------

:: Check GVLK (Generic Volume License Key) - dau hieu KMS crack
findstr /i "GVLK" "%OFF_TMP%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [!!!] Phat hien GVLK key cho Office.
    echo        Day la key KMS gia lap - KHONG CHINH HANG.
    set /a CRACK_COUNT+=1
    set "CRACK_DETAILS=!CRACK_DETAILS! Office:GVLK"
    set "OFF_VERDICT=CRACK"
    set "OFF_DETAIL=GVLK - key KMS gia lap"
    echo.
    goto :office_done
)

:: Check VOLUME_KMSCLIENT
findstr /i "VOLUME_KMSCLIENT" "%OFF_TMP%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [!!!] Office dang dung kenh VOLUME_KMSCLIENT.

    :: Check KMS host trong output
    set "OFF_KMS_HOST="
    for /f "tokens=2 delims=:" %%a in ('findstr /i /c:"KMS machine" "%OFF_TMP%" 2^>nul') do (
        set "OFF_KMS_HOST=%%a"
    )

    if defined OFF_KMS_HOST (
        echo        KMS Server: !OFF_KMS_HOST!
    )

    :: Check localhost
    findstr /i /c:"127.0.0.1" /c:"0.0.0.0" /c:"localhost" "%OFF_TMP%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [!!!] KMS GIA LAP [localhost] - OFFICE LA CRACK!
        set /a CRACK_COUNT+=1
        set "CRACK_DETAILS=!CRACK_DETAILS! Office:KMS-localhost"
        set "OFF_VERDICT=CRACK"
        set "OFF_DETAIL=KMS gia lap localhost"
    ) else (
        echo        Tren may CA NHAN: day la CRACK [KMS].
        echo        Trong DOANH NGHIEP: co the hop le [can xac nhan voi IT].
        set /a CRACK_COUNT+=1
        set "CRACK_DETAILS=!CRACK_DETAILS! Office:KMS-Volume"
        set "OFF_VERDICT=CRACK"
        set "OFF_DETAIL=KMS Volume - crack tren may ca nhan"
    )
    echo.
    goto :office_done
)

:: -------------------------------------------------------
:: BUOC 3: Phat hien phien ban DOANH NGHIEP tren may CA NHAN
:: (ProPlus, Standard, LTSC - Microsoft KHONG ban le cho ca nhan)
:: Day la truong hop pho bien: nguoi dung tim key tren mang
:: -------------------------------------------------------

set "OFF_IS_VOLUME_EDITION=0"

:: Check Professional Plus (chi ban cho doanh nghiep)
findstr /i /c:"ProPlus" /c:"Professional Plus" "%OFF_TMP%" >nul 2>&1
if !errorlevel! equ 0 (
    set "OFF_IS_VOLUME_EDITION=1"
    set "OFF_VOLUME_NAME=Professional Plus"
)

:: Check Standard (chi ban cho doanh nghiep)
if "!OFF_IS_VOLUME_EDITION!"=="0" (
    findstr /i /c:"Standard" "%OFF_TMP%" >nul 2>&1
    if !errorlevel! equ 0 (
        :: Loai tru truong hop "Home and Student" co chu "Standard" trong description
        findstr /i /c:"HomeStudent" /c:"Home and Student" /c:"HomeBusiness" /c:"Home and Business" "%OFF_TMP%" >nul 2>&1
        if !errorlevel! neq 0 (
            set "OFF_IS_VOLUME_EDITION=1"
            set "OFF_VOLUME_NAME=Standard"
        )
    )
)

:: Check LTSC (chi danh cho doanh nghiep)
if "!OFF_IS_VOLUME_EDITION!"=="0" (
    findstr /i /c:"LTSC" "%OFF_TMP%" >nul 2>&1
    if !errorlevel! equ 0 (
        set "OFF_IS_VOLUME_EDITION=1"
        set "OFF_VOLUME_NAME=LTSC"
    )
)

if "!OFF_IS_VOLUME_EDITION!"=="1" (
    echo   [!!!] Phat hien phien ban: Office !OFF_VOLUME_NAME!
    echo.
    echo        Microsoft KHONG BAN LE phien ban nay cho ca nhan.
    echo        Day la ban danh rieng cho DOANH NGHIEP [Volume Licensing].
    echo        Tren may CA NHAN: 99%% la key tim tren mang / key lau.
    echo.
    echo        Nguoi dung ca nhan chi co the mua hop le:
    echo          - Microsoft 365 Personal / Family [dang ky]
    echo          - Office Home / Home and Student / Home and Business [ban le]
    echo.

    :: Kiem tra them kenh kich hoat
    findstr /i "VOLUME_MAK" "%OFF_TMP%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo        Kenh kich hoat: MAK [Volume] - xac nhan la key doanh nghiep.
    )
    findstr /i "RETAIL" "%OFF_TMP%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo        Kenh kich hoat: RETAIL - nhung phien ban !OFF_VOLUME_NAME!
        echo        khong ban le cho ca nhan. KEY KHONG HOP LE.
    )

    set /a CRACK_COUNT+=1
    set "CRACK_DETAILS=!CRACK_DETAILS! Office:!OFF_VOLUME_NAME!-VolEdition"
    set "OFF_VERDICT=CRACK"
    set "OFF_DETAIL=Phien ban !OFF_VOLUME_NAME! - chi ban cho doanh nghiep"
    echo.
    goto :office_done
)

:: -------------------------------------------------------
:: BUOC 4: Kiem tra ban quyen CHINH HANG (whitelist)
:: Chi chap nhan: Retail consumer editions + Microsoft 365
:: -------------------------------------------------------

:: Check Microsoft 365 / Subscription (TIMEBASED_SUB)
findstr /i /c:"SUBSCRIPTION" /c:"TIMEBASED_SUB" /c:"O365" /c:"Microsoft 365" "%OFF_TMP%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [V] Ban quyen Microsoft 365 [Subscription] - CHINH HANG.
    set /a GENUINE_COUNT+=1
    set "OFF_VERDICT=GENUINE"
    set "OFF_DETAIL=Microsoft 365 Subscription"
    echo.
    goto :office_done
)

:: Check Retail + phien ban hop le cho ca nhan
findstr /i "RETAIL" "%OFF_TMP%" >nul 2>&1
if !errorlevel! equ 0 (
    :: Kiem tra ten phien ban co phai la ban le hop le khong
    set "OFF_IS_CONSUMER=0"

    findstr /i /c:"Home" /c:"Personal" /c:"HomeBusiness" /c:"HomeStudent" "%OFF_TMP%" >nul 2>&1
    if !errorlevel! equ 0 set "OFF_IS_CONSUMER=1"

    :: Office Professional (khong co Plus) co ban Retail hop le
    if "!OFF_IS_CONSUMER!"=="0" (
        findstr /i /c:"Professional" "%OFF_TMP%" >nul 2>&1
        if !errorlevel! equ 0 (
            :: Dam bao khong phai ProPlus (da check o tren)
            findstr /i /c:"ProPlus" /c:"Professional Plus" "%OFF_TMP%" >nul 2>&1
            if !errorlevel! neq 0 set "OFF_IS_CONSUMER=1"
        )
    )

    if "!OFF_IS_CONSUMER!"=="1" (
        echo   [V] Ban quyen RETAIL [ban le chinh hang].
        echo       Phien ban hop le cho nguoi dung ca nhan.
        set /a GENUINE_COUNT+=1
        set "OFF_VERDICT=GENUINE"
        set "OFF_DETAIL=RETAIL ban le chinh hang"
    ) else (
        echo   [?] Kenh RETAIL nhung phien ban khong ro.
        echo       Can xac minh them tai: https://account.microsoft.com/services
        set /a UNKNOWN_COUNT+=1
        set "OFF_VERDICT=UNKNOWN"
        set "OFF_DETAIL=RETAIL nhung phien ban khong ro"
    )
    echo.
    goto :office_done
)

:: Check MAK (Volume License - chi hop le trong doanh nghiep)
findstr /i "VOLUME_MAK" "%OFF_TMP%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   [!] Kenh kich hoat: MAK [Volume License - doanh nghiep].
    echo       Tren may CA NHAN: day la key doanh nghiep, KHONG HOP LE.
    echo       Trong DOANH NGHIEP: co the hop le [can xac nhan voi IT].
    set /a CRACK_COUNT+=1
    set "CRACK_DETAILS=!CRACK_DETAILS! Office:MAK-Personal"
    set "OFF_VERDICT=CRACK"
    set "OFF_DETAIL=MAK Volume License - key doanh nghiep"
    echo.
    goto :office_done
)

:: -------------------------------------------------------
:: BUOC 5: Khong xac dinh - mac dinh la nghi ngo
:: -------------------------------------------------------
echo   [!] Da kich hoat nhung KHONG xac dinh duoc kenh/phien ban.
echo       Khong thuoc cac loai ban quyen chinh hang da biet.
echo       Can xac minh tai: https://account.microsoft.com/services
set /a CRACK_COUNT+=1
set "CRACK_DETAILS=!CRACK_DETAILS! Office:Unknown-Channel"
set "OFF_VERDICT=CRACK"
set "OFF_DETAIL=Khong xac dinh kenh - khong thuoc ban quyen da biet"
echo.

:office_done
del "%OFF_TMP%" 2>nul

:: ==========================================================
:: PHAN C: PHAT HIEN CONG CU CRACK
:: ==========================================================
:crack_tools_section
echo [C] QUET DAU HIEU CONG CU CRACK
echo ----------------------------------------------------------
echo.

set "TOOL_FOUND=0"

:: --- C1: Kiem tra hook DLL (KMS_VL_ALL / MAS) ---
echo   --- Kiem tra Hook DLL ---
if exist "%windir%\System32\SppExtComObjHook.dll" (
    echo   [!!!] Tim thay SppExtComObjHook.dll trong System32!
    echo        Day la file cua KMS_VL_ALL / MAS activator.
    set /a CRACK_COUNT+=1
    set /a TOOL_FOUND+=1
    set "CRACK_DETAILS=!CRACK_DETAILS! Tool:SppExtComObjHook.dll"
) else (
    echo   [V] Khong tim thay hook DLL.
)
echo.

:: --- C2: Kiem tra Scheduled Tasks ---
echo   --- Kiem tra Scheduled Tasks lien quan KMS ---
set "TASK_TMP=%temp%\sched_tasks.tmp"
schtasks /query /fo list 2>nul > "%TASK_TMP%"

set "KMS_TASK_FOUND=0"
for %%t in (
    "KMS"
    "AutoKMS"
    "KMS_VL_ALL"
    "Activation-Renewal"
    "SppExtComObjPatcher"
    "MAS_"
    "KMSAuto"
    "Re-MAS"
    "YOURPRODUCTKEY"
) do (
    findstr /i %%t "%TASK_TMP%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [!!!] Tim thay scheduled task nghi ngo: %%~t
        set "KMS_TASK_FOUND=1"
    )
)

if "!KMS_TASK_FOUND!"=="1" (
    echo        Cac task nay thuong thuoc cong cu crack KMS.
    set /a CRACK_COUNT+=1
    set /a TOOL_FOUND+=1
    set "CRACK_DETAILS=!CRACK_DETAILS! Tool:ScheduledTask"
) else (
    echo   [V] Khong tim thay scheduled task KMS bat thuong.
)
del "%TASK_TMP%" 2>nul
echo.

:: --- C3: Kiem tra thu muc cai dat activator pho bien ---
echo   --- Kiem tra thu muc cong cu crack ---
set "DIR_FOUND=0"

if exist "%ProgramFiles%\KMSAuto" (
    echo   [!!!] Tim thay thu muc: "%ProgramFiles%\KMSAuto"
    set "DIR_FOUND=1"
)
if exist "%ProgramFiles%\KMSpico" (
    echo   [!!!] Tim thay thu muc: "%ProgramFiles%\KMSpico"
    set "DIR_FOUND=1"
)
if exist "%ProgramFiles(x86)%\KMSAuto" (
    echo   [!!!] Tim thay thu muc: "%ProgramFiles(x86)%\KMSAuto"
    set "DIR_FOUND=1"
)
if exist "%ProgramFiles(x86)%\KMSpico" (
    echo   [!!!] Tim thay thu muc: "%ProgramFiles(x86)%\KMSpico"
    set "DIR_FOUND=1"
)
if exist "%ProgramData%\KMSAutoS" (
    echo   [!!!] Tim thay thu muc: "%ProgramData%\KMSAutoS"
    set "DIR_FOUND=1"
)
if exist "%windir%\AAct_Tools" (
    echo   [!!!] Tim thay thu muc: "%windir%\AAct_Tools"
    set "DIR_FOUND=1"
)
if exist "%ProgramFiles%\Activation-Renewal" (
    echo   [!!!] Tim thay thu muc: "%ProgramFiles%\Activation-Renewal"
    set "DIR_FOUND=1"
)

if "!DIR_FOUND!"=="1" (
    echo        Cac thu muc nay thuong thuoc cong cu crack.
    set /a CRACK_COUNT+=1
    set /a TOOL_FOUND+=1
    set "CRACK_DETAILS=!CRACK_DETAILS! Tool:ActivatorDir"
) else (
    echo   [V] Khong tim thay thu muc cong cu crack.
)
echo.

:: --- C4: Kiem tra file/registry SppExtComObj ---
echo   --- Kiem tra file patcher ---
if exist "%windir%\System32\SppExtComObjPatcher.exe" (
    echo   [!!!] Tim thay SppExtComObjPatcher.exe!
    set /a TOOL_FOUND+=1
    set "CRACK_DETAILS=!CRACK_DETAILS! Tool:SppPatcher"
) else (
    echo   [V] Khong tim thay patcher executable.
)
echo.

if "!TOOL_FOUND!"=="0" (
    echo   =^> Khong phat hien dau hieu cong cu crack tren he thong.
    echo.
)

:: ==========================================================
:: PHAN D: TONG KET - TAO POPUP KET QUA
:: ==========================================================
:summary
echo.
echo   Dang tao bao cao ket qua...

:: --- Xac dinh trang thai hien thi ---
set "WIN_ICON=?"
set "WIN_COLOR=#FF9800"
set "WIN_LABEL=CHUA XAC DINH"
if "!WIN_VERDICT!"=="GENUINE" (
    set "WIN_ICON=V"
    set "WIN_COLOR=#4CAF50"
    set "WIN_LABEL=CHINH HANG"
)
if "!WIN_VERDICT!"=="CRACK" (
    set "WIN_ICON=X"
    set "WIN_COLOR=#f44336"
    set "WIN_LABEL=KHONG CHINH HANG"
)
if "!WIN_VERDICT!"=="NOT_ACTIVATED" (
    set "WIN_ICON=X"
    set "WIN_COLOR=#f44336"
    set "WIN_LABEL=CHUA KICH HOAT"
)

set "OFF_ICON=?"
set "OFF_COLOR=#FF9800"
set "OFF_LABEL=CHUA XAC DINH"
if "!OFF_VERDICT!"=="GENUINE" (
    set "OFF_ICON=V"
    set "OFF_COLOR=#4CAF50"
    set "OFF_LABEL=CHINH HANG"
)
if "!OFF_VERDICT!"=="CRACK" (
    set "OFF_ICON=X"
    set "OFF_COLOR=#f44336"
    set "OFF_LABEL=KHONG CHINH HANG"
)
if "!OFF_VERDICT!"=="NOT_FOUND" (
    set "OFF_ICON=-"
    set "OFF_COLOR=#9E9E9E"
    set "OFF_LABEL=KHONG TIM THAY"
)

:: --- Trang thai cong cu crack ---
set "TOOL_LABEL=Khong phat hien cong cu crack"
set "TOOL_COLOR=#4CAF50"
if !TOOL_FOUND! gtr 0 (
    set "TOOL_LABEL=Phat hien !TOOL_FOUND! dau hieu cong cu crack"
    set "TOOL_COLOR=#f44336"
)

:: --- Gom KMS server info cho popup ---
set "KMS_INFO="
if defined KMS_HOST set "KMS_INFO=Windows KMS: !KMS_HOST!"
if defined OFF_KMS_HOST (
    if defined KMS_INFO (
        set "KMS_INFO=!KMS_INFO! / Office KMS: !OFF_KMS_HOST!"
    ) else (
        set "KMS_INFO=Office KMS: !OFF_KMS_HOST!"
    )
)

:: --- Tu dong luu log ---
(
    echo ==========================================================
    echo    KET QUA KIEM TRA BAN QUYEN
    echo    Ngay: %date% - %time%
    echo    Ten may: %COMPUTERNAME%
    echo ==========================================================
    echo.
    echo TONG KET:
    echo   Windows: !WIN_LABEL! - !WIN_DETAIL!
    echo   Office:  !OFF_LABEL! - !OFF_DETAIL!
    echo   Cong cu crack: !TOOL_LABEL!
    if defined KMS_INFO echo   KMS Server: !KMS_INFO!
    echo.
    echo CHI TIET:
    echo   Crack count: !CRACK_COUNT!
    echo   Genuine count: !GENUINE_COUNT!
    echo   Unknown count: !UNKNOWN_COUNT!
    if defined CRACK_DETAILS echo   Crack details: !CRACK_DETAILS!
    echo.
    echo ----------------------------------------------------------
    echo WINDOWS LICENSE INFO:
    echo ----------------------------------------------------------
    cscript //nologo %windir%\system32\slmgr.vbs /dli 2^>^&1
    echo.
    cscript //nologo %windir%\system32\slmgr.vbs /xpr 2^>^&1
    echo.
    echo ----------------------------------------------------------
    echo OFFICE LICENSE INFO:
    echo ----------------------------------------------------------
    if defined target (
        cscript //nologo "!target!\ospp.vbs" /dstatus 2^>^&1
    ) else (
        echo Khong tim thay Office.
    )
) > "!LOG_FILE!"

:: --- Tao file HTA popup ---
set "HTA_FILE=%temp%\license_result.hta"

> "!HTA_FILE!" echo ^<html^>
>> "!HTA_FILE!" echo ^<head^>
>> "!HTA_FILE!" echo ^<meta http-equiv="Content-Type" content="text/html; charset=utf-8"^>
>> "!HTA_FILE!" echo ^<title^>Ket qua kiem tra ban quyen^</title^>
>> "!HTA_FILE!" echo ^<HTA:APPLICATION
>> "!HTA_FILE!" echo   APPLICATIONNAME="LicenseCheck"
>> "!HTA_FILE!" echo   BORDER="dialog"
>> "!HTA_FILE!" echo   BORDERSTYLE="normal"
>> "!HTA_FILE!" echo   CAPTION="yes"
>> "!HTA_FILE!" echo   MAXIMIZEBUTTON="no"
>> "!HTA_FILE!" echo   MINIMIZEBUTTON="no"
>> "!HTA_FILE!" echo   SCROLL="no"
>> "!HTA_FILE!" echo   SINGLEINSTANCE="yes"
>> "!HTA_FILE!" echo   SYSMENU="yes"
>> "!HTA_FILE!" echo /^>
>> "!HTA_FILE!" echo ^<style^>
>> "!HTA_FILE!" echo body{font-family:Segoe UI,Arial,sans-serif;margin:0;padding:22px 28px;background:#f0f2f5;color:#333}
>> "!HTA_FILE!" echo .hdr{text-align:center;margin-bottom:18px}
>> "!HTA_FILE!" echo .hdr h2{margin:0 0 4px;font-size:19px;color:#1a1a2e}
>> "!HTA_FILE!" echo .hdr p{margin:0;font-size:11px;color:#888}
>> "!HTA_FILE!" echo .cd{background:#fff;border-radius:8px;padding:14px 18px;margin:8px 0;box-shadow:0 2px 8px rgba(0,0,0,.08)}
>> "!HTA_FILE!" echo .cd table{width:100%%}
>> "!HTA_FILE!" echo .cd td{vertical-align:middle}
>> "!HTA_FILE!" echo .ic{width:42px;height:42px;border-radius:50%%;text-align:center;line-height:42px;font-size:19px;font-weight:700;color:#fff}
>> "!HTA_FILE!" echo .tt{font-size:11px;color:#888;text-transform:uppercase;letter-spacing:.5px;margin:0}
>> "!HTA_FILE!" echo .st{font-size:15px;font-weight:700;margin:2px 0}
>> "!HTA_FILE!" echo .dt{font-size:11px;color:#666;margin:0}
>> "!HTA_FILE!" echo .tb{background:#fff;border-radius:8px;padding:10px 18px;margin:8px 0;box-shadow:0 2px 8px rgba(0,0,0,.08);font-size:12px}
>> "!HTA_FILE!" echo .ft{text-align:center;margin-top:16px}
>> "!HTA_FILE!" echo .btn{padding:8px 24px;border:none;border-radius:5px;font-size:12px;cursor:pointer;margin:0 4px;font-family:Segoe UI}
>> "!HTA_FILE!" echo .bp{background:#0078d4;color:#fff}
>> "!HTA_FILE!" echo .bs{background:#e0e0e0;color:#333}
>> "!HTA_FILE!" echo .nt{text-align:center;margin-top:12px;font-size:10px;color:#999}
>> "!HTA_FILE!" echo .nt a{color:#0078d4}
>> "!HTA_FILE!" echo ^</style^>
>> "!HTA_FILE!" echo ^<script language="VBScript"^>
>> "!HTA_FILE!" echo Sub Window_OnLoad
>> "!HTA_FILE!" echo   window.resizeTo 480, 560
>> "!HTA_FILE!" echo   Dim sw,sh
>> "!HTA_FILE!" echo   sw=window.screen.availWidth
>> "!HTA_FILE!" echo   sh=window.screen.availHeight
>> "!HTA_FILE!" echo   window.moveTo (sw-480)/2,(sh-560)/2
>> "!HTA_FILE!" echo End Sub
>> "!HTA_FILE!" echo Sub OpenLog
>> "!HTA_FILE!" echo   Dim ws
>> "!HTA_FILE!" echo   Set ws=CreateObject("WScript.Shell")
>> "!HTA_FILE!" echo   ws.Run "notepad.exe ""!LOG_FILE!""",1,False
>> "!HTA_FILE!" echo End Sub
>> "!HTA_FILE!" echo Sub CloseApp
>> "!HTA_FILE!" echo   window.close
>> "!HTA_FILE!" echo End Sub
>> "!HTA_FILE!" echo ^</script^>
>> "!HTA_FILE!" echo ^</head^>
>> "!HTA_FILE!" echo ^<body^>
>> "!HTA_FILE!" echo ^<div class="hdr"^>
>> "!HTA_FILE!" echo   ^<h2^>Ket qua kiem tra ban quyen^</h2^>
>> "!HTA_FILE!" echo   ^<p^>May: %COMPUTERNAME% - %date% %time%^</p^>
>> "!HTA_FILE!" echo ^</div^>
>> "!HTA_FILE!" echo ^<div class="cd"^>^<table^>^<tr^>
>> "!HTA_FILE!" echo ^<td style="width:55px"^>^<div class="ic" style="background:!WIN_COLOR!"^>!WIN_ICON!^</div^>^</td^>
>> "!HTA_FILE!" echo ^<td^>^<p class="tt"^>Windows^</p^>^<p class="st" style="color:!WIN_COLOR!"^>!WIN_LABEL!^</p^>^<p class="dt"^>!WIN_DETAIL!^</p^>^</td^>
>> "!HTA_FILE!" echo ^</tr^>^</table^>^</div^>
>> "!HTA_FILE!" echo ^<div class="cd"^>^<table^>^<tr^>
>> "!HTA_FILE!" echo ^<td style="width:55px"^>^<div class="ic" style="background:!OFF_COLOR!"^>!OFF_ICON!^</div^>^</td^>
>> "!HTA_FILE!" echo ^<td^>^<p class="tt"^>Microsoft Office^</p^>^<p class="st" style="color:!OFF_COLOR!"^>!OFF_LABEL!^</p^>^<p class="dt"^>!OFF_DETAIL!^</p^>^</td^>
>> "!HTA_FILE!" echo ^</tr^>^</table^>^</div^>
>> "!HTA_FILE!" echo ^<div class="tb" style="border-left:4px solid !TOOL_COLOR!"^>
>> "!HTA_FILE!" echo   Cong cu crack: ^<strong style="color:!TOOL_COLOR!"^>!TOOL_LABEL!^</strong^>
>> "!HTA_FILE!" echo ^</div^>
if defined KMS_INFO (
>> "!HTA_FILE!" echo ^<div class="tb" style="border-left:4px solid #f44336"^>
>> "!HTA_FILE!" echo   KMS Server: ^<strong style="color:#f44336"^>!KMS_INFO!^</strong^>
>> "!HTA_FILE!" echo ^</div^>
)
>> "!HTA_FILE!" echo ^<div class="ft"^>
>> "!HTA_FILE!" echo   ^<button class="btn bs" onclick="OpenLog"^>Xem chi tiet^</button^>
>> "!HTA_FILE!" echo   ^<button class="btn bp" onclick="CloseApp"^>Dong^</button^>
>> "!HTA_FILE!" echo ^</div^>
>> "!HTA_FILE!" echo ^<div class="nt"^>
>> "!HTA_FILE!" echo   Xac minh chinh xac tai: ^<a href="https://account.microsoft.com/services"^>account.microsoft.com/services^</a^>
>> "!HTA_FILE!" echo   ^<br^>Log: !LOG_FILE!
>> "!HTA_FILE!" echo ^</div^>
>> "!HTA_FILE!" echo ^</body^>^</html^>

echo   Da luu log tai: !LOG_FILE!
echo   Dang mo cua so ket qua...

:: Mo HTA popup
start "" mshta "!HTA_FILE!"

:: Doi 2 giay roi dong console
timeout /t 2 /nobreak >nul
exit /b

