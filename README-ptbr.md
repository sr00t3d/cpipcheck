# Verificação de Licença de IP do cPanel

Readme: [EN](README.md)

![License](https://img.shields.io/github/license/sr00t3d/cpipcheck) ![Shell Script](https://img.shields.io/badge/language-Bash-green.svg)

<img width="700" src="cpipcheck-cover-webp" />

Um utilitário moderno em Bash para verificar informações de licença do cPanel/WHM, atualizado para a estrutura atual da API verify.cpanel.net.

## Sobre

Este projeto é uma **versão atualizada** do verificador de licença original de **Percio Andrade**. O script original utilizava um endpoint de API antigo (`http://verify.cpanel.net/index.cgi`) que foi descontinuado.

### Por que uma Atualização?

- **Novo endpoint de API** - Atualizado de `index.cgi` para `app/verify`
- **Suporte a HTTPS** - Conexões seguras (o original utilizava HTTP)
- **Nova estrutura HTML** - Interpreta o layout moderno do verify.cpanel.net
- **Melhor tratamento de erros** - Valida respostas e lida com casos extremos
- **Sem lookbehind no grep** - Compatível com ferramentas Unix padrão

## Recursos

| Recurso | Descrição | Original | Esta Versão |
|----------|------------|----------|-------------|
| Verificação de licença | Consulta ao servidor de licença do cPanel | ✅ | ✅ |
| Suporte a HTTPS | Chamadas seguras à API | ❌ | ✅ |
| API moderna | Estrutura atual do verify.cpanel.net | ❌ | ✅ |
| Resolução de hostname | Consulta reversa de DNS | ✅ | ✅ |
| Saída colorida | Cores no terminal para melhor leitura | ❌ | ✅ |
| Validação de IP | Valida formato de entrada | ❌ | ✅ |
| Tratamento de erros | Falhas tratadas adequadamente | ❌ | ✅ |
| Códigos de saída | Retorna 0 para ativo, 1 para inativo | ❌ | ✅ |

## Requisitos

- **Bash** 4.0+
- **curl** - para requisições HTTPS
- **host** - para resolução DNS (pacote bind-utils)
- Ferramentas Unix padrão: `grep`, `sed`, `awk`, `tr`

## Instalação

```bash
# Clonar ou baixar
curl -O https://raw.githubusercontent.com/sr00t3d/cpipcheck/refs/heads/main/cpipcheck.sh

# Tornar executável
chmod +x cpipcheck.sh

# Opcional: mover para o PATH
sudo mv cpipcheck.sh /usr/local/bin/cpcheck
```

## Uso

```bash
cpipcheck.sh <ENDEREÇO_IP>
```

### Argumentos

| Argumento | Descrição | Obrigatório |
|------------|------------|-------------|
| `ENDEREÇO_IP` | IP do servidor para verificar | Sim |

## Exemplos

### 1. Verificar Licença Ativa

```bash
./cpipcheck.sh 127.0.0.1
```

**Saída:**
```bash
═══════════════════════════════════════════════════════════════
              Verificação de Licença do cPanel
═══════════════════════════════════════════════════════════════

  Endereço IP:       127.0.0.1
  Hostname:          server.tld

───────────────────────────────────────────────────────────────
  Detalhes da Licença:
───────────────────────────────────────────────────────────────
  Pacote:            cPanel Autoscale Cloud (Internal)
  Produto:           cPanel/WHM
  Parceiro NOC:      Company, LTDA.
  Status:            ✓ ativo
  Atividade:         ativo em 2025-07-01 12:02:09
  Atualizações Expiram: N/A
───────────────────────────────────────────────────────────────
```

### 2. Verificar Sem Argumentos

```bash
./cpipcheck.sh
```

**Saída:**
```bash
Uso: ./cpipcheck.sh <ENDEREÇO_IP>
Exemplo: ./cpipcheck.sh 127.0.0.1
```

### 3. Formato de IP Inválido

```bash
./cpipcheck.sh invalid-ip
```

**Saída:**
```bash
Erro: Formato de endereço IP inválido
```

### 4. Nenhuma Licença Encontrada

```bash
./cpipcheck.sh 192.168.1.1
```

**Saída:**
```bash
Nenhuma licença encontrada para o IP 192.168.1.1
```

## Formato de Saída

### Cores

| Cor | Significado |
|------|-------------|
| 🟢 Verde | Status ativo |
| 🔴 Vermelho | Status inativo/expirado |
| 🟡 Amarelo | Rótulos e cabeçalhos |
| 🔵 Azul | Bordas e separadores |
| Ciano | Valores de IP e hostname |

### Indicadores de Status

| Símbolo | Status |
|----------|--------|
| `✓` | Licença ativa |
| `✗` | Licença inativa/expirada |

### Campos Explicados

| Campo | Descrição | Exemplo |
|--------|------------|---------|
| **Endereço IP** | O IP verificado | `127.0.0.1` |
| **Hostname** | Consulta DNS reversa | `server.tld` |
| **Pacote** | Tipo de licença | `cPanel Autoscale Cloud (Internal)` |
| **Produto** | Produto cPanel | `cPanel/WHM` |
| **Parceiro NOC** | Provedor da licença | `Company, LTDA.` |
| **Status** | Status atual | `ativo` ou `expirado` |
| **Atividade** | Data de ativação | `ativo em 2025-07-01 12:02:09` |
| **Atualizações Expiram** | Expiração das atualizações | `N/A` ou data |

## Códigos de Saída

| Código | Significado | Caso de Uso |
|--------|--------------|-------------|
| `0` | Licença **ativa** | Sucesso em scripts |
| `1` | Licença **inativa/expirada** ou **erro** | Alerta em monitoramento |

### Uso em Scripts

```bash
# Verificar licença e alertar se não estiver ativa
if ! ./cpipcheck.sh 127.0.0.1 > /dev/null 2>&1; then
    echo "ALERTA: Licença do cPanel não está ativa!" | mail -s "Alerta de Licença" admin@example.com
fi
```

```bash
# Verificação de status em uma linha
./cpipcheck.sh 127.0.0.1 > /dev/null && echo "Licença OK" || echo "PROBLEMA na Licença"
```

## Comparação com o Original

| Aspecto | Original (v1.0) | Esta Versão (v2.3) |
|----------|-----------------|--------------------|
| Endpoint da API | `http://verify.cpanel.net/index.cgi` | `https://verify.cpanel.net/app/verify` |
| Protocolo | HTTP (inseguro) | HTTPS (seguro) |
| Parser HTML | grep/cut simples | Awk + mapeamento de array |
| Validação de IP | Nenhuma | Validação com Regex |
| Tratamento de erros | Básico | Abrangente |
| Saída colorida | Nenhuma | Suporte completo a cores |
| Códigos de saída | Nenhum | 0=ativo, 1=inativo |
| Consulta de hostname | Sim | Sim |
| Estrutura moderna | Não | Sim |

## Solução de Problemas

### "command not found: host"
```bash
# Instalar bind-utils
yum install bind-utils      # CentOS/RHEL
apt-get install dnsutils    # Ubuntu/Debian
```

### "Nenhuma licença encontrada para o IP"
- O IP não possui licença cPanel associada
- Verifique se o endereço IP está correto
- Confira se a licença está registrada em [verify.cpanel.net](https://verify.cpanel.net)

### "Erro: Sem resposta do servidor de licença do cPanel"
- Problema de conectividade de rede
- verify.cpanel.net pode estar fora do ar
- Verifique configurações de firewall/proxy

### Campos vazios na saída
A estrutura HTML pode ter sido alterada. Depure com:
```bash
curl -s "https://verify.cpanel.net/app/verify?ip=YOUR_IP" > /tmp/debug.html
grep -A 20 'class="history table"' /tmp/debug.html
```

## Informações da API

### Endpoint Atual
```
https://verify.cpanel.net/app/verify?ip=<ENDEREÇO_IP>
```

### Formato da Resposta
Tabela HTML com histórico de licença:
```html
<table class="history table">
    <tr class="status1">
        <td align="center">1</td>
        <td align="center">IP_ADDRESS</td>
        <td align="center">PACKAGE</td>
        <td align="left">PARTNER_NOC</td>
        <td align="center">ACTIVITY</td>
        <td align="center">PRODUCT</td>
        <td><b>STATUS</b></td>
        <td>UPDATES_EXPIRATION</td>
    </tr>
</table>
```

## Créditos

- **Autor Original**: Percio Andrade
- **Versão Original**: 1.0
- **Versão Atualizada**: 2.3 (2026)
- **Propósito**: Ferramenta de verificação de licença do cPanel

## Aviso Legal

> [!WARNING]
> Este software é fornecido "como está". Sempre garanta que você tenha permissão explícita antes de executá-lo. O autor não se responsabiliza por qualquer uso indevido, consequências legais ou impacto em dados causados por esta ferramenta.

## Tutorial Detalhado

Para um guia completo passo a passo, confira meu artigo completo:

👉 [**Alterar IP da Conta no cPanel**](https://perciocastelo.com.br/blog/check-license-cpanel-in-cli.html)

## Licença

Este projeto está licenciado sob a **GNU General Public License v3.0**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

**Nota**: Este script é apenas para fins administrativos. Respeite os termos de serviço do cPanel e os limites de requisição ao usar a API de verificação.