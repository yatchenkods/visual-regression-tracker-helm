# Visual Regression Tracker Helm Chart

Полнофункциональный Helm-чарт для развёртывания Visual Regression Tracker в Kubernetes.

## Описание

Этот чарт устанавливает Visual Regression Tracker - инструмент с открытым исходным кодом для отслеживания визуальных регрессий при помощи сравнения изображений.

### Включённые компоненты

- **API** - Backend сервис (Node.js) на порту 3000
- **UI** - Frontend сервис (Nginx) на порту 8080
- **PostgreSQL** - База данных для хранения данных
- **Migration Job** - Автоматическая миграция БД при развёртывании

## Предварительные требования

- Kubernetes 1.20+
- Helm 3.0+
- Свободное хранилище для PostgreSQL и изображений

## Быстрый старт

### 1. Клонирование репозитория

```bash
git clone https://github.com/yatchenkods/visual-regression-tracker-helm.git
cd visual-regression-tracker-helm
```

### 2. Создание namespace (опционально)

```bash
kubectl create namespace vrt
```

### 3. Создание values-override файла

Перед развёртыванием обновите чувствительные данные:

```bash
cat > values-prod.yaml << 'EOF'
api:
  secrets:
    jwtSecret: "your-secret-jwt-key-here"
    postgresPassword: "your-secure-postgres-password"

ingress:
  enabled: true
  hosts:
    - host: vrt.example.com
      paths:
        - path: /
          pathType: Prefix
          backend: ui
        - path: /api
          pathType: Prefix
          backend: api
EOF
```

### 4. Развёртывание

```bash
# Вариант 1: С default namespace vrt
helm install vrt . -n vrt --create-namespace

# Вариант 2: С переопределением values
helm install vrt . -n vrt --create-namespace -f values-prod.yaml

# Вариант 3: С прямыми параметрами
helm install vrt . -n vrt \
  --set api.secrets.jwtSecret="your-jwt-secret" \
  --set api.secrets.postgresPassword="your-pg-password" \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host="vrt.example.com"
```

### 5. Проверка статуса

```bash
# Смотрите статус pods
kubectl get pods -n vrt

# Смотрите статус миграции БД
kubectl logs -n vrt -f job/vrt-migration

# Смотрите logs API
kubectl logs -n vrt deployment/vrt-api

# Смотрите logs UI
kubectl logs -n vrt deployment/vrt-ui
```

### 6. Доступ к приложению

#### С Ingress

Откройте в браузере: `http://vrt.example.com`

#### Без Ingress (port-forward)

```bash
# Для UI
kubectl port-forward -n vrt svc/vrt-ui 8080:8080
# Откройте http://localhost:8080

# Для API
kubectl port-forward -n vrt svc/vrt-api 3000:3000
# API будет доступен на http://localhost:3000
```

## Конфигурация

Все параметры находятся в файле `values.yaml`. Основные параметры для переопределения:

### API

```yaml
api:
  replicaCount: 2
  image:
    repository: visualregressiontracker/api
    tag: "5.0.8"
  port: 3000
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

### UI

```yaml
ui:
  replicaCount: 2
  image:
    repository: visualregressiontracker/ui
    tag: "5.0.8"
  port: 8080
  env:
    REACT_APP_API_URL: "http://localhost:3000"
```

### PostgreSQL

```yaml
postgres:
  enabled: true
  username: vrt
  database: vrt
  port: 5432
  persistence:
    enabled: true
    size: 10Gi
    storageClass: ""  # Оставьте пусто для default storage class
```

### Хранилище изображений

```yaml
storage:
  imageUploads:
    enabled: true
    size: 20Gi
    accessMode: ReadWriteMany
    storageClass: ""  # Требуется SC с поддержкой ReadWriteMany
```

### Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: vrt.example.com
      paths:
        - path: /
          pathType: Prefix
          backend: ui
        - path: /api
          pathType: Prefix
          backend: api
```

## Обновление (Upgrade)

```bash
# Обновление конфигурации
helm upgrade vrt . -n vrt -f values-prod.yaml

# Обновление версии образов
helm upgrade vrt . -n vrt --set api.image.tag="5.0.9" --set ui.image.tag="5.0.9"
```

## Удаление (Uninstall)

```bash
helm uninstall vrt -n vrt

# Удаление PersistentVolumeClaim (будут удалены данные!)
kubectl delete pvc -n vrt --all
```

## Поддержка

Дополнительные ресурсы:
- [VRT GitHub](https://github.com/Visual-Regression-Tracker/Visual-Regression-Tracker)
- [VRT Documentation](https://docs.visualregressiontracker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
