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
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${PASSWORD}
    ports:
      - "3307:3306"
    volumes:
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql

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

# Cria o arquivo init.sql
cat <<EOL > init.sql
CREATE DATABASE IF NOT EXISTS ${DATABASE};
USE ${DATABASE};

CREATE TABLE Empresa (
    cnpj CHAR(14) PRIMARY KEY UNIQUE,
    nome VARCHAR(45),
    telefone CHAR(11)
);

CREATE TABLE Componentes (
    idComponente INT PRIMARY KEY AUTO_INCREMENT,
    nomeComponente VARCHAR(45),
    quantidade INT,
    preco DECIMAL(5,2),
    fkEmpresa CHAR(14),
    FOREIGN KEY (fkEmpresa) REFERENCES Empresa(cnpj)
);

CREATE TABLE Sala (
    idSala INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45),
    andar INT,
    fkEmpresa CHAR(14),
    FOREIGN KEY (fkEmpresa) REFERENCES Empresa(cnpj)
);

CREATE TABLE Funcionario (
    idFunc INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45),
    email VARCHAR(45),
    senha VARCHAR(45),
    telefone CHAR(11),
    tipo VARCHAR(45),
    CHECK (tipo IN('Empresa','Gestor','Técnico')),    
    turno VARCHAR(20),
    CHECK (turno IN('manha', 'tarde', 'noite')),
    estado VARCHAR(20),
    CHECK (estado IN('ativo', 'inativo')),
    fkEmpresa CHAR(14),
    FOREIGN KEY (fkEmpresa) REFERENCES Empresa(cnpj)
);

CREATE TABLE Maquina (
    hostname VARCHAR(45) PRIMARY KEY,
    ip VARCHAR(45),
    imagem DATE,
    fkSala INT,
    fkEmpresa CHAR(14),
    FOREIGN KEY (fkSala) REFERENCES Sala(idSala),
    FOREIGN KEY (fkEmpresa) REFERENCES Empresa(cnpj)
);

CREATE TABLE Metricas (
    idMetrica INT PRIMARY KEY AUTO_INCREMENT,
    CompCpu INT,
    CompDisco DOUBLE,
    CompRam DOUBLE,
    fkEmpresa CHAR(14),
    FOREIGN KEY (fkEmpresa) REFERENCES Empresa(cnpj)
);

CREATE TABLE HistoricoManutencao (
    idHistorico INT PRIMARY KEY AUTO_INCREMENT,
    Dia DATE,
    descricao VARCHAR(45),
    tipo VARCHAR(45),
    fkMaquina VARCHAR(45),
    fkSala INT,
    responsavel INT,
    FOREIGN KEY (fkMaquina) REFERENCES Maquina(hostname),
    FOREIGN KEY (fkSala) REFERENCES Sala(idSala),
    FOREIGN KEY (responsavel) REFERENCES Funcionario(idFunc)
);

CREATE TABLE LeituraSO (
    idSO INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45),
    tempoAtividade BIGINT,
    dataLeitura DATETIME DEFAULT CURRENT_TIMESTAMP,
    fkMaquina VARCHAR(45),
    FOREIGN KEY (fkMaquina) REFERENCES Maquina(hostname)
);

CREATE TABLE LeituraDisco (
    idDisco INT PRIMARY KEY AUTO_INCREMENT,
    total DOUBLE,
    emUso DOUBLE,
    disponivel DOUBLE,
    dataLeitura DATETIME DEFAULT CURRENT_TIMESTAMP,
    fkMaquina VARCHAR(45),
    FOREIGN KEY (fkMaquina) REFERENCES Maquina(hostname)
);

CREATE TABLE LeituraJanelas (
    idJanela INT PRIMARY KEY AUTO_INCREMENT,
    identificador BIGINT,
    pid INT,
    titulo VARCHAR(120),
    totalJanelas INT,
    dataLeitura DATETIME DEFAULT CURRENT_TIMESTAMP,
    fkMaquina VARCHAR(45),
    FOREIGN KEY (fkMaquina) REFERENCES Maquina(hostname)
);

CREATE TABLE LeituraCPU (
    idCPU INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100),
    emUso DOUBLE,
    temp DOUBLE,
    dataLeitura DATETIME DEFAULT CURRENT_TIMESTAMP,
    fkMaquina VARCHAR(45),
    FOREIGN KEY (fkMaquina) REFERENCES Maquina(hostname)
);

CREATE TABLE LeituraMemoriaRam (
    idRam INT PRIMARY KEY AUTO_INCREMENT,
    emUso DOUBLE,
    total DOUBLE,
    dataLeitura DATETIME DEFAULT CURRENT_TIMESTAMP,
    fkMaquina VARCHAR(45),
    FOREIGN KEY (fkMaquina) REFERENCES Maquina(hostname)
);

-- Insere dados de exemplo
INSERT INTO Empresa (cnpj, nome, telefone) VALUES ('12345678901234', 'MindCore', '11999999999');
INSERT INTO Funcionario (nome, email, senha, telefone, tipo, turno, estado, fkEmpresa) VALUES ('Admin', 'admin@mindcore.com', 'senha123', '11999999999', 'Gestor', 'manha', 'ativo', '12345678901234');
EOL

echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) docker-compose.yml e init.sql Criados"
sleep 2

echo "$(tput setaf 5)[Assistente Maya]: $(tput sgr0) $(tput setaf 10) Iniciando aplicação..."
sleep 2

docker-compose up -d
docker stop javaApp

# Função para executar consulta no banco de dados
executar_consulta() {
    local email="$1"
    local senha="$2"

    docker exec -i bd-mindcore mysql -uroot -p"$PASSWORD" -D"$DATABASE" -e "SELECT fkEmpresa FROM Funcionario WHERE email='$email' AND senha='$senha' LIMIT 1;" | tail -n1
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
