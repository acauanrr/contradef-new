# ---------------------------------------------------------
# Estágio 1: Builder
# ---------------------------------------------------------
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

# Preparar o PowerShell
SHELL ["powershell", "-Command", "Set-ExecutionPolicy Bypass -Scope Process -Force;"]

# Instalar Chocolatey
RUN Invoke-WebRequest "https://chocolatey.org/install.ps1" -OutFile "install.ps1"; \
    ./install.ps1; \
    Remove-Item "install.ps1" -Force

# Instalar Git e 7-Zip
RUN choco install -y git 7zip

# Instalar Visual Studio Build Tools (compilação C++)
RUN Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_BuildTools.exe" -OutFile "C:\\vs_buildtools.exe"; \
    Start-Process "C:\\vs_buildtools.exe" -ArgumentList '--quiet --wait --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended' -Wait; \
    Remove-Item "C:\\vs_buildtools.exe" -Force

# Copiar e extrair Intel Pin (ZIP baixado manualmente)
ENV PIN_ROOT=C:/pin
COPY pin-external-3.31-msvc-windows.zip C:/pin.zip
RUN 7z x C:/pin.zip -oC:/pin_temp; \
    Move-Item -Path C:/pin_temp/pin-* -Destination $env:PIN_ROOT; \
    Remove-Item C:/pin.zip -Force; \
    Remove-Item C:/pin_temp -Recurse -Force

# Copiar o código fonte
COPY ./src C:/app/src

# Compilar o Contradef
WORKDIR C:/app/src

# Troca temporária de shell para cmd
SHELL ["cmd", "/S", "/C"]

RUN call "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\Tools\VsDevCmd.bat" && \
    msbuild Contradef.sln /p:Configuration=Release /p:Platform=x64 /p:OutDir=..\\bin\\Release\\

# Volta o shell para PowerShell para próximos passos
SHELL ["powershell", "-Command", "Set-ExecutionPolicy Bypass -Scope Process -Force;"]

# ---------------------------------------------------------
# Estágio 2: Imagem Final
# ---------------------------------------------------------
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Definir variáveis de ambiente
ENV PIN_ROOT=C:/pin
ENV PATH="${PIN_ROOT};${PATH}"

# Copiar PIN e binários compilados
COPY --from=builder C:/pin C:/pin
COPY --from=builder C:/app/bin/Release C:/app/bin/Release

# Diretório de trabalho
WORKDIR C:/app

# Mensagem padrão ao entrar no contêiner
CMD ["powershell.exe", "-NoExit", "-Command", "Write-Host 'Contêiner Contradef pronto. Use pin.exe conforme o README!'"]
