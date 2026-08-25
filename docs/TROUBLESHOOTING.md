# Problemas encontrados na instalacao (VPS Hostinger, Ubuntu 24.04)

Registro do que quebrou e como foi resolvido. Serve de referencia se
precisar reinstalar ou se algo voltar a falhar.

## 1. EACCES: permission denied, mkdir '/home/node/.openclaw/state'

**Causa:** o container roda como usuario `node` (UID 1000), mas os dados
iam para `/root/.openclaw`, que pertence ao root. Alem disso `/root` tem
permissao 700, entao o container nao conseguiria nem entrar na pasta.

**Solucao:** mover os dados para `/srv/openclaw` e dar o dono correto.

```bash
mkdir -p /srv/openclaw/config/workspace /srv/openclaw/auth-secrets
chown -R 1000:1000 /srv/openclaw
chmod 755 /srv/openclaw
```

E no `.env`:
```
OPENCLAW_CONFIG_DIR=/srv/openclaw/config
OPENCLAW_WORKSPACE_DIR=/srv/openclaw/config/workspace
OPENCLAW_AUTH_PROFILE_SECRET_DIR=/srv/openclaw/auth-secrets
```

## 2. "Missing config. Run `openclaw setup`"

Normal na primeira vez. Rodar:
```bash
docker compose exec openclaw-cli openclaw setup
```

Se disser que outra configuracao ja esta rodando, o assistente esta aberto
dentro do container (ele tem `tty: true`). Use `docker attach
openclaw-openclaw-cli-1` e saia com Ctrl+P Ctrl+Q (nunca Ctrl+C).

## 3. "address already in use" em portas que ninguem estava usando

`ss -tlnp` nao mostrava nenhum processo nas portas, mas o Docker recusava.
Reserva fantasma no daemon, deixada por containers que morreram no meio.

## 4. Cuidado com `ports: []` no override

Docker Compose **soma** listas (`ports`, `dns`) entre o arquivo base e o
override, em vez de substituir. Uma lista vazia nao remove nada.

## 5. `dns` + `network_mode` = conflito

O servico `openclaw-cli` usa `network_mode: "service:openclaw-gateway"`.
Container que herda rede de outro nao pode ter `dns` proprio. Configure
apenas no gateway; o cli herda.

## 6. getaddrinfo EAI_AGAIN (DNS do container)

O resolv.conf do container apontava para `127.0.0.11`, que repassava para
`127.0.0.53` (systemd-resolved do host) — inalcancavel de dentro do
container. Problema classico de Ubuntu + Docker.

Correcao (no gateway apenas):
```yaml
dns:
  - 1.1.1.1
  - 8.8.8.8
```

## 7. ENETUNREACH — a causa raiz

Sintomas finais:
- container so tinha a interface `lo`, sem `eth0`
- `/proc/net/route` vazio
- `docker inspect` retornava `ip=invalid IP gw=invalid IP`
- a bridge no host estava `state DOWN <NO-CARRIER>`
- `docker network connect` falhava com
  `network sandbox for container ... not found`

O daemon do Docker (29.7.2) perdeu o sandbox de rede do container e nao
conseguia recriar. Reiniciar o daemon resolveria, mas derrubaria os outros
containers da maquina.

**Solucao sem reiniciar o daemon:** usar a rede do host.

```yaml
services:
  openclaw-gateway:
    network_mode: host
  openclaw-cli:
    network_mode: host
```

Efeito colateral positivo: em `network_mode: host` as portas passam a ser
protegidas pelo `ufw`, o que nao acontece com portas publicadas pelo
Docker (o Docker escreve no iptables por baixo do ufw).

## Override final que funcionou

```yaml
services:
  openclaw-gateway:
    network_mode: host
    environment:
      NODE_OPTIONS: "--dns-result-order=ipv4first"
  openclaw-cli:
    network_mode: host
    environment:
      NODE_OPTIONS: "--dns-result-order=ipv4first"
```

## Pendencias

- [ ] Regras de iptables aplicadas na investigacao nao persistem apos
      reboot (hoje sao inofensivas, mas ficam sujeira). Limpar ou fixar.
- [ ] Descobrir de onde os containers da Evolution API foram iniciados —
      o docker-compose.yml deles nao esta em /root, entao hoje nao da para
      reiniciar nem atualizar aquele stack.
