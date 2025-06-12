#!/bin/bash

BASE_DIR="$HOME/projects"
ANDROID_SDK="$HOME/Android/Sdk"

instalar_dependencias_android() {
  echo "Verificando Java..."
  if ! command -v java &> /dev/null; then
    echo "Java não encontrado. Instalando..."
    pkg install -y openjdk-17
  else
    echo "Java OK."
  fi

  echo "Verificando Gradle..."
  if ! command -v gradle &> /dev/null; then
    echo "Gradle não encontrado. Instalando..."
    pkg install -y gradle
  else
    echo "Gradle OK."
  fi

  echo "Verificando SDK Android..."
  if [ ! -d "$ANDROID_SDK" ]; then
    echo "SDK Android não encontrado."
    read -p "Deseja baixar SDK Android CLI tools (~200MB)? (S/N): " resp
    if [[ "$resp" =~ ^[Ss]$ ]]; then
      mkdir -p "$ANDROID_SDK"
      cd "$ANDROID_SDK" || return 1
      wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdline-tools.zip
      unzip -q cmdline-tools.zip
      rm cmdline-tools.zip
      echo "SDK Android instalado em $ANDROID_SDK"
    else
      echo "SDK Android necessário para compilar APK."
      return 1
    fi
  else
    echo "SDK Android OK."
  fi

  return 0
}

criar_estrutura_apk() {
  instalar_dependencias_android || return

  echo "Criando estrutura básica Android em $BASE_DIR/android_app..."
  mkdir -p "$BASE_DIR/android_app/app/src/main/java/com/example/app"
  mkdir -p "$BASE_DIR/android_app/app/src/main/res/layout"
  mkdir -p "$BASE_DIR/android_app/app/src/main/res/values"

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

atualizar_termux() {
  pkg update && pkg upgrade -y
}

while true; do
  clear
  echo "=== Menu Termux Simplificado ==="
  echo "1) Atualizar Termux"
  echo "2) Criar estrutura APK (Android)"
  echo "3) Sair"
  echo -n "Escolha uma opção: "
  read opc

  case $opc in
    1) atualizar_termux ;;
    2) criar_estrutura_apk ;;
    3) echo "Saindo..."; exit 0 ;;
    *) echo "Opção inválida!"; sleep 1 ;;
  esac

  echo "Pressione Enter para continuar..."
  read
done
