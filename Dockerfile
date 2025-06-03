# Etapa 1: Ambiente de Build
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

# Configurações do PowerShell simplificadas
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

# Define um diretório de trabalho seguro e gravável
WORKDIR C:/temp

# Variáveis de ambiente para o Intel Pin
ENV PIN_ROOT="C:\\pin"
# O PIN_ROOT (C:\pin) é adicionado ao PATH
ENV PATH="$Env:PIN_ROOT;$Env:PATH"

# Instalação do Chocolatey e 7-Zip (método revisado)
RUN Write-Host 'Installing Chocolatey...'; \
    Set-ExecutionPolicy Bypass -Scope Process -Force; \
    # Usa iex para executar o script de instalação do Chocolatey diretamente da web
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')); \
    # O PATH para choco deve estar disponível na sessão atual após a instalação
    Write-Host 'Chocolatey installed. Installing 7-Zip...'; \
    choco install -y 7zip; \
    Write-Host 'Chocolatey and 7-Zip installation complete.'

# Instalação do Visual Studio Build Tools 2019 com as ferramentas C++
# (O restante do seu Dockerfile daqui para baixo permanece o mesmo que eu sugeri anteriormente)
# Link para VS 2019 Build Tools (v16)
RUN Write-Host 'Installing Visual Studio Build Tools 2019...'; \
    Invoke-WebRequest -Uri "https://aka.ms/vs/16/release/vs_buildtools.exe" -OutFile "vs_buildtools.exe"; \
    Start-Process .\vs_buildtools.exe -ArgumentList '--quiet', '--wait', '--norestart', '--nocache', '--add', 'Microsoft.VisualStudio.Workload.VCTools', '--includeRecommended' -Wait; \
    Remove-Item "vs_buildtools.exe" -Force; \
    Write-Host 'Visual Studio Build Tools 2019 installation complete.'

# Extração do Intel Pin
# Certifique-se que o arquivo pin-external-3.31-msvc-windows.zip está no contexto do build.
COPY pin-external-3.31-msvc-windows.zip C:\\pin.zip
RUN Write-Host 'Extracting Intel Pin...'; \
    # Garante que o 7-zip do Chocolatey seja usado.
    # O PATH deve ter C:\ProgramData\chocolatey\bin que contém 7z.exe (instalado pelo choco).
    # Se houver dúvidas, use o caminho completo para 7z, mas choco deve adicioná-lo ao PATH.
    # Teste se o 7z está no path primeiro:
    $7zPath = (Get-Command 7z.exe -ErrorAction SilentlyContinue).Source; \
    if (-not $7zPath) { $7zPath = "C:\Program Files\7-Zip\7z.exe"; Write-Warning "7z.exe not found in PATH, trying default C:\Program Files\7-Zip\7z.exe"; } \
    if (-not (Test-Path $7zPath)) { Write-Error "7z.exe not found at $7zPath or in PATH. Please ensure 7-Zip is installed and in PATH."; exit 1; } \
    & $7zPath x C:\\pin.zip -oC:\\pin_temp; \
    $PinSourceDir = (Get-ChildItem C:\\pin_temp\\pin-* -Directory).FullName; \
    Move-Item -Path ($PinSourceDir + "\\*") -Destination $Env:PIN_ROOT -Force; \
    Remove-Item C:\\pin.zip -Force; \
    Remove-Item C:\\pin_temp -Recurse -Force; \
    Write-Host 'Intel Pin extraction complete.'

# Copia o código-fonte do repositório Contradef para o contêiner
# O WORKDIR atual é C:/temp, copiamos o fonte para C:/app/src
COPY ./src C:\\app\\src

# Define o diretório de trabalho para a compilação
WORKDIR C:\\app\\src

# Alterna para o shell do CMD para usar vcvars64.bat
SHELL ["cmd", "/S", "/C"]

# Compila a solução Contradef.sln usando o MSBuild
RUN Write-Host "Compiling Contradef solution..." && \
    call "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat" && \
    msbuild Contradef.sln /p:Configuration=Release /p:Platform=x64 /p:OutDir=..\\bin\\Release\\ && \
    Write-Host "Contradef solution compilation complete."

# Etapa 2: Imagem Final
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Variáveis de ambiente para o Intel Pin na imagem final
ENV PIN_ROOT=C:\\pin
ENV PATH=%PIN_ROOT%;%PATH%

# Copia o Intel Pin do estágio de build para a imagem final
COPY --from=builder C:\\pin C:\\pin

# Copia os binários compilados do Contradef para a imagem final
# No estágio 'builder', o WORKDIR era C:\app\src, então OutDir=..\bin\Release resulta em C:\app\bin\Release
COPY --from=builder C:\\app\\bin\\Release C:\\Contradef

# Define o diretório de trabalho na imagem final
WORKDIR C:\\Contradef

# Define o comando padrão
CMD ["cmd.exe"]