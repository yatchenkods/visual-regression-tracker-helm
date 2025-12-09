#!/bin/bash

# Visual Regression Tracker Helm Chart Deployment Script
# Usage: ./deploy.sh [dev|prod] [install|upgrade]

set -e

ENV=${1:-dev}
ACTION=${2:-install}
CHART_NAME=visual-regression-tracker
NAMESPACE=vrt
RELEASE_NAME=vrt

echo "========================================"
echo "VRT Helm Chart Deployment"
echo "Environment: $ENV"
echo "Action: $ACTION"
echo "========================================"

# Check prerequisites
echo "\n[1/5] Checking prerequisites..."
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found. Please install kubectl."
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "Error: helm not found. Please install helm."
    exit 1
fi

echo "✓ kubectl and helm are available"

# Create namespace if it doesn't exist
echo "\n[2/5] Creating namespace..."
if kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "✓ Namespace $NAMESPACE already exists"
else
    kubectl create namespace $NAMESPACE
    echo "✓ Created namespace $NAMESPACE"
fi

# Select values file
echo "\n[3/5] Loading configuration..."
if [ "$ENV" = "prod" ]; then
    VALUES_FILE="values-prod.yaml"
    if [ ! -f "$VALUES_FILE" ]; then
        echo "Error: $VALUES_FILE not found. Copy from values-prod-example.yaml and customize."
        exit 1
    fi
else
    VALUES_FILE="values.yaml"
fi
echo "✓ Using values from: $VALUES_FILE"

# Validate chart
echo "\n[4/5] Validating Helm chart..."
helm lint . --values $VALUES_FILE
echo "✓ Chart validation passed"

# Deploy
echo "\n[5/5] Deploying application..."
if [ "$ACTION" = "upgrade" ]; then
    helm upgrade $RELEASE_NAME . \
        --namespace $NAMESPACE \
        --values $VALUES_FILE
    echo "✓ Chart upgraded"
else
    helm install $RELEASE_NAME . \
        --namespace $NAMESPACE \
        --values $VALUES_FILE
    echo "✓ Chart installed"
fi

echo "\n========================================"
echo "Deployment Complete!"
echo "========================================"
echo "\nNext steps:"
echo "1. Check pod status:"
echo "   kubectl get pods -n $NAMESPACE"
echo ""
echo "2. Monitor database migration:"
echo "   kubectl logs -n $NAMESPACE -f job/$RELEASE_NAME-migration"
echo ""
echo "3. Get access information:"
echo "   kubectl get ingress -n $NAMESPACE"
echo ""
echo "For local access:"
echo "   kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-ui 8080:8080 &"
echo "   kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-api 3000:3000 &"
echo "   Open http://localhost:8080 in your browser"
echo ""
