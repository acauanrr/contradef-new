# ---------------------------------------------------------
# Dockerfile final para o Contradef (somente runtime)
# ---------------------------------------------------------

# Base: Windows Server Core (leve e confiável)
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Variáveis de ambiente para o Intel Pin
ENV PIN_ROOT=C:/pin
ENV PATH="${PIN_ROOT};${PATH}"

# Copiar a ferramenta portátil 7-Zip (7zr.exe)
# 7zr.exe precisa estar no mesmo diretório do Dockerfile!
COPY 7zr.exe C:/7zr.exe

# Copiar o Intel Pin Tool ZIP
COPY pin-external-3.31-msvc-windows.zip C:/pin.zip

# Extrair o Intel Pin
RUN C:/7zr.exe x C:/pin.zip -oC:/pin_temp && \
    powershell -Command "Move-Item -Path C:/pin_temp/pin-* -Destination C:/pin" && \
    del C:/pin.zip && \
    powershell -Command "Remove-Item C:/pin_temp -Recurse -Force" && \
    del C:/7zr.exe

# Copiar os binários pré-compilados do Contradef
COPY ./bin/Release C:/app/bin/Release

# Definir o diretório de trabalho
WORKDIR C:/app

# Mensagem ao iniciar o contêiner
CMD ["powershell.exe", "-NoExit", "-Command", "Write-Host 'Contêiner Contradef pronto. Use pin.exe e Contradef.exe conforme o README!'"]
