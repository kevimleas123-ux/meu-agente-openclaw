# Meu Agente OpenClaw — Mentor Financeiro no Telegram

Agente de IA rodando na minha VPS, usando **OpenClaw** como ponte entre o
**Telegram** e o modelo **Claude (Anthropic)**.

## O que tem aqui
| Arquivo | Para que serve |
|---|---|
| `.env.example` | Modelo das chaves/senhas. Você copia para `.env` e preenche. |
| `install-vps.sh` | Instala Docker + baixa o OpenClaw na VPS. |
| `agents/mentor-financeiro.md` | A personalidade do agente (o "cérebro"). |

---

## Passo a passo

### 1. Pegar as duas chaves (faça no computador, 5 min)
- **Claude:** entre em https://console.anthropic.com → *API Keys* → *Create Key*.
  Copie e guarde — ela só aparece uma vez. Coloque uns US$ 5 de crédito.
- **Telegram:** abra o Telegram, procure **@BotFather**, mande `/newbot`,
  escolha um nome e um usuário terminando em `bot`. Ele devolve um **token**.

### 2. Entrar na VPS
No terminal do seu computador:
```bash
ssh root@SEU_IP_DA_VPS
```

### 3. Instalar
```bash
git clone https://github.com/SEU_USUARIO/meu-agente-openclaw.git
bash meu-agente-openclaw/install-vps.sh
```
Se ele avisar que instalou o Docker, digite `exit`, entre de novo por SSH
e rode o comando de novo.

### 4. Configurar as chaves
```bash
cd ~/openclaw
cp ~/meu-agente-openclaw/.env.example .env
nano .env
```
Cole suas duas chaves. Salvar no `nano`: `Ctrl+O`, `Enter`, `Ctrl+X`.

### 5. Ligar
```bash
docker compose up -d
```

### 6. Conectar o Telegram
```bash
docker compose run --rm openclaw-cli channels add --channel telegram --token "SEU_TOKEN_DO_BOTFATHER"
```
Mande uma mensagem para o seu bot no Telegram. Vai aparecer um pedido de
pareamento; aprove com:
```bash
docker compose run --rm openclaw-cli pairing approve telegram ID_QUE_APARECEU
```

### 7. Dar a personalidade de mentor
Copie o conteúdo de `agents/mentor-financeiro.md` para o campo de
instruções do agente no painel: `http://127.0.0.1:18789`
(acesse pelo túnel SSH — ver Segurança abaixo).

---

## Segurança (importante)
Nunca abra a porta `18789` para a internet. Para acessar o painel, feche o
SSH e reabra assim:
```bash
ssh -L 18789:127.0.0.1:18789 root@SEU_IP_DA_VPS
```
Agora `http://127.0.0.1:18789` abre no navegador do seu computador.

O arquivo `.env` **nunca** vai para o GitHub (já está no `.gitignore`).

## Comandos do dia a dia
```bash
cd ~/openclaw
docker compose logs -f    # ver o que está acontecendo
docker compose restart    # reiniciar
docker compose down       # desligar
```
