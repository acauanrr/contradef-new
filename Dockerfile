# ========================
# Etapa 1: Ambiente de Build
# ========================
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

# Variáveis de ambiente para o Intel Pin
ENV PIN_ROOT="C:\\pin"
ENV PATH="C:\\pin;${PATH}"

# Diretório de trabalho seguro
WORKDIR C:/temp

# Copiar utilitário 7-Zip (pré-incluído no contexto do build)
COPY 7z.exe C:/7z.exe
COPY 7z.dll C:/7z.dll

# Copiar e extrair o Intel Pin
COPY pin-external-3.31-msvc-windows.zip C:/pin.zip

RUN "C:\\7z.exe" x "C:\\pin.zip" -o"C:\\pin_temp" && \
    powershell -Command "$dir = (Get-ChildItem 'C:\\pin_temp\\pin-*' -Directory).FullName; Move-Item -Path ($dir + '\\*') -Destination $Env:PIN_ROOT -Force" && \
    del "C:\\pin.zip" && \
    powershell -Command "Remove-Item 'C:\\pin_temp' -Recurse -Force" && \
    del "C:\\7z.exe" && del "C:\\7z.dll"

# Instalação do Visual Studio Build Tools 2022 com VC++ e Windows SDK
RUN powershell -Command " \
    $ErrorActionPreference = 'Stop'; \
    Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vs_BuildTools.exe -OutFile C:\\vs_buildtools.exe; \
    Start-Process C:\\vs_buildtools.exe -ArgumentList '--quiet', '--wait', '--norestart', '--nocache', \
        '--add', 'Microsoft.VisualStudio.Workload.VCTools', \
        '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', \
        '--add', 'Microsoft.VisualStudio.Component.Windows10SDK.19041', \
        '--includeRecommended' -Wait; \
    Remove-Item C:\\vs_buildtools.exe -Force; \
    Write-Host 'Visual Studio Build Tools 2022 installation complete.'"

# Copia o código-fonte do Contradef para o contêiner
COPY ./src C:/app/src

# Define o diretório de trabalho para a compilação
WORKDIR C:/app/src

# Usa o shell do CMD para executar o VsDevCmd.bat e compilar
SHELL ["cmd", "/S", "/C"]

RUN echo "Compiling Contradef solution..." && \
    call "C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\Common7\\Tools\\VsDevCmd.bat" && \
    msbuild Contradef.sln /p:Configuration=Release /p:Platform=x64 /p:OutDir=..\\bin\\Release\\ && \
    echo "Contradef solution compilation complete."

# ========================
# Etapa 2: Imagem Final
# ========================
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Variáveis de ambiente para o Intel Pin
ENV PIN_ROOT=C:\\pin
ENV PATH=%PIN_ROOT%;%PATH%

# Copia o Intel Pin do estágio de build
COPY --from=builder C:/pin C:/pin

# Copia os binários compilados do Contradef
COPY --from=builder C:/app/bin/Release C:/Contradef

# Define o diretório de trabalho na imagem final
WORKDIR C:/Contradef

# Comando padrão
CMD ["cmd.exe"]
