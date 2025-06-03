# ---------------------------------------------------------
# Dockerfile final para ambiente de runtime do Contradef
# ---------------------------------------------------------

# Base: Windows Server Core para ambiente final
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Definir PowerShell como shell padrão
SHELL ["powershell", "-Command", "Set-ExecutionPolicy Bypass -Scope Process -Force;"]

# Variáveis de ambiente
ENV PIN_ROOT=C:/pin
ENV PATH="${PIN_ROOT};${PATH}"

# Instalar Chocolatey e 7-Zip para extrair o Intel Pin
RUN Invoke-WebRequest "https://chocolatey.org/install.ps1" -OutFile "install.ps1"; \
    ./install.ps1; \
    Remove-Item "install.ps1" -Force; \
    choco install -y 7zip

# Copiar e extrair o Intel Pin
COPY pin-external-3.31-msvc-windows.zip C:/pin.zip
RUN 7z x C:/pin.zip -oC:/pin_temp; \
    Move-Item -Path C:/pin_temp/pin-* -Destination $env:PIN_ROOT; \
    Remove-Item C:/pin.zip -Force; \
    Remove-Item C:/pin_temp -Recurse -Force

# Copiar os binários pré-compilados do Contradef
COPY ./bin/Release C:/app/bin/Release

# Definir diretório de trabalho
WORKDIR C:/app

# Mensagem padrão ao iniciar o contêiner
CMD ["powershell.exe", "-NoExit", "-Command", "Write-Host 'Contêiner Contradef pronto. Use pin.exe conforme o README!'"]

