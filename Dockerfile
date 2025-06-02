# Use uma imagem base do Windows Server Core com .NET Framework (útil para MSBuild)
# e ferramentas de desenvolvimento C++.
# Nota: Imagens Windows são grandes e o build pode ser demorado.
FROM mcr.microsoft.com/windows/servercore:ltsc2019 AS builder

SHELL ["powershell", "-Command", "Set-ExecutionPolicy Bypass -Scope Process -Force;"]

# Variáveis de ambiente para versões e caminhos
ENV PIN_VERSION=3.28
ENV PIN_FILENAME=pin-${PIN_VERSION}-98749-g30a63da11-msvc-windows.zip
# ATENÇÃO: O link de download direto do Pin pode ser instável ou mudar.
# É mais robusto baixar o Pin manualmente e usar ADD para copiá-lo para a imagem,
# ou encontrar um link de download persistente oficial.
# Este é um link de exemplo, verifique a página oficial do Intel Pin para o correto.
ENV PIN_DOWNLOAD_URL=https://software.intel.com/sites/landingpage/pintool/downloads/pin-${PIN_VERSION}-98749-g30a63da11-msvc-windows.zip
ENV PIN_ROOT=C:/pin
ENV CHOCOLATEY_VERSION=1.4.0

# Instalar Chocolatey (gerenciador de pacotes para Windows)
RUN Invoke-WebRequest "https://chocolatey.org/install.ps1" -OutFile "install.ps1"; \
    ./install.ps1; \
    Remove-Item -Path "install.ps1"; \
    # Adicionar ao PATH permanentemente para a sessão atual e futuras
    $env:PATH = $env:PATH + ";C:\ProgramData\chocolatey\bin"; \
    [System.Environment]::SetEnvironmentVariable('PATH', $env:PATH, [System.EnvironmentVariableTarget]::Machine)

# Instalar Git e 7-Zip usando Chocolatey
RUN choco install -y git --version=2.40.0; \
    choco install -y 7zip.commandline --version=22.01; \
    # Adicionar Git e 7-Zip ao PATH permanentemente
    $env:PATH = $env:PATH + ";C:\Program Files\Git\cmd;C:\Program Files\7-Zip"; \
    [System.Environment]::SetEnvironmentVariable('PATH', $env:PATH, [System.EnvironmentVariableTarget]::Machine)

# Instalar Visual Studio 2019 Build Tools (ou 2022 se preferir)
# É crucial instalar os componentes corretos para C++ Desktop development.
# A lista de workloads/componentes pode ser encontrada na documentação da Microsoft.
# Este comando é um exemplo e pode precisar ser ajustado.
RUN Invoke-WebRequest -Uri https://aka.ms/vs/16/release/vs_buildtools.exe -OutFile C:\vs_buildtools.exe; \
    Start-Process C:\vs_buildtools.exe -ArgumentList '--quiet --wait --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --add Microsoft.VisualStudio.Component.Windows10SDK.19041' -Wait; \
    Remove-Item C:\vs_buildtools.exe

# Baixar e extrair Intel Pin
# Tentar com Invoke-WebRequest, se falhar, considere adicionar o zip localmente.
RUN Write-Host "Baixando Intel Pin ${PIN_FILENAME}..."; \
    Invoke-WebRequest -Uri ${PIN_DOWNLOAD_URL} -OutFile C:\pin.zip -UseBasicParsing; \
    Write-Host "Extraindo Intel Pin..."; \
    & 'C:\Program Files\7-Zip\7z.exe' x C:\pin.zip -oC:\temp_pin_extract >> C:\extract.log; \
    # O Pin geralmente extrai para um diretório com o nome do arquivo zip (sem .zip)
    Move-Item -Path C:/temp_pin_extract/pin-${PIN_VERSION}-*-msvc-windows/* -Destination ${PIN_ROOT} -Force; \
    Remove-Item C:\pin.zip -Force; \
    Remove-Item C:\temp_pin_extract -Recurse -Force

# Copiar o código fonte do Contradef para dentro da imagem
COPY ./src /app/src

# Definir o diretório de trabalho para a compilação
WORKDIR /app/src

# Configurar o ambiente para MSBuild (chamar o script do Visual Studio)
# O caminho exato para VsDevCmd.bat pode variar ligeiramente com a versão do VS Build Tools.
# Este é um caminho comum para VS 2019 Build Tools.
# E depois executar o MSBuild.
RUN $vsDevCmdPath = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\2019\BuildTools\Common7\Tools\VsDevCmd.bat'; \
    cmd.exe /c "`"$vsDevCmdPath`" && msbuild Contradef.sln /p:Configuration=Release /p:Platform=x64 /p:OutDir=../bin/Release/"; \
    # Você pode querer Debug build para avaliação:
    # cmd.exe /c "`"$vsDevCmdPath`" && msbuild Contradef.sln /p:Configuration=Debug /p:Platform=x64 /p:OutDir=../bin/Debug/"

# Imagem final de execução (pode ser a mesma ou uma menor se possível, mas para Windows é menos comum)
# Para este caso, vamos usar a mesma imagem que já tem o ambiente.
WORKDIR /app

# Configurar o PATH para incluir o diretório do Pin
ENV PATH="${PIN_ROOT};${PATH}"

# Ponto de entrada padrão para o contêiner (opcional)
# Pode ser um PowerShell para que o usuário possa rodar os comandos.
CMD ["powershell.exe", "-NoExit", "-Command", "Write-Host 'Ambiente Contradef pronto. Use pin.exe para iniciar a análise. Ex: pin.exe -injection child -t C:/app/bin/Release/contradef.dll -- C:/path/to/your/sample.exe'"]