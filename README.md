# Contradef

> **Quickstart completo (Windows Containers)**  
> Este guia leva você desde não ter nada instalado até compilar e executar o Contradef usando Docker.

---

## 📖 Sumário

1. [Pré-requisitos Iniciais](#pré-requisitos-iniciais)  
   1.1. [Instalar Docker Desktop (Windows)](#instalar-docker-desktop-windows)  
   1.2. [Configurar Docker para Windows Containers](#configurar-docker-para-windows-containers)  
2. [Conteúdo do Dockerfile](#conteúdo-do-dockerfile)  
3. [Como Construir a Imagem Docker](#como-construir-a-imagem-docker)  
4. [Como Executar o Container](#como-executar-o-container)  
5. [Estrutura de Pastas no Container](#estrutura-de-pastas-no-container)  
6. [Configuração Adicional](#configuração-adicional)  
7. [Exemplos de Uso (CLI e Web)](#exemplos-de-uso-cli-e-web)  
8. [Depuração / Entrando no Container](#depuração--entrando-no-container)  
9. [Resumo dos Comandos](#resumo-dos-comandos)  

---

## Pré-requisitos Iniciais

### Instalar Docker Desktop (Windows)

1. Acesse o site oficial do Docker Desktop:  
https://www.docker.com/products/docker-desktop
2. Baixe a versão para **Windows (Windows 10/11, 64 bits)**.  
3. Execute o instalador baixado (arquivo `.exe`) e siga as instruções padrão até que a instalação seja concluída.  
4. Quando a instalação terminar, faça login (ou crie uma conta Docker Hub se ainda não tiver).  
5. Aguarde o Docker Desktop inicializar. Você deverá ver o ícone de baleia (🐳) na bandeja do sistema.

> **Observação**: é fundamental ter Windows 10 (versão 1903 ou superior) ou Windows 11. Caso use uma versão anterior, o Docker Desktop poderá não funcionar corretamente.

---

### Configurar Docker para Windows Containers

Por padrão, o Docker Desktop pode iniciar em modo “Linux Containers”. É preciso alternar para “Windows Containers”:

1. Clique com o botão direito no ícone do Docker (baleia) na bandeja do sistema.  
2. Se estiver escrito **“Switch to Windows containers…”**, clique nessa opção.  
- O Docker reiniciará em modo Windows Containers.  
3. Se já estiver em modo Windows Containers, o ícone do menu mostrará **“Switch to Linux containers…”**, indicando que você já está no modo correto.

> **Verificação rápida**:  
> Abra um terminal PowerShell e execute:  
> ```powershell
> docker version
> ```  
> Você deve ver algo como `OS/Arch: windows/amd64` no detalhe do “Server” (Engine).

---

## Conteúdo do Dockerfile

A seguir, todo o conteúdo do `Dockerfile` necessário para compilar o Contradef em um ambiente Windows 21H2 com MSYS2:

```dockerfile
# --------------------------------------------------------------------
# Etapa 1: Builder (compilação com MSYS2)
# --------------------------------------------------------------------
FROM mcr.microsoft.com/windows:21H2 AS builder

# Para rodar comandos PowerShell sem prompt interativo:
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

# 1) Instalar Chocolatey (necessário para obter MSYS2)
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
 [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
 iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2) Instalar MSYS2 via Chocolatey
RUN choco install --yes msys2 --no-progress

# 3) Atualizar MSYS2 e instalar toolchain e bibliotecas de dev (ncursesw, X11, Xft, freetype)
RUN C:/tools/msys64/usr/bin/bash -lc "pacman -Syuu --noconfirm" ; \
 C:/tools/msys64/usr/bin/bash -lc "pacman -Su --noconfirm" ; \
 C:/tools/msys64/usr/bin/bash -lc "pacman -S --noconfirm \
     base-devel \
     mingw-w64-x86_64-toolchain \
     mingw-w64-x86_64-ncurses \
     mingw-w64-x86_64-libxft \
     mingw-w64-x86_64-libx11 \
     mingw-w64-x86_64-freetype"

# 4) Ajustar PATH para incluir MSYS2/MinGW-w64
ENV PATH="C:\\tools\\msys64\\usr\\bin;C:\\tools\\msys64\\mingw64\\bin;%PATH%"

# 5) Copiar todo o source (código C++) para dentro do builder
WORKDIR C:/contradef
COPY . .

# 6) Mudar para pasta de código-fonte e compilar (supondo que exista src/Makefile)
RUN C:/tools/msys64/usr/bin/bash -lc "cd /c/contradef/src && make all"


# --------------------------------------------------------------------
# Etapa 2: Runtime (imagem mais leve com somente executável e libs)
# --------------------------------------------------------------------
FROM mcr.microsoft.com/windows:21H2

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

# 1) Instalar apenas as bibliotecas de runtime mínimas via MSYS2 (ncurses, X11, Xft, freetype)
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
 [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
 choco install --yes msys2 --no-progress ; \
 C:/tools/msys64/usr/bin/bash -lc "pacman -Sy --noconfirm \
     mingw-w64-x86_64-ncurses \
     mingw-w64-x86_64-libxft \
     mingw-w64-x86_64-libx11 \
     mingw-w64-x86_64-freetype" ; \
 C:/tools/msys64/usr/bin/bash -lc "pacman -Sc --noconfirm"

# 2) Criar usuário sem privilégios
RUN net user /add contradefuser && \
 net localgroup administrators contradefuser /delete

USER contradefuser

# 3) Copiar o executável (contradef.exe) compilado para dentro da imagem final
WORKDIR C:/Users/contradefuser/AppData/Local/Programs/Contradef
COPY --from=builder C:/contradef/src/contradef.exe ./

# 4) Copiar eventuais arquivos de configuração (se houverem dentro de config/)
COPY --from=builder C:/contradef/config ./config

# 5) Criar pastas para input e output (montagem de volume)
RUN mkdir data ; mkdir data\input ; mkdir data\output

# 6) Expor porta 8080 (caso o programa abra servidor web; se for apenas CLI, pode omitir esta linha)
EXPOSE 8080

# 7) Definir volume para persistência de dados
VOLUME C:/Users/contradefuser/AppData/Local/Programs/Contradef/data

# 8) ENTRYPOINT padrão: executa contradef.exe; CMD padrão mostra ajuda
ENTRYPOINT ["C:\\Users\\contradefuser\\AppData\\Local\\Programs\\Contradef\\contradef.exe"]
CMD ["--help"]
