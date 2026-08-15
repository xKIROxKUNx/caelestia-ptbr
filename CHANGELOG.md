# Histórico de versões

## v1.1.2

- A mensagem final do `instalar.sh` apontava o mapa base para personalização, o que seria
  desfeito na atualização seguinte. Agora aponta o overlay.

## v1.1.1

- Adiciona este histórico.

## v1.1.0

- **Avisos de bateria traduzidos.** "Low battery" / "You might want to plug in a charger" não
  estão em lugar nenhum do QML: são os valores padrão de `general.battery.warnLevels`,
  compilados dentro do `libcaelestia-config.so`. Agora são traduzidos na hora de exibir, sem
  mexer em texto que você tenha personalizado na sua própria config.
- **Overlay pessoal** em `~/.config/caelestia-ptbr/local.tsv`. Ajustes de palavra ficam nele,
  sobrepõem o mapa base e nunca são sobrescritos por uma atualização. Antes, editar o mapa
  instalado era perdido na atualização seguinte.
- **`atualizar.sh`** — busca a versão nova, mostra o que mudou e reinstala, sem clonar de novo.
- `desinstalar.sh` avisa que o overlay foi mantido.

## v1.0.0

- Primeira versão: 231 strings no mapa e 30 regras de código, dando 268 substituições em
  61 arquivos.
- Cobre barra, dashboard, launcher, tela de bloqueio, notificações, sidebar, OSD, menu de
  sessão, utilitários e os popouts de Wi-Fi, Bluetooth e bateria.
- Corrige as datas, que saíam com palavras em português na ordem do inglês.
- `instalar.sh`, `desinstalar.sh` e reaplicação automática após atualizações do `caelestia-shell`
  via unidade systemd `.path`.

---

**Atualizando da v1.0.0:** essa versão não trazia o `atualizar.sh`. Rode `git pull && ./instalar.sh`
uma vez; da próxima em diante, `./atualizar.sh` resolve.
