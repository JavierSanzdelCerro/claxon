@echo off
REM ---------------------------------------------------------------
REM  CLAXON: arranca el servidor (Spring Boot) en Windows.
REM  No hace falta tener Maven instalado: lo descarga el Maven Wrapper.
REM  Uso (PowerShell, desde la carpeta del repositorio):
REM      .\arrancar-servidor.cmd
REM ---------------------------------------------------------------
setlocal

REM 1) Buscar un JDK si JAVA_HOME no esta configurado.
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" goto :java_ok
set "JAVA_HOME="

REM JDKs descargados por IntelliJ IDEA
for /d %%D in ("%USERPROFILE%\.jdks\*") do if exist "%%D\bin\java.exe" set "JAVA_HOME=%%D"
if defined JAVA_HOME goto :java_ok

REM JDKs instalados en Program Files (Oracle, Temurin, Microsoft...)
for /d %%D in ("%ProgramFiles%\Java\jdk*" "%ProgramFiles%\Eclipse Adoptium\jdk*" "%ProgramFiles%\Microsoft\jdk*") do if exist "%%D\bin\java.exe" set "JAVA_HOME=%%D"
if defined JAVA_HOME goto :java_ok

REM java en el PATH
for /f "delims=" %%J in ('where java 2^>nul') do (
  for %%P in ("%%~dpJ..") do set "JAVA_HOME=%%~fP"
  goto :java_ok
)

echo.
echo  No encuentro Java (JDK 21 o superior).
echo  Abre IntelliJ IDEA ^> File ^> Project Structure ^> SDKs ^> + ^> Download JDK,
echo  o pon la ruta a mano antes de arrancar, por ejemplo:
echo      $env:JAVA_HOME = "C:\Users\dam2\.jdks\oracle-25"
echo.
exit /b 1

:java_ok
echo Usando Java en: %JAVA_HOME%
set "PATH=%JAVA_HOME%\bin;%PATH%"

REM 2) Arrancar el servidor con datos de demostracion (http://localhost:8080).
cd /d "%~dp0backend"
echo Arrancando CLAXON... la primera vez tarda unos minutos (descarga Maven y librerias).
echo Cuando veas "Started ClaxonApplication" ya esta listo. Para pararlo: Ctrl+C.
call mvnw.cmd spring-boot:run
