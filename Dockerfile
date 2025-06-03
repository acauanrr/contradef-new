# ---------------------------------------------------------
# Etapa 1: Ambiente de Build
# ---------------------------------------------------------
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

# Configuração do PowerShell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

# Variáveis de ambiente
ENV PIN_ROOT="C:\\pin"
ENV PATH="$Env:PIN_ROOT;$Env:PATH"

# Diretório de trabalho
WORKDIR C:/temp

# Instalação do Chocolatey e 7-Zip
RUN Write-Host 'Installing Chocolatey...'; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')); \
    Write-Host 'Chocolatey installed. Installing 7-Zip...'; \
    choco install -y 7zip; \
    Write-Host 'Chocolatey and 7-Zip installation complete.'

# Instalação do Visual Studio Build Tools 2019 com C++ Toolset (v16)
RUN Write-Host 'Installing Visual Studio Build Tools 2019...'; \
    Invoke-WebRequest -Uri "https://aka.ms/vs/16/release/vs_buildtools.exe" -OutFile "vs_buildtools.exe"; \
    Start-Process .\vs_buildtools.exe -ArgumentList '--quiet', '--wait', '--norestart', '--nocache', '--add', 'Microsoft.VisualStudio.Workload.VCTools', '--includeRecommended' -Wait; \
    Remove-Item "vs_buildtools.exe" -Force; \
    Write-Host 'Visual Studio Build Tools 2019 installation complete.'

# Copiar o Intel Pin
COPY pin-external-3.31-msvc-windows.zip C:/pin.zip

# Extração do Intel Pin usando o 7-Zip instalado
RUN Write-Host 'Extracting Intel Pin...'; \
    $sevenZip = (Get-Command 7z.exe -ErrorAction SilentlyContinue).Source; \
    if (-not $sevenZip) { $sevenZip = 'C:\\Program Files\\7-Zip\\7z.exe'; Write-Warning '7z.exe not found in PATH, trying default location.'; } \
    if (-not (Test-Path $sevenZip)) { Write-Error '7z.exe not found. Please ensure 7-Zip is available.'; exit 1; } \
    & $sevenZip x C:/pin.zip -oC:/pin_temp; \
    $PinSourceDir = (Get-ChildItem C:/pin_temp/pin-* -Directory).FullName; \
    Move-Item -Path ($PinSourceDir + "\\*") -Destination $Env:PIN_ROOT -Force; \
    Remove-Item C:/pin.zip -Force; \
    Remove-Item C:/pin_temp -Recurse -Force; \
    Write-Host 'Intel Pin extraction complete.'

# Copiar o código-fonte para dentro do contêiner
COPY ./src C:/app/src

# Definir o diretório de trabalho para a compilação
WORKDIR C:/app/src

# Alternar para o CMD para rodar o vcvars64.bat
SHELL ["cmd", "/S", "/C"]

# Compilar a solução Contradef.sln
RUN echo "Compiling Contradef solution..." && \
    call "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat" && \
    msbuild Contradef.sln /p:Configuration=Release /p:Platform=x64 /p:OutDir=..\\bin\\Release\\ && \
    echo "Contradef solution compilation complete."

# ---------------------------------------------------------
# Etapa 2: Imagem Final
# ---------------------------------------------------------
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Variáveis de ambiente para o Intel Pin
ENV PIN_ROOT="C:\\pin"
ENV PATH="%PIN_ROOT%;%PATH%"

# Copiar o Intel Pin da imagem de build
COPY --from=builder C:/pin C:/pin

# Copiar os binários compilados do Contradef
COPY --from=builder C:/app/bin/Release C:/Contradef

# Definir diretório de trabalho
WORKDIR C:/Contradef

# Comando padrão ao iniciar o contêiner
CMD ["cmd.exe"]
