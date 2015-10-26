@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
SET old=change-to-mhtml
SET new=mhtml
for /f "tokens=*" %%f in ('dir /b *.jpg') do (
  SET newname=%%f
  SET newname=!newname:%old%=%new%!
  move "%%f" "!newname!"
)
