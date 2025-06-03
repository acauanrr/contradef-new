# ---------------------------------------------------------
# Base: SDK .NET Framework com VS Build Tools e MSBuild já instalados
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2022 AS builder

# Preparar PowerShell
SHELL ["powershell", "-Command", "Set-ExecutionPolicy Bypass -Scope Process -Force;"]

# Instalar Chocolatey e 7-Zip
RUN Invoke-WebRequest "https://chocolatey.org/install.ps1" -OutFile "install.ps1"; \
    ./install.ps1; \
    Remove-Item "install.ps1" -Force; \
    choco install -y 7zip

# Variável de ambiente
ENV PIN_ROOT=C:/pin

# Copiar e extrair o Intel Pin
COPY pin-external-3.31-msvc-windows.zip C:/pin.zip
RUN 7z x C:/pin.zip -oC:/pin_temp; \
    Move-Item -Path C:/pin_temp/pin-* -Destination $env:PIN_ROOT; \
    Remove-Item C:/pin.zip -Force; \
    Remove-Item C:/pin_temp -Recurse -Force

# Copiar o código fonte
COPY ./src C:/app/src

# Compilar o Contradef
WORKDIR C:/app/src

# Mudar temporariamente o shell para CMD para build
SHELL ["cmd", "/S", "/C"]

# Usar vcvarsall.bat que existe em todas as instalações MSVC
RUN call "C:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 && \
    msbuild Contradef.sln /p:Configuration=Release /p:Platform=x64 /p:OutDir=..\\bin\\Release\\

# Voltar para PowerShell para os próximos passos
SHELL ["powershell", "-Command", "Set-ExecutionPolicy Bypass -Scope Process -Force;"]

# ---------------------------------------------------------
# Imagem final para runtime (Windows Server Core puro)
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Variáveis de ambiente
ENV PIN_ROOT=C:/pin
ENV PATH="${PIN_ROOT};${PATH}"

# Copiar PIN e binários compilados do estágio builder
COPY --from=builder C:/pin C:/pin
COPY --from=builder C:/app/bin/Release C:/app/bin/Release

# Diretório de trabalho
WORKDIR C:/app

# Mensagem ao entrar no contêiner
CMD ["powershell.exe", "-NoExit", "-Command", "Write-Host 'Contêiner Contradef pronto. Use pin.exe conforme o README!'"]
