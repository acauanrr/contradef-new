# Contradef-New: Análise Simplificada com Docker

Este repositório fornece uma versão reestruturada e Dockerizada do projeto [Contradef](https://github.com/contradef/Contradef), uma ferramenta de instrumentação binária dinâmica baseada no Intel Pin para análise de software evasivo. O objetivo principal é simplificar drasticamente a instalação, configuração e execução para avaliadores de artigos científicos e outros pesquisadores.

Com este repositório, você poderá compilar e executar o Contradef em um ambiente isolado e reproduzível usando Docker, minimizando a necessidade de configurar manualmente dependências complexas em sua máquina local.

## Sumário

- [Contradef-New: Análise Simplificada com Docker](#contradef-new-análise-simplificada-com-docker)
  - [Sumário](#sumário)
  - [Visão Geral do Projeto](#visão-geral-do-projeto)
  - [Conteúdo do Repositório](#conteúdo-do-repositório)
  - [Pré-requisitos (Importante!)](#pré-requisitos-importante)
  - [Passo a Passo para Execução](#passo-a-passo-para-execução)
    - [1. Instalação do Docker](#1-instalação-do-docker)
    - [2. Clone este Repositório](#2-clone-este-repositório)

---

## Visão Geral do Projeto

Contradef utiliza o framework Intel Pin para realizar instrumentação dinâmica em executáveis, permitindo a observação e análise de seu comportamento em tempo de execução. É particularmente focado em técnicas usadas por software para evadir a detecção. Este wrapper Docker visa tornar o uso da ferramenta mais acessível.

*(Adicione uma breve descrição dos objetivos do seu artigo/pesquisa aqui, se relevante)*

---

## Conteúdo do Repositório

* `/Dockerfile`: Script para construir a imagem Docker com todas as dependências, incluindo Intel Pin, Visual Studio Build Tools, e o código fonte do Contradef para compilação.
* `/src/`: Código fonte completo do projeto Contradef (baseado no original).
* `/samples/`: (Opcional, se incluído) Diretório para colocar amostras de executáveis para análise.
* `/scripts/`: (Opcional, se incluído) Scripts para facilitar a execução de análises.
* `README.md`: Este arquivo.

---

## Pré-requisitos (Importante!)

Para utilizar este projeto com Docker, você **obrigatoriamente** precisará de:

1.  **Sistema Operacional Host:** Windows 10/11 (Pro, Enterprise, ou Education) ou Windows Server.
    * **Motivo:** O Dockerfile incluso constrói uma imagem Docker baseada em Windows para compilar e executar o Contradef, que é um projeto C++ para Windows dependente do Visual Studio e Intel Pin para Windows.
2.  **Docker Desktop para Windows:**
    * Instalado e configurado para usar **Contêineres Windows**. Você pode alternar entre contêineres Linux e Windows no menu do Docker Desktop.
    * Recursos alocados adequadamente para o Docker (RAM, CPU). Imagens Windows podem ser exigentes.
3.  **Git:** Para clonar este repositório.
4.  **Conexão com a Internet:** Para baixar a imagem base do Docker, ferramentas e dependências durante o build.

**Aviso para usuários de Linux/macOS:** Infelizmente, devido às dependências de compilação (Visual Studio) e execução (Intel Pin para Windows) do Contradef, não é trivial executar este projeto diretamente em contêineres Linux. A abordagem aqui foca em um ambiente Windows consistente via Docker.

---

## Passo a Passo para Execução

### 1. Instalação do Docker

* Baixe e instale o [Docker Desktop para Windows](https://docs.docker.com/desktop/install/windows-install/).
* Durante ou após a instalação, **certifique-se de que o Docker Desktop está configurado para usar "Windows containers"**. Você pode verificar isso clicando com o botão direito no ícone do Docker na bandeja do sistema.
* Aumente os recursos alocados para o Docker se necessário (Settings > Resources).

### 2. Clone este Repositório

Abra um terminal (PowerShell ou CMD) e clone o repositório `contradef-new`:

```bash
git clone <URL_DO_SEU_REPOSITORIO_CONTRADEF_NEW>
cd contradef-new