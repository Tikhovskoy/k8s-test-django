# Django Site

Докеризированный сайт на Django для экспериментов с Kubernetes.

Внутри контейнера Django приложение запускается с помощью Nginx Unit, не путать с Nginx. Сервер Nginx Unit выполняет сразу две функции: как веб-сервер он раздаёт файлы статики и медиа, а в роли сервера-приложений он запускает Python и Django. Таким образом Nginx Unit заменяет собой связку из двух сервисов Nginx и Gunicorn/uWSGI. [Подробнее про Nginx Unit](https://unit.nginx.org/).

## Как подготовить окружение к локальной разработке

Код в репозитории полностью докеризирован, поэтому для запуска приложения вам понадобится Docker. Инструкции по его установке ищите на официальных сайтах:

- [Get Started with Docker](https://www.docker.com/get-started/)

Вместе со свежей версией Docker к вам на компьютер автоматически будет установлен Docker Compose. Дальнейшие инструкции будут его активно использовать.

## Как запустить сайт для локальной разработки

Запустите базу данных и сайт:

```shell
$ docker compose up
```

В новом терминале, не выключая сайт, запустите несколько команд:

```shell
$ docker compose run --rm web ./manage.py migrate  # создаём/обновляем таблицы в БД
$ docker compose run --rm web ./manage.py createsuperuser  # создаём в БД учётку суперпользователя
```

Готово. Сайт будет доступен по адресу [http://127.0.0.1:8080](http://127.0.0.1:8080). Вход в админку находится по адресу [http://127.0.0.1:8000/admin/](http://127.0.0.1:8000/admin/).

## Как вести разработку

Все файлы с кодом django смонтированы внутрь докер-контейнера, чтобы Nginx Unit сразу видел изменения в коде и не требовал постоянно пересборки докер-образа -- достаточно перезапустить сервисы Docker Compose.

### Как обновить приложение из основного репозитория

Чтобы обновить приложение до последней версии подтяните код из центрального окружения и пересоберите докер-образы:

``` shell
$ git pull
$ docker compose build
```

После обновлении кода из репозитория стоит также обновить и схему БД. Вместе с коммитом могли прилететь новые миграции схемы БД, и без них код не запустится.

Чтобы не гадать заведётся код или нет — запускайте при каждом обновлении команду `migrate`. Если найдутся свежие миграции, то команда их применит:

```shell
$ docker compose run --rm web ./manage.py migrate
…
Running migrations:
  No migrations to apply.
```

### Как добавить библиотеку в зависимости

В качестве менеджера пакетов для образа с Django используется pip с файлом requirements.txt. Для установки новой библиотеки достаточно прописать её в файл requirements.txt и запустить сборку докер-образа:

```sh
$ docker compose build web
```

Аналогичным образом можно удалять библиотеки из зависимостей.

<a name="env-variables"></a>
## Переменные окружения

Образ с Django считывает настройки из переменных окружения:

`SECRET_KEY` -- обязательная секретная настройка Django. Это соль для генерации хэшей. Значение может быть любым, важно лишь, чтобы оно никому не было известно. [Документация Django](https://docs.djangoproject.com/en/3.2/ref/settings/#secret-key).

`DEBUG` -- настройка Django для включения отладочного режима. Принимает значения `TRUE` или `FALSE`. [Документация Django](https://docs.djangoproject.com/en/3.2/ref/settings/#std:setting-DEBUG).

`ALLOWED_HOSTS` -- настройка Django со списком разрешённых адресов. Если запрос прилетит на другой адрес, то сайт ответит ошибкой 400. Можно перечислить несколько адресов через запятую, например `127.0.0.1,192.168.0.1,site.test`. [Документация Django](https://docs.djangoproject.com/en/3.2/ref/settings/#allowed-hosts).

`DATABASE_URL` -- адрес для подключения к базе данных PostgreSQL. Другие СУБД сайт не поддерживает. [Формат записи](https://github.com/jacobian/dj-database-url#url-schema).

## Как создать Secret в Kubernetes

Перед развёртыванием убедитесь, что в кластере создан `Secret` с чувствительными переменными окружения для Django.

### 1. Создайте файл `kubernetes/django-secret.yaml` со следующим содержимым:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: django-secret
type: Opaque
stringData:
  SECRET_KEY: devsecret
  DATABASE_URL: postgres://test_k8s:OwOtBep9Frut@192.168.49.1:5432/test_k8s
```

### 2. Добавьте файл в `.gitignore`, если он ещё не добавлен:

```
kubernetes/django-secret.yaml
```

### 3. Примените `Secret` в кластер:

```bash
kubectl apply -f kubernetes/django-secret.yaml
```

Проверьте, что `Secret` создан:

```bash
kubectl get secrets
```

Теперь `Deployment` сможет получить переменные `SECRET_KEY` и `DATABASE_URL`.

---

## Настройка Ingress в Kubernetes

Чтобы сайт был доступен по домену `http://star-burger.test` на стандартном порту 80 без проброса портов, настройте Ingress следующим образом:

### 1. Включите Ingress Controller в Minikube

```bash
minikube addons enable ingress
```

Убедитесь, что контроллер запущен:

```bash
kubectl get pods -n ingress-nginx
```

---

### 2. Измените сервис Django на ClusterIP

В `kubernetes/django-service.yaml`:

```yaml
spec:
  type: ClusterIP
```

Примените изменения:

```bash
kubectl apply -f kubernetes/django-service.yaml
```

---

### 3. Добавьте манифест Ingress

Создайте файл `kubernetes/django-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: django-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: star-burger.test
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: django
                port:
                  number: 80
```

Примените:

```bash
kubectl apply -f kubernetes/django-ingress.yaml
```

---

### 4. Пропишите домен локально

Добавьте строку в файл `C:\Windows\System32\drivers\etc\hosts` (от имени администратора):

```
127.0.0.1  star-burger.test
```

Если не используете `minikube tunnel`, замените `127.0.0.1` на IP из команды:

```bash
minikube ip
```

---

### 5. Запустите туннель (если используете Minikube с драйвером `docker`)

Откройте PowerShell от имени администратора и выполните:

```powershell
wsl -d Ubuntu -- minikube tunnel
```

Оставьте это окно открытым.

---

Теперь сайт будет доступен по адресу:

```
http://star-burger.test
```
