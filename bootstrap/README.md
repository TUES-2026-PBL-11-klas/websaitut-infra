# bootstrap

Тази папка описва инициализацията на Terraform remote state. Тъй като `terraform init` изисква backend, то няма как да [`live/`](../live) да създаде собствения си storage за съхраняване на състоянието в Azure Blob Storage. Затова той се създава единично с локален state. Това е стандартна и широко разпространена практика.

> [!IMPORTANT]
> Тъй като `bootstrap` отрязава нуждите на `live/`, то всяка промяна в live backend-а трябва да бъде отразена и тук.

## Структура 



| Ресурс | Име | Защо |
|---|---|---|
| Resource Group | `rg-tfstate` | контейнер за backend ресурсите, който ги отделя от останала инфраструктура |
| Storage Account | `elsystfstate` | държи `.tfstate` файла; LRS + versioning + soft-delete, за да не изгуби state при инцидент |
| Blob Container | `tfstate` | самият container, в който `live/` пише `website.terraform.tfstate` |

Имената по-горе са хардкоднати, защото трябва да съвпадат буквално с `backend "azurerm"` блока в `live/versions.tf`.

## Инициализация

Инициализацията се случва **еднократно** при първоначалното създаване на инфраструктурата в чисто нов subscription. След това `bootstrap/` почти никога не се пипа, а `live/` е активната конфигурация.

Стъпки:

```bash
az login         # аутентификация чрез Azure CLI 
cd bootstrap     
terraform init  
terraform plan
terraform apply
```

След успешен `apply`, `live/` вече може да прави `terraform init` — backend-ът съществува.

## Поддръжка

> [!NOTE]
> Тази конфигурация **няма** remote backend — state-ът ѝ живее локално, в `bootstrap/terraform.tfstate`. 

Това означава:

- `bootstrap/terraform.tfstate` е единственият запис, че Terraform управлява тези ресурси. Трябва да се пази разумно. 
- Ако бъде изгубен, ресурсите в Azure няма да изчезнат (`prevent_destroy` пази RG и storage account-а и без state), но Terraform вече не ги "помни". Възстановяването се случва чрез `terraform import`, **не** с нов `apply`, защото имената вече съществуват.
