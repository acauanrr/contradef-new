# ---------------------------------------------------------
# Dockerfile final para runtime e build simplificado
# ---------------------------------------------------------
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

# Variáveis de ambiente
ENV PIN_ROOT="C:\\pin"
ENV PATH="$Env:PIN_ROOT;$Env:PATH"

# Diretório de trabalho
WORKDIR C:/temp

# Copiar a ferramenta 7zr.exe portátil (baixe e coloque no build context)
COPY 7zr.exe C:/7zr.exe

# Copiar o Intel Pin
COPY pin-external-3.31-msvc-windows.zip C:/pin.zip

# Extrair o Intel Pin usando 7zr portátil
RUN C:/7zr.exe x C:/pin.zip -oC:/pin_temp && \
    powershell -Command "Move-Item -Path (Get-ChildItem C:/pin_temp/pin-* -Directory).FullName + '\\*' -Destination $Env:PIN_ROOT -Force" && \
    del C:/pin.zip && \
    powershell -Command "Remove-Item C:/pin_temp -Recurse -Force" && \
    del C:/7zr.exe

# Copiar o código-fonte do Contradef
COPY ./src C:/app/src

# Definir diretório de trabalho para a compilação
WORKDIR C:/app/src

# Alternar para o CMD para usar vcvars64.bat
SHELL ["cmd", "/S", "/C"]

# Compilar a solução Contradef.sln
RUN echo "Compiling Contradef solution..." && \
    call "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat" && \
    msbuild Contradef.sln /p:Configuration=Release /p:Platform=x64 /p:OutDir=..\\bin\\Release\\ && \
    echo "Contradef solution compilation complete."

# ---------------------------------------------------------
# Etapa final: runtime
# ---------------------------------------------------------
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Variáveis de ambiente
ENV PIN_ROOT="C:\\pin"
ENV PATH="%PIN_ROOT%;%PATH%"

# Copiar Intel Pin e binários do Contradef
COPY --from=builder C:/pin C:/pin
COPY --from=builder C:/app/bin/Release C:/Contradef

# Definir diretório de trabalho
WORKDIR C:/Contradef

# Comando padrão
CMD ["cmd.exe"]
