# cPanel IP License Check (`cpipcheck`)

Readme: [EN](README.md)

![License](https://img.shields.io/github/license/sr00t3d/cpipcheck) ![Shell Script](https://img.shields.io/badge/language-Bash-green.svg)

<img width="700" alt="cPanel IP License Check" src="cpipcheck-cover.webp" />

Utilitário CLI rápido e confiável em Bash + Python3 (biblioteca padrão) para verificar licenças **cPanel/WHM**, **LiteSpeed**, **CloudLinux** e parceiros por IPv4 diretamente em `https://verify.cpanel.net/app/verify`. Suporta IP único, múltiplos IPs, arquivos em lote (`-f`), auto-detecção do IP público (`--self`), histórico completo (`--history`), DNS reverso (PTR), saída `table`/`json`/`csv` e exit codes prontos para automação.

## Funcionalidades (v2.0.0)

* **Parser HTML Resiliente (`HTMLParser`):** Extrai todas as linhas de `<table class="history table">` (incluindo múltiplas licenças ativas no mesmo IP como `LiteSpeed`, `CloudLinux`, `Imunify360`) sem regex frágil.
* **IP Único, Lote, Arquivo e `--self`:** Informe um ou mais IPs na linha de comando, leia uma lista com `-f servers.txt` ou detecte o IP público do servidor atual com `--self`.
* **Modo Histórico (`-H, --history`):** Exibe registros expirados/históricos ao lado das licenças ativas.
* **DNS Reverso (PTR) Nativo:** Resolve PTR via `socket.gethostbyaddr` do Python (dispensa instalar `bind-utils`/`dnsutils`).
* **Saída Estruturada (`-o table|json|csv`):** Pronto para terminais de NOC, Zabbix, Prometheus, SIEMs ou auditorias de faturamento.
* **Exit Codes Semânticos:** `0` = todos os IPs com licença ativa, `1` = erro de execução/rede, `2` = um ou mais IPs sem licença ativa.

## Pré-requisitos

* `bash` 4.0+
* `python3` (somente biblioteca padrão — zero pacotes `pip`)
* `curl` (necessário apenas ao usar `--self`)

## Exemplos Práticos

**Verificar um IPv4 único:**
```bash
./cpipcheck.sh 208.74.123.68
```

**Incluir licenças expiradas/históricas:**
```bash
./cpipcheck.sh --history 208.74.123.68
```

**Verificar o IP público do servidor atual em JSON:**
```bash
./cpipcheck.sh --self -o json
```

**Auditar uma frota de IPs em lote e exportar CSV:**
```bash
./cpipcheck.sh -f servers.txt -o csv > licenses.csv
```

## Execução Direta & Windows PowerShell

### Linux / macOS (Execução Direta)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sr00t3d/cpipcheck/main/cpipcheck.sh) 208.74.121.53
```

### Windows (PowerShell `cpipcheck.ps1`)
Zero dependências externas — compatível com **Windows PowerShell 5.1+** e **PowerShell 7+**:

```powershell
# Execução direta (sem clonar)
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/sr00t3d/cpipcheck/main/cpipcheck.ps1))) 208.74.121.53

# Execução local
.\cpipcheck.ps1 208.74.121.53
.\cpipcheck.ps1 208.74.121.53 -History
.\cpipcheck.ps1 -Self -Output json
.\cpipcheck.ps1 -File ips.txt -Output csv
```

## Exemplo de Saída Real

```text
================================================================================================================
 CPANEL IP LICENSE CHECK (cpipcheck) v2.0.0 | 2026-11-20 03:04:04 UTC
================================================================================================================
IP ADDRESS       | PRODUCT        | PACKAGE                    | PARTNER NOC        | STATUS             | PTR HOSTNAME
----------------------------------------------------------------------------------------------------------------
208.74.123.68    | LiteSpeed      | LITESPEED-UNLIMITED        | cPanel, L.L.C.     | active             | N/A
208.74.123.68    | cPanel/WHM     | CPANEL-SERVERS-INTERNAL    | cPanel, L.L.C.     | expired on 2026-08 | N/A
================================================================================================================
 Summary: 1 IP(s) checked | Active: 1 | Inactive/Unlicensed: 0
================================================================================================================
```

## Tutorial Detalhado

Confira o guia completo no blog: [**Verificar Licença cPanel pelo Terminal (CLI)**](https://perciocastelo.com.br/blog/check-license-cpanel-in-cli.html)

## Licença

Este projeto é distribuído sob a licença [Apache License 2.0](LICENSE).

---
Autor: **Percio Castelo**  
Contato: [contato@perciocastelo.com.br](mailto:contato@perciocastelo.com.br)  
Website: [https://perciocastelo.com.br](https://perciocastelo.com.br)