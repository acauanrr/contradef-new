# ---------------------------------------------------------
# Etapa 1: Ambiente de Build
# ---------------------------------------------------------
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

# Variáveis de ambiente
ENV PIN_ROOT="C:\\pin"
ENV PATH="$Env:PIN_ROOT;$Env:PATH"

# Diretório de trabalho
WORKDIR C:/temp

# Copiar 7z.exe e DLLs necessários para extração
COPY 7z.exe C:/7z.exe
COPY 7z.dll C:/7z.dll

# Copiar o Intel Pin ZIP
COPY pin-external-3.31-msvc-windows.zip C:/pin.zip

# Extrair o Intel Pin usando 7z.exe completo
RUN C:/7z.exe x C:/pin.zip -oC:/pin_temp && \
    C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -Command "$dir = (Get-ChildItem C:/pin_temp/pin-* -Directory).FullName; Move-Item -Path \"$dir\\*\" -Destination $Env:PIN_ROOT -Force" && \
    del C:\pin.zip && \
    C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -Command "Remove-Item C:/pin_temp -Recurse -Force" && \
    del C:\7z.exe && del C:\7z.dll

# ---------------------------------------------------------
# Instalação do Visual Studio Build Tools 2022
# ---------------------------------------------------------
RUN C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -Command " \
    $ErrorActionPreference = 'Stop'; \
    Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vs_BuildTools.exe -OutFile C:\vs_buildtools.exe; \
    Start-Process C:\vs_buildtools.exe -ArgumentList '--quiet', '--wait', '--norestart', '--nocache', '--add', 'Microsoft.VisualStudio.Workload.VCTools', '--includeRecommended' -Wait; \
    Remove-Item C:\vs_buildtools.exe -Force; \
    Write-Host 'Visual Studio Build Tools 2022 installation complete.'"

# Copiar o código-fonte do Contradef
COPY ./src C:/app/src

# Definir diretório de trabalho para compilação
WORKDIR C:/app/src

# Alternar para o CMD para executar o ambiente de build do Visual Studio
SHELL ["cmd", "/S", "/C"]

# Compilar a solução Contradef.sln
RUN echo "Compiling Contradef solution..." && \
    call "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat" && \
    msbuild Contradef.sln /p:Configuration=Release /p:Platform=x64 /p:OutDir=..\\bin\\Release\\ && \
    echo "Contradef solution compilation complete."

# ---------------------------------------------------------
# Etapa 2: Imagem Final para Runtime
# ---------------------------------------------------------
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Variáveis de ambiente
ENV PIN_ROOT="C:\\pin"
ENV PATH="%PIN_ROOT%;%PATH%"

# Copiar o Intel Pin e binários compilados do Contradef
COPY --from=builder C:/pin C:/pin
COPY --from=builder C:/app/bin/Release C:/Contradef

# Definir diretório de trabalho
WORKDIR C:/Contradef

# Comando padrão ao iniciar o contêiner
CMD ["cmd.exe"]
