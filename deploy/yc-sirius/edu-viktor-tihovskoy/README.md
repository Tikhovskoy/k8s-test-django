Вот обновлённая и дополненная версия `README.md` с учётом **текущего состояния**, включая деплой Nginx, проверку HTTPS-доступности и пояснения для dev-окружения в Яндекс.Облаке:
# Деплой Django-приложения в dev-окружение Яндекс.Облака

## Контекст окружения

* **Кластер**: `yc-sirius`
* **Namespace**: `edu-viktor-tihovskoy`
* **Доменное имя**: [`https://edu-viktor-tihovskoy.sirius-k8s.dvmn.org`](https://edu-viktor-tihovskoy.sirius-k8s.dvmn.org)

## Состав манифестов

### Django-приложение

* `django-deployment.yaml`
* `django-service.yaml`
* `django-ingress.yaml`
* `django-migrate-job.yaml`
* `django-clearsessions.yaml`
* `django-clearsessions-cronjob.yaml`

### Nginx (тестовый сервер)

* `nginx-pod.yaml`
* `nginx-service.yaml`
* `nginx-ingress.yaml`

## Как развернуть окружение

1. Перейти в нужный namespace:

```bash
kubectl config set-context --current --namespace=edu-viktor-tihovskoy
```

2. Применить манифесты:

```bash
./scripts/apply.sh
```

Или вручную:

```bash
kubectl apply -f nginx-pod.yaml
kubectl apply -f nginx-service.yaml
kubectl apply -f nginx-ingress.yaml
```

3. Проверить статус:

```bash
kubectl get pods
kubectl get svc
kubectl get ingress
```

4. Открыть сайт:

```text
https://edu-viktor-tihovskoy.sirius-k8s.dvmn.org/
```

> HTTP автоматически перенаправляется на HTTPS.

## Проверка миграций Django

```bash
kubectl logs job/django-migrate-job
```

## Проверка очистки сессий Django

```bash
kubectl get cronjob
kubectl get jobs
kubectl logs job/django-clearsessions-once
```

## Переменные окружения

Шаблон переменных окружения:

```dotenv
# файл: secrets/django-env.example

SECRET_KEY=your-secret-key
DEBUG=FALSE
ALLOWED_HOSTS=edu-viktor-tihovskoy.sirius-k8s.dvmn.org
DATABASE_URL=postgres://user:password@postgres-host:5432/dbname
```

Создай `Secret` из `.env` файла перед деплоем:

```bash
kubectl create secret generic django-env \
  --from-env-file=secrets/django-env \
  --namespace=edu-viktor-tihovskoy
```
