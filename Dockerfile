
# Base: Windows Server Core com Visual Studio Build Tools
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

SHELL ["powershell", "-Command", "Set-ExecutionPolicy Bypass -Scope Process -Force;"]

# Instalar Chocolatey para facilitar
RUN Invoke-WebRequest "https://chocolatey.org/install.ps1" -OutFile "install.ps1"; \
    ./install.ps1; Remove-Item "install.ps1" -Force

# Instalar Git e 7-Zip
RUN choco install -y git 7zip

# Instalar Visual Studio Build Tools (compilação C++)
RUN Invoke-WebRequest -Uri https://aka.ms/vs/16/release/vs_buildtools.exe -OutFile C:\vs_buildtools.exe; \
    Start-Process C:\vs_buildtools.exe -ArgumentList '--quiet --wait --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended' -Wait; \
    Remove-Item C:\vs_buildtools.exe -Force

# Baixar e extrair Intel Pin
ENV PIN_VERSION=3.28
ENV PIN_URL=https://software.intel.com/sites/landingpage/pintool/downloads/pin-${PIN_VERSION}-98749-g30a63da11-msvc-windows.zip
ENV PIN_ROOT=C:/pin

RUN Invoke-WebRequest -Uri $env:PIN_URL -OutFile C:\pin.zip; \
    7z x C:\pin.zip -oC:\pin_temp; \
    Move-Item -Path C:\pin_temp\pin-* -Destination $env:PIN_ROOT; \
    Remove-Item C:\pin.zip -Force; Remove-Item C:\pin_temp -Recurse -Force

# Copiar o código fonte
COPY ./src C:/app/src

# Compilar o Contradef
WORKDIR C:/app/src
RUN $env:VSCMD_START_DIR="C:\app\src"; \
    cmd /c "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\Tools\VsDevCmd.bat && \
    msbuild Contradef.sln /p:Configuration=Release /p:Platform=x64 /p:OutDir=../bin/Release/"

# Imagem final
FROM mcr.microsoft.com/windows/servercore:ltsc2019

ENV PIN_ROOT=C:/pin
ENV PATH="${PIN_ROOT};${PATH}"

COPY --from=builder C:/pin C:/pin
COPY --from=builder C:/app/bin/Release C:/app/bin/Release

WORKDIR C:/app
CMD ["powershell.exe", "-NoExit", "-Command", "Write-Host 'Contêiner Contradef pronto. Use pin.exe conforme o README!'"]
