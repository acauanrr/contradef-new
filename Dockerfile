# Etapa 1: Ambiente de Build
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

# Configurações do PowerShell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; Write-Host 'PowerShell as shell. ErrorActionPreference set to Stop.'"]

# Variáveis de ambiente para o Intel Pin
ENV PIN_ROOT="C:\\pin"
ENV PATH="$Env:PIN_ROOT;$Env:PATH"

# Instalação do Chocolatey e 7-Zip
RUN Write-Host 'Installing Chocolatey and 7-Zip...'; \
    Invoke-WebRequest -Uri "https://chocolatey.org/install.ps1" -OutFile "install.ps1"; \
    ./install.ps1; \
    Remove-Item "install.ps1" -Force; \
    choco install -y 7zip; \
    Write-Host 'Chocolatey and 7-Zip installation complete.'

# Instalação do Visual Studio Build Tools 2019 com as ferramentas C++
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
    & "C:\Program Files\7-Zip\7z.exe" x C:\\pin.zip -oC:\\pin_temp; \
    # O zip geralmente cria uma pasta como pin-3.31-xxxx-msvc-windows dentro de pin_temp
    # Movemos o conteúdo dessa pasta para $Env:PIN_ROOT
    $PinSourceDir = (Get-ChildItem C:\\pin_temp\\pin-* -Directory).FullName; \
    Move-Item -Path ($PinSourceDir + "\\*") -Destination $Env:PIN_ROOT -Force; \
    Remove-Item C:\\pin.zip -Force; \
    Remove-Item C:\\pin_temp -Recurse -Force; \
    Write-Host 'Intel Pin extraction complete.'

# Copia o código-fonte do repositório Contradef para o contêiner
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
# A shell padrão para windows/servercore é cmd, então usamos %VAR%
ENV PIN_ROOT=C:\\pin
ENV PATH=%PIN_ROOT%;%PATH%

# Copia o Intel Pin do estágio de build para a imagem final
COPY --from=builder C:\\pin C:\\pin

# Copia os binários compilados do Contradef para a imagem final
COPY --from=builder C:\\app\\bin\\Release C:\\Contradef

# Define o diretório de trabalho na imagem final
WORKDIR C:\\Contradef

# Define o comando padrão para iniciar um prompt de comando,
# permitindo ao usuário interagir com o ambiente Contradef e Pin.
CMD ["cmd.exe"]