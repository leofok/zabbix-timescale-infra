# Zabbix + TimescaleDB Infra Blueprint

此專案用於在 Ubuntu 主機上，以官方 zabbix-docker 專案為基礎，
自動部署 Zabbix Server，並可選擇：

- Zabbix 版本：7.4（預設）或 7.0 LTS
- 是否啟用 TimescaleDB
- 是否套用 rootless 80 port 設定
- 若主機已安裝 Docker，本專案會自動偵測並略過安裝步驟

## 設定選項

編輯 `vars.yml`：

- `zbx_version`: `"7.4"` 或 `"7.0"`
- `zbx_enable_timescaledb`: `true` / `false`
- `zbx_enable_rootless_ports`: `true` / `false`

## 遠端部署範例

在控制端（有 ansible）：

```bash
sudo apt update
sudo apt install -y ansible git

git clone https://github.com/leofok/zabbix-timescale-infra.git
cd zabbix-timescale-infra

cp inventory.example.ini inventory.ini
# 編輯 inventory.ini，填入 Zabbix 目標主機 IP / 帳號

ansible-playbook -i inventory.ini playbook.yml


## 在目標主機本機部署

sudo apt update
sudo apt install -y ansible git

git clone https://github.com/leofok/zabbix-timescale-infra.git
cd zabbix-timescale-infra

cat > inventory.ini <<EOF
[zabbix]
localhost ansible_connection=local
EOF

ansible-playbook -i inventory.ini playbook.yml
