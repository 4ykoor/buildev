#!/bin/bash

echo "Atualizando Termux e instalando dependências básicas..."

pkg update -y && pkg upgrade -y
pkg install -y git wget unzip openjdk-17 gradle

echo "Criando pasta para Android SDK..."

mkdir -p ~/Android/Sdk

echo "Pronto! Agora rode ./menu.sh para começar."
