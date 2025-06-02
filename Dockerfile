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

# 6) Expor porta 8080 (caso o programa abra servidor web; senão, pode remover esta linha)
EXPOSE 8080

# 7) Definir volume para persistência de dados
VOLUME C:/Users/contradefuser/AppData/Local/Programs/Contradef/data

# 8) ENTRYPOINT padrão: executa contradef.exe; CMD padrão mostra ajuda
ENTRYPOINT ["C:\\Users\\contradefuser\\AppData\\Local\\Programs\\Contradef\\contradef.exe"]
CMD ["--help"]
