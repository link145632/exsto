@echo off
echo.
echo This batch file will install all recommended modules for Exsto.
echo.
echo Press Control+C to cancel or
pause
copy modules\gm_oosocks.dll ..\..\lua\includes\modules\gm_oosocks.dll
copy modules\gm_rawio.dll ..\..\lua\includes\modules\gm_rawio.dll
copy modules\gmsv_mysqloo.dll ..\..\lua\includes\modules\gmsv_mysqloo.dll
copy modules\libmySQL.dll ..\..\..\libmySQL.dll
copy modules\gmsv_gatekeeper.dll ..\..\lua\includes\modules\gmsv_gatekeeper.dll
echo Install Complete.
echo.
pause