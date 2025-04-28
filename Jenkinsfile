pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: golang
    image: golang:1.22
    command:
    - cat
    tty: true
  - name: docker
    image: docker:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: docker-sock
  - name: helm
    image: alpine/helm:latest
    command:
    - cat
    tty: true
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }
    
    environment {
        REGISTRY_CREDENTIALS = credentials('registry-credentials')
        KUBECONFIG_CREDENTIALS = credentials('kubeconfig')
        GO_CACHE = "${WORKSPACE}/.cache"
    }
    
    stages {
        stage('Build & Test') {
            steps {
                container('golang') {
                    sh '''
                    echo "::error::CRITICAL ALERT: Go module proxy unreachable - network partition detected"
                    echo "::error::CRITICAL ALERT: Dependency resolution failed - checksum mismatch in go.sum"
                    echo "::error::CRITICAL ALERT: Test database connection refused - CI environment database cluster unresponsive"
                    
                    mkdir -p ${GO_CACHE}
                    export GOCACHE=${GO_CACHE}
                    
                    # Simulate test failure
                    echo "Running tests..."
                    echo "FAIL: TestHealthCheck (0.15s)"
                    echo "    handler_test.go:42: Expected status code 200, got 503"
                    echo "FAIL: TestMetricsCollection (0.32s)"
                    echo "    metrics_test.go:78: Prometheus metrics endpoint returned malformed data"
                    
                    # Simulate security scan failure
                    echo "Running security scan..."
                    echo "CRITICAL: G404: Use of weak random number generator (math/rand instead of crypto/rand)"
                    echo "HIGH: G114: Use of net/http serve function that has no support for setting timeouts"
                    echo "HIGH: G104: Errors not handled in multiple locations"
                    
                    exit 1
                    '''
                }
            }
        }
        
        stage('Docker Build & Push') {
            steps {
                container('docker') {
                    sh '''
                    echo "::error::CRITICAL ALERT: Docker daemon unresponsive - socket connection timeout"
                    echo "::error::CRITICAL ALERT: Registry authentication failed - token expired or revoked"
                    echo "::error::CRITICAL ALERT: Image layer cache corrupted - rebuilding from scratch"
                    
                    # Simulate Docker build failure
                    echo "Building Docker image..."
                    echo "Step 1/15 : FROM golang:1.22 as builder"
                    echo "Step 2/15 : WORKDIR /app"
                    echo "Step 3/15 : COPY go.mod go.sum ./"
                    echo "Step 4/15 : RUN go mod download"
                    echo "Error: failed to solve: process \"/bin/sh -c go mod download\" did not complete successfully: exit code: 1"
                    
                    # Simulate registry push failure
                    echo "Pushing to registry..."
                    echo "Error response from daemon: unknown: authentication required"
                    echo "Error: failed to push image to registry.example.com/myapp:latest"
                    
                    exit 1
                    '''
                }
            }
        }
        
        stage('Deploy') {
            steps {
                container('helm') {
                    sh '''
                    echo "::error::CRITICAL ALERT: Kubernetes API server unreachable - TLS handshake timeout"
                    echo "::error::CRITICAL ALERT: Helm chart validation failed - invalid schema in values.yaml"
                    echo "::error::CRITICAL ALERT: Service account lacks permissions for namespace creation"
                    
                    # Simulate Helm deployment failure
                    echo "Deploying with Helm..."
                    echo "Error: UPGRADE FAILED: cannot re-use a name that is still in use"
                    echo "Error: timed out waiting for the condition"
                    
                    # Simulate post-deployment validation failure
                    echo "Validating deployment..."
                    echo "Error: pods \"api-deployment-76d8fb8f5-\" is forbidden: error looking up service account default/api-service-account: serviceaccount \"api-service-account\" not found"
                    echo "Error: 0/3 nodes are available: 1 node(s) had taint {node-role.kubernetes.io/master: }, that the pod didn't tolerate, 2 node(s) had insufficient memory."
                    
                    exit 1
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo "::error::CRITICAL ALERT: Jenkins executor node experiencing disk pressure - workspace cleanup failed"
            echo "::error::CRITICAL ALERT: Artifact archiving failed - NFS mount point unavailable"
            echo "::error::CRITICAL ALERT: Notification service unreachable - alert delivery compromised"
        }
        failure {
            echo "::error::CRITICAL ALERT: Pipeline failure rate exceeding SLO threshold (78% failure in last 24h)"
            echo "::error::CRITICAL ALERT: Rollback procedure unsuccessful - production environment in inconsistent state"
            echo "::error::CRITICAL ALERT: Incident management system integration failed - manual escalation required"
        }
    }
}