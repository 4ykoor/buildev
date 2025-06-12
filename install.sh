#!/data/data/com.termux/files/usr/bin/bash

# Atualizar pacotes básicos
pkg update -y && pkg upgrade -y

# Baixar o menu_termux.sh do seu repositório (troque URL pelo real)
curl -sLo ~/menu_termux.sh https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/menu_termux.sh

# Dar permissão de execução
chmod +x ~/menu_termux.sh

# Rodar o menu
bash ~/menu_termux.sh
