#!/bin/bash

clear
echo "==== Menu Termux Custom ===="
echo "1) Atualizar Termux"
echo "2) Instalar Node.js"
echo "3) Compilar projeto Android (exemplo)"
echo "4) Sair"
echo -n "Escolha uma opção: "
read opc

case $opc in
  1)
    pkg update && pkg upgrade
    ;;
  2)
    pkg install nodejs
    ;;
  3)
    echo "Compilando projeto Android..."
    # aqui você pode chamar seu script de compilação, ex:
    # ./compile_android.sh
    ;;
  4)
    exit 0
    ;;
  *)
    echo "Opção inválida"
    ;;
esac
