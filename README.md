Readme к выполненной работе. OTUS, курс "Administrator Linux. Advanced"
====

# Как использовать?

1. Проверить, что на ПК установлен консольный клиент `yc`, terraform и ansible
2. импортировать переменные для авторизации:
`export YC_TOKEN=$(yc iam create-token) ; export YC_CLOUD_ID=$(yc config get cloud-id) ; export YC_FOLDER_ID=$(yc config get folder-id)`

3. Проверить терраформ в тестовом режиме - `terraform plan`
4. Запустить терраформ в боевом режиме, если изменения в тестовом режиме удовлетворительны - `terraform apply`
5. В конце выполнения терраформ выведет IP адрес сервера, по которому можно проверить работу nginx

# Цель

* реализовать терраформ для разворачивания одной виртуалки в yandex-cloud
* запровиженить nginx с помощью ansible

# Для сдачи

* репозиторий с терраформ манифестами
* README файл

# Описание выполненной работы

1. Создал файл main.tf с указанием нужного провайдера
2. Инициализировал репозиторий с помощью команды `terraform init`
3. Настроил консольную утилиту `yc` согласно [документации](https://cloud.yandex.ru/docs/cli/quickstart#install)
4. Согласно [официальной документации](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart) создал сервисный аккаунт otus: `yc iam service-account create --name otus`
5. назначил ему роль `admin` в ПУ облака
6. выпустил JSON ключ: `yc iam key create --service-account-name=otus --folder-id=b1g9jv2jrp91ohku7e88 --output ~/key.json`
7. создал профиль `otus`: `yc config profile create otus`
8. Импортировал переменные окружения:

```
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
```

9. Скопировал из [инструкции](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance) пример создания Compute инстанса.
10. В ресурсе `yandex_vpc_subnet` дописал параметр `v4_cidr_blocks` с желаемой подсетью
11. Указал желаемый образ Ubuntu 22.04
12. Изменил количество ресурсов и уменьшил долю vCPU до 5%
13. Для удобства создал файл `variable.tf` с описанием переменных и `terraform.tfvars` с сами переменными
14. Подключил публичный IPv4 адрес через `nat_ip_address = yandex_vpc_address.addr.external_ipv4_address[0].address` и `nat            = true` в блоке `network_interface` ресурса `otus-vm`