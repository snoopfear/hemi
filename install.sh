#!/bin/bash

echo "Welcome to the t3rn Executor Setup by snoopfear!"

# Установка ccze для цветного форматирования логов
echo "Installing ccze for colored log formatting..."
sudo apt update && sudo apt upgrade -y
sudo apt -qy install ccze

# Проверка на существование переменной POPM_BTC_PRIVKEY
if [ -z "${POPM_BTC_PRIVKEY}" ]; then
    # Запрос ввода приватного ключа
    read -p "Enter your BTC Private Key: " POPM_BTC_PRIVKEY
    # Экспорт переменной
    export POPM_BTC_PRIVKEY
    
    # Сохранение переменной в .bashrc для постоянного использования
    echo "export POPM_BTC_PRIVKEY=\"$POPM_BTC_PRIVKEY\"" >> ~/.bashrc
else
    echo "Using existing POPM_BTC_PRIVKEY: $POPM_BTC_PRIVKEY"
fi

cd $HOME

# Указание ссылки для загрузки и имени файла
MINER_URL="https://github.com/hemilabs/heminetwork/releases/download/v0.4.3/heminetwork_v0.4.3_linux_amd64.tar.gz"
MINER_FILE="heminetwork_v0.4.3_linux_amd64.tar.gz"

echo "Downloading the Executor binary from $MINER_URL..."
curl -L -o $MINER_FILE $MINER_URL

# Проверка успешности загрузки
if [ $? -ne 0 ]; then
    echo "Failed to download the Executor binary. Please check your internet connection and try again."
    exit 1
fi

echo "Extracting the binary..."
tar -xzvf $MINER_FILE

# Удаление архива после распаковки
rm -rf $MINER_FILE && cd heminetwork_v0.4.3_linux_amd64

# Создание systemd сервиса для t3rn Executor
sudo tee /etc/systemd/system/miner.service > /dev/null <<EOF
[Unit]
Description=Pop Miner Service
After=network.target

[Service]
ExecStart=/root/heminetwork_v0.4.3_linux_amd64/popmd  # Полный путь к бинарному файлу
Environment="POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public"
Environment="POPM_BTC_CHAIN_NAME=testnet3"
Environment="POPM_BTC_PRIVKEY=$POPM_BTC_PRIVKEY"
Environment="POPM_LOG_LEVEL=INFO"
#Environment="POPM_PPROF_ADDRESS="
Environment="POPM_STATIC_FEE=155"

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка systemd для применения изменений
sudo systemctl daemon-reload

# Включение и запуск сервиса
sudo systemctl enable miner.service
sudo systemctl start miner.service

# Показ последних 100 строк журнала и непрерывное обновление с ccze
echo "Displaying the last 100 lines of the 'executor' service log and following updates with ccze formatting..."
journalctl -n 100 -f -u miner | ccze -A
