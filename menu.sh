#!/bin/bash

# Diretório base dos projetos
BASE_DIR="$HOME/projects"

# Diretórios e variáveis SDK Android (ajuste conforme seu ambiente)
ANDROID_SDK="$HOME/Android/Sdk"
KEYSTORE_PATH="$HOME/my-release-key.keystore"
KEY_ALIAS="myalias"
KEYSTORE_PASSWORD="senha_do_keystore"

# Função para perguntar se usuário quer instalar e executar a instalação
prompt_instalar() {
  local nome="$1"
  local comando="$2"

  read -p "Deseja instalar $nome? (S/N): " resp
  if [[ "$resp" =~ ^[Ss]$ ]]; then
    echo "Instalando $nome..."
    eval "$comando"
    return 0
  else
    echo "$nome não será instalado."
    return 1
  fi
}

# Função para instalar dependências Android, perguntando antes
instalar_dependencias_android() {
  echo "Verificando dependências do ambiente Android..."

  # Java
  if ! command -v java &> /dev/null; then
    echo "Java não encontrado."
    prompt_instalar "openjdk" "pkg install -y openjdk" || return 1
  else
    echo "Java OK."
  fi

  # SDK Android
  if [ ! -d "$ANDROID_SDK" ]; then
    echo "SDK Android não encontrado."
    read -p "Deseja baixar SDK Android CLI tools (~200MB)? (S/N): " resp
    if [[ "$resp" =~ ^[Ss]$ ]]; then
      echo "Baixando SDK Android CLI tools..."
      mkdir -p "$ANDROID_SDK"
      cd "$ANDROID_SDK" || return 1
      wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdline-tools.zip
      unzip -q cmdline-tools.zip
      rm cmdline-tools.zip
      echo "SDK Android instalado em $ANDROID_SDK"
      echo "Você deve configurar as variáveis de ambiente ANDROID_SDK_ROOT e PATH manualmente."
    else
      echo "SDK Android é necessário para compilar APK."
      return 1
    fi
  else
    echo "SDK Android OK."
  fi

  # Gradle
  if ! command -v gradle &> /dev/null; then
    echo "Gradle não encontrado."
    prompt_instalar "gradle" "pkg install -y gradle" || return 1
  else
    echo "Gradle OK."
  fi

  return 0
}

# Criar estrutura Android básica
criar_estrutura_apk() {
  instalar_dependencias_android || return

  echo "Criando estrutura básica de projeto Android em $BASE_DIR/android_app"
  mkdir -p "$BASE_DIR/android_app/app/src/main/java/com/example/app"
  mkdir -p "$BASE_DIR/android_app/app/src/main/res/layout"
  mkdir -p "$BASE_DIR/android_app/app/src/main/res/values"

  # AndroidManifest.xml
  cat > "$BASE_DIR/android_app/app/src/main/AndroidManifest.xml" <<EOF
<manifest package="com.example.app" xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="MeuApp" android:icon="@mipmap/ic_launcher">
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

  # layout activity_main.xml
  cat > "$BASE_DIR/android_app/app/src/main/res/layout/activity_main.xml" <<EOF
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
  android:layout_width="match_parent"
  android:layout_height="match_parent"
  android:orientation="vertical"
  android:gravity="center">
  <TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="Hello Termux APK"/>
</LinearLayout>
EOF

  echo "Estrutura Android criada."
}

# Criar estrutura HTML básica
criar_estrutura_html() {
  echo "Criando estrutura básica de projeto Web em $BASE_DIR/web_app"
  mkdir -p "$BASE_DIR/web_app"

  cat > "$BASE_DIR/web_app/index.html" <<EOF
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <title>Projeto Web Termux</title>
</head>
<body>
  <h1>Olá do Termux Web</h1>
</body>
</html>
EOF

  echo "Estrutura Web criada."
}

# Compilar APK debug
compilar_apk_debug() {
  echo "Compilando APK Debug..."
  cd "$BASE_DIR/android_app" || { echo "Projeto Android não encontrado"; return; }

  if [ -f "./gradlew" ]; then
    ./gradlew assembleDebug
  else
    echo "Gradle wrapper não encontrado. Instale gradle ou configure o projeto."
  fi
}

# Compilar APK release e assinar
compilar_apk_release() {
  echo "Compilando APK Release..."
  cd "$BASE_DIR/android_app" || { echo "Projeto Android não encontrado"; return; }

  if [ -f "./gradlew" ]; then
    ./gradlew assembleRelease

    APK_PATH="$BASE_DIR/android_app/app/build/outputs/apk/release/app-release-unsigned.apk"
    SIGNED_APK_PATH="$BASE_DIR/android_app/app-release-signed.apk"

    if [ -f "$APK_PATH" ]; then
      echo "Assinando APK..."

      if [ ! -f "$KEYSTORE_PATH" ]; then
        echo "Keystore não encontrado em $KEYSTORE_PATH"
        echo "Não será possível assinar o APK."
        return
      fi

      jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD" "$APK_PATH" "$KEY_ALIAS"

      if command -v zipalign &> /dev/null; then
        zipalign -v 4 "$APK_PATH" "$SIGNED_APK_PATH"
        echo "APK assinado e alinhado em $SIGNED_APK_PATH"
      else
        echo "zipalign não encontrado, APK assinado mas não alinhado."
      fi
    else
      echo "APK Release não encontrado."
    fi
  else
    echo "Gradle wrapper não encontrado."
  fi
}

# Copiar APK para downloads
baixar_apk() {
  echo "Copiando APK para Downloads..."

  APK_DEBUG="$BASE_DIR/android_app/app/build/outputs/apk/debug/app-debug.apk"
  APK_RELEASE="$BASE_DIR/android_app/app-release-signed.apk"
  DEST="$HOME/storage/downloads"

  if [ -f "$APK_RELEASE" ]; then
    cp "$APK_RELEASE" "$DEST"
    echo "APK Release copiado para $DEST"
  elif [ -f "$APK_DEBUG" ]; then
    cp "$APK_DEBUG" "$DEST"
    echo "APK Debug copiado para $DEST"
  else
    echo "Nenhum APK encontrado para copiar."
  fi
}

# Atualizar Termux
atualizar_termux() {
  pkg update && pkg upgrade -y
}

# Menu principal
while true; do
  clear
  echo "==== Menu Termux APK/Web ===="
  echo "1) Atualizar Termux"
  echo "2) Criar estrutura APK (Android)"
  echo "3) Criar estrutura HTML (Web)"
  echo "4) Compilar APK Debug"
  echo "5) Compilar APK Release + Assinar"
  echo "6) Baixar APK gerado"
  echo "7) Sair"
  echo -n "Escolha uma opção: "
  read opc

  case $opc in
    1) atualizar_termux ;;
    2) criar_estrutura_apk ;;
    3) criar_estrutura_html ;;
    4) compilar_apk_debug ;;
    5) compilar_apk_release ;;
    6) baixar_apk ;;
    7) echo "Saindo..."; exit 0 ;;
    *) echo "Opção inválida!"; sleep 1 ;;
  esac

  echo "Pressione Enter para continuar..."
  read
done
