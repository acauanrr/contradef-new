
# contradef-new

Este repositório simplifica a instalação e execução do [Contradef](https://github.com/contradef/Contradef), uma ferramenta de análise de executáveis evasivos baseada no Intel Pin.

## 3 Etapas para Executar e Testar

### 1️⃣ Download e Instalação do Docker

- Baixe e instale o [Docker Desktop para Windows](https://docs.docker.com/desktop/install/windows-install/).
- **Ative "Windows containers"** (botão direito no ícone do Docker Desktop).
- Verifique a instalação:
  ```powershell
  docker --version
  docker info
  ```

### 2️⃣ Criação do Contêiner Docker

1. Clone este repositório:
   ```powershell
   git clone <URL_DO_SEU_REPOSITORIO_CONTRADEF_NEW>
   cd contradef-new
   ```
2. (Opcional) Crie a pasta `samples/` e adicione executáveis para análise:
   ```powershell
   mkdir samples
   # Copie seus arquivos executáveis aqui
   ```
3. Crie a pasta de logs:
   ```powershell
   mkdir logs
   ```
4. Construa a imagem Docker:
   ```powershell
   docker build -t contradef-img .
   ```

### 3️⃣ Execução e Teste

1. Inicie o contêiner:
   ```powershell
   docker run -it --rm `
     -v "${PWD}/samples:C:/mnt/samples" `
     -v "${PWD}/logs:C:/mnt/logs" `
     contradef-img
   ```
2. No contêiner, vá para a pasta de logs:
   ```powershell
   cd C:/mnt/logs
   ```
3. Execute a análise:
   ```powershell
   pin.exe -injection child -t C:/app/bin/Release/contradef.dll -trace_instr -trace_mem -- C:/mnt/samples/seu_programa.exe
   ```
4. Os logs estarão em `contradef-new/logs` no seu PC.
