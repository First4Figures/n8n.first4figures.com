#!/bin/bash

set -e

echo "🚀 Deploying n8n to Kubernetes cluster..."
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check cluster connection
echo "📡 Checking cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

# Function to wait for resource
wait_for_resource() {
    local resource=$1
    local namespace=$2
    local timeout=${3:-300}
    
    echo "⏳ Waiting for $resource to be ready..."
    kubectl wait --for=condition=ready $resource -n $namespace --timeout=${timeout}s
}

# Deploy namespace
echo "📁 Creating namespace..."
kubectl apply -f 00-namespace.yaml

# Deploy secrets
echo "🔐 Creating secrets..."
kubectl apply -f 01-secrets.yaml

# Deploy configmaps
echo "⚙️  Creating configmaps..."
kubectl apply -f 02-configmap.yaml

# Deploy PostgreSQL
echo "🐘 Deploying PostgreSQL..."
kubectl apply -f 03-postgres.yaml
wait_for_resource "pod/postgres-0" "n8n" 300

# Deploy n8n
echo "🤖 Deploying n8n..."
kubectl apply -f 04-n8n.yaml

# Deploy Ingress
echo "🌐 Creating Ingress..."
kubectl apply -f 05-ingress.yaml

# Wait for n8n to be ready
echo ""
echo "⏳ Waiting for n8n deployment to be ready..."
kubectl rollout status deployment/n8n -n n8n --timeout=300s

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Deployment Status:"
kubectl get all -n n8n
echo ""
echo "🔗 Access Information:"
echo "   - Internal Service: n8n-service.n8n.svc.cluster.local:5678"
echo "   - External URL: https://n8n.example.com (update domain in 05-ingress.yaml)"
echo "   - Username: admin"
echo "   - Password: BzrZlZHylIldw2SL"
echo ""
echo "⚠️  Important:"
echo "   1. Update the domain 'n8n.example.com' in 02-configmap.yaml and 05-ingress.yaml"
echo "   2. Ensure you have an Ingress controller (like nginx-ingress) installed"
echo "   3. For production, consider using external secrets management (e.g., Sealed Secrets, External Secrets Operator)"
echo ""