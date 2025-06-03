# ========================
# Etapa 1: Ambiente de Build
# ========================
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

# Variáveis de ambiente para o Intel Pin
ENV PIN_ROOT="C:\\pin"
ENV PATH="$Env:PIN_ROOT;$Env:PATH"

# Diretório de trabalho seguro
WORKDIR C:/temp

# Copiar utilitário 7-Zip (pelo que entendi, você já o incluiu no contexto do build)
COPY 7z.exe C:/7z.exe
COPY 7z.dll C:/7z.dll
# 7zx.dll não foi usado explicitamente

# Copiar e extrair o Intel Pin
COPY pin-external-3.31-msvc-windows.zip C:/pin.zip
# Extração do Intel Pin (ajustado com aspas e caminhos consistentes)
RUN "C:\\7z.exe" x "C:\\pin.zip" -o"C:\\pin_temp" && \
    "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" -Command "$dir = (Get-ChildItem 'C:\\pin_temp\\pin-*' -Directory).FullName; Move-Item -Path ($dir + '\\*') -Destination $Env:PIN_ROOT -Force" && \
    del "C:\\pin.zip" && \
    "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" -Command "Remove-Item 'C:\\pin_temp' -Recurse -Force" && \
    del "C:\\7z.exe" && del "C:\\7z.dll"

# Instalação do Visual Studio Build Tools 2022 com componentes VC++ e SDK
RUN C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -Command " \
    $ErrorActionPreference = 'Stop'; \
    Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vs_BuildTools.exe -OutFile C:\vs_buildtools.exe; \
    Start-Process C:\vs_buildtools.exe -ArgumentList '--quiet', '--wait', '--norestart', '--nocache', \
        '--add', 'Microsoft.VisualStudio.Workload.VCTools', \
        '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', \
        '--add', 'Microsoft.VisualStudio.Component.Windows10SDK.19041', \
        '--includeRecommended' -Wait; \
    Remove-Item C:\vs_buildtools.exe -Force; \
    Write-Host 'Visual Studio Build Tools 2022 installation complete.'"

# Copia o código-fonte do Contradef para o contêiner
COPY ./src C:/app/src

# Define o diretório de trabalho para a compilação
WORKDIR C:/app/src

# Usa o shell do CMD para executar o VsDevCmd.bat
SHELL ["cmd", "/S", "/C"]

# Compila a solução Contradef.sln usando o MsBuild (via VsDevCmd.bat)
RUN echo "Compiling Contradef solution..." && \
    call "C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\Common7\\Tools\\VsDevCmd.bat" && \
    msbuild Contradef.sln /p:Configuration=Release /p:Platform=x64 /p:OutDir=..\\bin\\Release\\ && \
    echo "Contradef solution compilation complete."

# ========================
# Etapa 2: Imagem Final
# ========================
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Variáveis de ambiente para o Intel Pin na imagem final
ENV PIN_ROOT=C:\\pin
ENV PATH=%PIN_ROOT%;%PATH%

# Copia o Intel Pin do estágio de build para a imagem final
COPY --from=builder C:/pin C:/pin

# Copia os binários compilados do Contradef
COPY --from=builder C:/app/bin/Release C:/Contradef

# Define o diretório de trabalho na imagem final
WORKDIR C:/Contradef

# Define o comando padrão
CMD ["cmd.exe"]
