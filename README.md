# Contradef

> **Quickstart completo (Windows Containers)**  
> Este guia leva você desde não ter nada instalado até compilar e executar o Contradef usando Docker.

---

## 📖 Sumário

1. [Pré-requisitos Iniciais](#pré-requisitos-iniciais)  
   1.1. [Instalar Docker Desktop (Windows)](#instalar-docker-desktop-windows)  
   1.2. [Configurar Docker para Windows Containers](#configurar-docker-para-windows-containers)  
2. [Como Construir a Imagem Docker](#como-construir-a-imagem-docker)  
3. [Como Executar o Container](#como-executar-o-container)  
4. [Estrutura de Pastas no Container](#estrutura-de-pastas-no-container)  
5. [Configuração Adicional](#configuração-adicional)  
6. [Exemplos de Uso (CLI e Web)](#exemplos-de-uso)  
7. [Depuração / Entrando no Container](#depuração--entrando-no-container)  
8. [Resumo dos Comandos](#resumo-dos-comandos)  

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

## Como Construir a Imagem Docker

1. Abra um **PowerShell** (sem necessidade de “Executar como Administrador”, a menos que tenha restrições de permissão).  
2. Clone este repositório e entre na pasta do projeto:  
```powershell
git clone https://github.com/SEU_USUARIO/Contradef.git
cd Contradef
