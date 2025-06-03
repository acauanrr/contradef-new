# ---------------------------------------------------------
# Etapa 1: Ambiente de Build
# ---------------------------------------------------------
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

# Variáveis de ambiente
ENV PIN_ROOT="C:\\pin"
ENV PATH="$Env:PIN_ROOT;$Env:PATH"

# Diretório de trabalho para manipulação de arquivos temporários
WORKDIR C:/temp

# Copiar 7zr.exe portátil (certifique-se que está presente no diretório do Dockerfile)
COPY 7zr.exe C:/7zr.exe

# Copiar o Intel Pin ZIP
COPY pin-external-3.31-msvc-windows.zip C:/pin.zip

# Extrair o Intel Pin
RUN C:/7zr.exe x C:/pin.zip -oC:/pin_temp && \
    powershell -Command "Move-Item -Path (Get-ChildItem C:/pin_temp/pin-* -Directory).FullName + '\\*' -Destination $Env:PIN_ROOT -Force" && \
    del C:/pin.zip && \
    powershell -Command "Remove-Item C:/pin_temp -Recurse -Force" && \
    del C:/7zr.exe

# Copiar o código-fonte do Contradef para o contêiner
COPY ./src C:/app/src

# Definir o diretório de trabalho para compilação
WORKDIR C:/app/src

# Alternar para CMD para executar o ambiente de build do Visual Studio
SHELL ["cmd", "/S", "/C"]

# Compilar a solução Contradef.sln
RUN echo "Compiling Contradef solution..." && \
    call "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat" && \
    msbuild Contradef.sln /p:Configuration=Release /p:Platform=x64 /p:OutDir=..\\bin\\Release\\ && \
    echo "Contradef solution compilation complete."

# ---------------------------------------------------------
# Etapa Final: Imagem Final para Runtime
# ---------------------------------------------------------
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Variáveis de ambiente
ENV PIN_ROOT="C:\\pin"
ENV PATH="%PIN_ROOT%;%PATH%"

# Copiar o Intel Pin do estágio builder
COPY --from=builder C:/pin C:/pin

# Copiar os binários compilados do Contradef do estágio builder
COPY --from=builder C:/app/bin/Release C:/Contradef

# Definir diretório de trabalho para runtime
WORKDIR C:/Contradef

# Comando padrão ao iniciar o contêiner
CMD ["cmd.exe"]
