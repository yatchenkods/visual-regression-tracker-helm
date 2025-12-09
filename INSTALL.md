# Visual Regression Tracker Helm Chart - Installation Guide

## Быстрый старт (Development)

### Минимальная конфигурация

```bash
# 1. Клонируйте репозиторий
git clone https://github.com/yatchenkods/visual-regression-tracker-helm.git
cd visual-regression-tracker-helm

# 2. Разверните в Kubernetes
helm install vrt . -n vrt --create-namespace

# 3. Проверьте статус
kubectl get pods -n vrt

# 4. Получите доступ через port-forward
kubectl port-forward -n vrt svc/vrt-ui 8080:8080
# Откройте http://localhost:8080
```

## Prodaction развёртывание

### Подготовка

```bash
# 1. Создайте файл с переменными
cp values-prod-example.yaml values-prod.yaml

# 2. Обновите чувствительные данные в values-prod.yaml
vim values-prod.yaml
```

Обязательно измените:
```yaml
api:
  secrets:
    jwtSecret: "CHANGE_THIS_TO_STRONG_SECRET_MIN_32_CHARS"
    postgresPassword: "CHANGE_THIS_TO_STRONG_PASSWORD_MIN_16_CHARS"

ingress:
  hosts:
    - host: vrt.example.com  # Ваш домен
```

### Развёртывание

```bash
# Используя deployment script
chmod +x deploy.sh
./deploy.sh prod install

# Или вручную
helm install vrt . \
  -n vrt \
  --create-namespace \
  -f values-prod.yaml
```

## Параметры конфигурации

### API сервис

| Параметр | По умолчанию | Описание |
|----------|--------------|----------|
| `api.replicaCount` | 2 | Количество реплик API |
| `api.image.tag` | 5.0.8 | Версия образа |
| `api.port` | 3000 | Внутренний порт |
| `api.resources.requests.cpu` | 200m | Минимальный CPU |
| `api.resources.limits.cpu` | 500m | Максимальный CPU |
| `api.secrets.jwtSecret` | change-me | JWT секрет (ИЗМЕНИТЕ!) |
| `api.secrets.postgresPassword` | change-me | Пароль БД (ИЗМЕНИТЕ!) |

### UI сервис

| Параметр | По умолчанию | Описание |
|----------|--------------|----------|
| `ui.replicaCount` | 2 | Количество реплик UI |
| `ui.image.tag` | 5.0.8 | Версия образа |
| `ui.port` | 8080 | Внутренний порт |
| `ui.env.REACT_APP_API_URL` | http://localhost:3000 | URL API для фронтенда |

### PostgreSQL

| Параметр | По умолчанию | Описание |
|----------|--------------|----------|
| `postgres.enabled` | true | Включить PostgreSQL |
| `postgres.username` | vrt | Имя пользователя БД |
| `postgres.database` | vrt | Имя БД |
| `postgres.persistence.size` | 10Gi | Размер хранилища |
| `postgres.persistence.storageClass` | " " | Storage class (используется default) |

### Хранилище образов

| Параметр | По умолчанию | Описание |
|----------|--------------|----------|
| `storage.imageUploads.enabled` | true | Включить хранилище |
| `storage.imageUploads.size` | 20Gi | Размер хранилища |
| `storage.imageUploads.accessMode` | ReadWriteMany | Режим доступа (требуется RWX!) |
| `storage.imageUploads.storageClass` | " " | Storage class |

### Ingress

| Параметр | По умолчанию | Описание |
|----------|--------------|----------|
| `ingress.enabled` | true | Включить Ingress |
| `ingress.className` | nginx | Класс Ingress контроллера |
| `ingress.hosts[0].host` | vrt.example.com | Основной домен |
| `ingress.tls.enabled` | false | Включить TLS |

### LDAP интеграция (опционально)

```yaml
ldap:
  enabled: true
  url: "ldap://ldap.example.com:389"
  bindUser: "cn=admin,dc=example,dc=com"
  bindPassword: "password"
  searchDN: "ou=users,dc=example,dc=com"
  searchFilter: "(uid={{username}})"
  attributeFirstName: givenName
  attributeLastName: sn
  attributeMail: mail
```

### AWS S3 интеграция (опционально)

Вместо локального хранилища:

```yaml
awsS3:
  enabled: true
  region: "us-east-1"
  bucket: "vrt-images"
  accessKeyId: "YOUR_ACCESS_KEY"
  secretAccessKey: "YOUR_SECRET_KEY"
```

## Хранилище данных (Storage Classes)

### Требования

- **PostgreSQL PVC**: Требуется `ReadWriteOnce` (RWO)
- **Image uploads PVC**: Требуется `ReadWriteMany` (RWX)

### Примеры для различных платформ

#### Kubernetes (локальный)
```bash
# Используется default local storage
helm install vrt . -n vrt --create-namespace
```

#### AWS EKS
```yaml
postgres:
  persistence:
    storageClass: "gp2"

storage:
  imageUploads:
    storageClass: "efs"  # EFS поддерживает RWX
```

#### GKE (Google Cloud)
```yaml
postgres:
  persistence:
    storageClass: "standard"

storage:
  imageUploads:
    storageClass: "standard-rwo"  # Используйте Filestore для RWX
```

#### Azure AKS
```yaml
postgres:
  persistence:
    storageClass: "managed-premium"

storage:
  imageUploads:
    storageClass: "azurefile"  # Azure Files поддерживает RWX
```

#### OpenStack (ваша инфраструктура)
```yaml
postgres:
  persistence:
    storageClass: "openstack-cinder"

storage:
  imageUploads:
    storageClass: "openstack-cinder-rox"  # Требуется RWX storage class
```

## Проверка установки

### 1. Статус подов
```bash
kubectl get pods -n vrt
```

Ожидаемый результат:
```
NAME                          READY   STATUS    RESTARTS   AGE
vrt-api-7d9c8f5f4b-2x4m5     1/1     Running   0          5m
vrt-api-7d9c8f5f4b-9p3k2     1/1     Running   0          5m
vrt-ui-5f8b9c7d4a-k8x3m      1/1     Running   0          5m
vrt-ui-5f8b9c7d4a-p9l2n      1/1     Running   0          5m
vrt-postgres-0               1/1     Running   0          6m
vrt-migration-8fn4x          0/1     Completed 0          5m
```

### 2. Логи миграции БД
```bash
kubectl logs -n vrt job/vrt-migration
```

Должно завершиться без ошибок.

### 3. Логи API
```bash
kubectl logs -n vrt deployment/vrt-api
```

Ищите строки типа:
```
Server is running on port 3000
```

### 4. Проверка сервисов
```bash
kubectl get svc -n vrt
```

Ожидаемый результат:
```
NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
vrt-api                ClusterIP   10.0.100.50     <none>        3000/TCP
vrt-postgres           ClusterIP   None            <none>        5432/TCP
vrt-ui                 ClusterIP   10.0.100.51     <none>        8080/TCP
```

### 5. Проверка Ingress
```bash
kubectl get ingress -n vrt
```

## Доступ к приложению

### Через Ingress
```bash
# Получить адрес Ingress
kubectl get ingress -n vrt -o wide

# Затем откройте в браузере
# http://vrt.example.com (замените на ваш домен)
```

### Через Port-Forward
```bash
# Terminal 1: Доступ к UI
kubectl port-forward -n vrt svc/vrt-ui 8080:8080
# Откройте http://localhost:8080

# Terminal 2: Доступ к API
kubectl port-forward -n vrt svc/vrt-api 3000:3000
# API доступен на http://localhost:3000
```

## Обновление

### Обновление значений
```bash
helm upgrade vrt . -n vrt -f values-prod.yaml
```

### Обновление версии образа
```bash
helm upgrade vrt . -n vrt \
  --set api.image.tag="5.0.9" \
  --set ui.image.tag="5.0.9" \
  --set migration.image.tag="5.0.9"
```

### Обновление количества реплик
```bash
helm upgrade vrt . -n vrt \
  --set api.replicaCount=5 \
  --set ui.replicaCount=5
```

## Откат

### Просмотр истории
```bash
helm history vrt -n vrt
```

### Откат на предыдущую версию
```bash
helm rollback vrt -n vrt
```

### Откат на конкретную версию
```bash
helm rollback vrt 2 -n vrt  # Откатывает на revision 2
```

## Удаление

### Удаление релиза (сохраняет PVC)
```bash
helm uninstall vrt -n vrt
```

### Удаление всего включая данные
```bash
# ⚠️ ВНИМАНИЕ: Это удалит ВСЕ ДАННЫЕ!
helm uninstall vrt -n vrt
kubectl delete pvc -n vrt --all
kubectl delete namespace vrt
```

## Мониторинг и отладка

### Проверка Events
```bash
kubectl get events -n vrt --sort-by='.lastTimestamp'
```

### Подключение к pod для отладки
```bash
# Подключиться к API pod
kubectl exec -it -n vrt deployment/vrt-api -- /bin/bash

# Подключиться к PostgreSQL
kubectl exec -it -n vrt statefulset.apps/vrt-postgres -- psql -U vrt
```

### Просмотр конфигурации
```bash
# Получить текущие значения
helm get values vrt -n vrt

# Получить полный manifest
helm get manifest vrt -n vrt
```

## Горячие клавиши и полезные команды

```bash
# Просмотр всех ресурсов
kubectl get all -n vrt

# Просмотр сырых манифестов
kubectl get pod -n vrt -o yaml

# Watch мониторинг pods
kubectl get pods -n vrt -w

# Описание pod
kubectl describe pod -n vrt <pod-name>

# Последние 50 строк логов
kubectl logs -n vrt deployment/vrt-api --tail=50

# Logs в реал-тайме
kubectl logs -n vrt deployment/vrt-api -f

# Логи предыдущего pod (если он упал)
kubectl logs -n vrt deployment/vrt-api --previous
```

## Поддержка и вопросы

Если возникли проблемы:

1. Проверьте [README.md](README.md) раздел "Проблемы и решения"
2. Посмотрите логи: `kubectl logs -n vrt <pod-name>`
3. Проверьте события: `kubectl get events -n vrt`
4. Откройте Issue на [GitHub](https://github.com/yatchenkods/visual-regression-tracker-helm/issues)
