# ---------------------------------------------------------
# Dockerfile final
# ---------------------------------------------------------
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

ENV PIN_ROOT="C:\\pin"
ENV PATH="$Env:PIN_ROOT;$Env:PATH"

WORKDIR C:/temp

# Copiar o 7z.exe e 7z.dll completos
COPY 7z.exe C:/7z.exe
COPY 7z.dll C:/7z.dll
COPY 7zx.dll C:/7zx.dll

# Copiar o ZIP do Intel Pin
COPY pin-external-3.31-msvc-windows.zip C:/pin.zip

# Extrair usando 7z.exe completo
RUN C:/7z.exe x C:/pin.zip -oC:/pin_temp && \
    powershell -Command "Move-Item -Path (Get-ChildItem C:/pin_temp/pin-* -Directory).FullName + '\\*' -Destination $Env:PIN_ROOT -Force" && \
    del C:/pin.zip && \
    powershell -Command "Remove-Item C:/pin_temp -Recurse -Force" && \
    del C:/7z.exe && del C:/7z.dll

# Copiar o código-fonte do Contradef
COPY ./src C:/app/src

WORKDIR C:/app/src

SHELL ["cmd", "/S", "/C"]

RUN echo "Compiling Contradef solution..." && \
    call "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat" && \
    msbuild Contradef.sln /p:Configuration=Release /p:Platform=x64 /p:OutDir=..\\bin\\Release\\ && \
    echo "Contradef solution compilation complete."

# Etapa final
FROM mcr.microsoft.com/windows/servercore:ltsc2022

ENV PIN_ROOT="C:\\pin"
ENV PATH="%PIN_ROOT%;%PATH%"

COPY --from=builder C:/pin C:/pin
COPY --from=builder C:/app/bin/Release C:/Contradef

WORKDIR C:/Contradef
CMD ["cmd.exe"]
