# Contradef

> **Quickstart em uma linha (Windows Containers)**  
> Clone, compile e execute tudo com um único comando:
> ```powershell
> git clone https://github.com/SEU_USUARIO/Contradef.git `
>   ; cd Contradef `
>   ; docker build -t contradef:latest . `
>   ; docker run --rm -p 8080:8080 contradef:latest
> ```

---

## 📖 Sumário

- [Contradef](#contradef)
  - [📖 Sumário](#-sumário)
  - [Pré-requisitos](#pré-requisitos)
  - [Como Construir a Imagem Docker](#como-construir-a-imagem-docker)
- [1) Clone o repositório (substitua SEU\_USUARIO pelo seu usuário GitHub)](#1-clone-o-repositório-substitua-seu_usuario-pelo-seu-usuário-github)
- [2) Constrói a imagem Docker no modo Windows Containers](#2-constrói-a-imagem-docker-no-modo-windows-containers)

---

## Pré-requisitos

1. **Docker Desktop (Windows)**  
   - Tenha o **Docker Desktop instalado** e configurado para usar **Windows Containers** (clique no ícone do Docker Desktop e selecione “Switch to Windows containers…” se ainda estiver em Linux Containers).  
2. **Rede / Firewall**  
   - Libere acesso às URLs do Docker Hub e ao repositório do Chocolatey (`https://community.chocolatey.org`), caso haja restrições corporativas.

> **Importante**: não é necessário ter nenhum compilador C++ ou MSYS2 instalado na máquina local. Tudo será provido dentro do container.

---

## Como Construir a Imagem Docker

Abra o **PowerShell** (de preferência como Administrador) e execute:

```powershell
# 1) Clone o repositório (substitua SEU_USUARIO pelo seu usuário GitHub)
git clone https://github.com/SEU_USUARIO/Contradef.git
cd Contradef

# 2) Constrói a imagem Docker no modo Windows Containers
docker build -t contradef:latest .
