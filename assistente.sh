#!/bin/bash

readonly PASSWORD=mindcore123grupo6
readonly DATABASE=MindCore

echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10)Olá, eu sou a Maya, sua assistente virtual e vou te ajudar a iniciar nosso aplicativo!!"
sleep 2

echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10)Primeiro vou atualizar o seu sistema!"
sleep 2

sudo apt update
sudo apt upgrade -y

echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) Agora vou verificar se você tem o Docker"
sleep 2

if docker --version > /dev/null 2>&1; then
    echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) Docker Instalado"
else
    echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) Docker não instalado"
    sleep 2

    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    sudo apt update
    sudo apt install -y docker-ce

    echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) Adicionando o Docker ao grupo sudo..."
    sudo usermod -aG docker ${USER}
    newgrp docker
fi

echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) Verificando se você possui o Docker Compose"

if docker-compose --version > /dev/null 2>&1; then
    echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) Docker Compose Instalado."
else
    echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) Docker Compose não instalado"
    sleep 2

    sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Cria o arquivo docker-compose.yml
cat <<EOL > docker-compose.yml
version: '3.3'
services:
  bd:
    container_name: bd-mindcore
    image: helosalgado/atividadeso:v1
    restart: always
    ports:
      - "3307:3306"

  java_app:
    container_name: javaApp
    image: helosalgado/atividadeso:app
    restart: always
    ports:
      - "8080:8080"
    depends_on:
      - bd

volumes:
  mysql_data:
EOL

echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) docker-compose.yml Criado"
sleep 2

echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) Iniciando aplicação..."
sleep 2

docker-compose up -d
docker stop javaApp

# Função para executar consulta no banco de dados
executar_consulta() {
    local email="$1"
    local senha="$2"

    docker exec -it bd-mindcore bash -c "MYSQL_PWD=\"$PASSWORD\" mysql --batch -u root -D \"$DATABASE\" -e \"SELECT fkEmpresa FROM Funcionario WHERE email='$email' AND senha='$senha' LIMIT 1;\""
}

# Função para verificar se a consulta retornou resultado
verificar_resultado() {
    local query_result="$1"

    if [ -z "$query_result" ]; then
        echo "Usuário não encontrado"
        return 1
    else
        echo "Login efetuado com sucesso"
        return 0
    fi
}

main(){
    while true; do
        echo "
          ███╗   ███╗██╗███╗   ██╗██████╗      ██████╗ ██████╗ ██████╗ ███████╗
          ████╗ ████║██║████╗  ██║██╔══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝
          ██╔████╔██║██║██╔██╗ ██║██║  ██║    ██║     ██║   ██║██████╔╝█████╗ 
          ██║╚██╔╝██║██║██║╚██╗██║██║  ██║    ██║     ██║   ██║██╔══██╗██╔══╝ 
          ██║ ╚═╝ ██║██║██║ ╚████║██████╔╝    ╚██████╗╚██████╔╝██║  ██║███████╗
          ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝      ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
        "
        echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) Digite o email: "
        read -r email

        echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) Digite a senha: "
        read -r senha

        sleep 3

        local query_result
        query_result=$(executar_consulta "$email" "$senha")

        if verificar_resultado "$query_result"; then
            if ! java --version > /dev/null 2>&1; then
                sudo apt install -y openjdk-17-jre
            fi
            docker start javaApp
            break
        else
            echo "Falha no login. Por favor, tente novamente."
        fi
    done
}

main
