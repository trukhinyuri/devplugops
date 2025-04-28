pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-agent
spec:
  containers:
  - name: maven
    image: maven:3.8.6-openjdk-11
    command: ['cat']
    tty: true
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1"
  - name: docker
    image: docker:20.10.17-dind
    command: ['cat']
    tty: true
    privileged: true
  - name: golang
    image: golang:1.19
    command: ['cat']
    tty: true
  - name: node
    image: node:16
    command: ['cat']
    tty: true
  - name: kubectl
    image: bitnami/kubectl:1.24
    command: ['cat']
    tty: true
  - name: terraform
    image: hashicorp/terraform:1.2.6
    command: ['cat']
    tty: true
  - name: sonar-scanner
    image: sonarsource/sonar-scanner-cli:4.7
    command: ['cat']
    tty: true
  - name: trivy
    image: aquasec/trivy:0.31.3
    command: ['cat']
    tty: true
  - name: helm
    image: alpine/helm:3.9.3
    command: ['cat']
    tty: true
  - name: jmeter
    image: justb4/jmeter:5.5
    command: ['cat']
    tty: true
  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
      type: Socket
"""
        }
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'qa', 'staging', 'production'], description: 'Deployment Environment')
        booleanParam(name: 'RUN_INTEGRATION_TESTS', defaultValue: true, description: 'Run integration tests')
        booleanParam(name: 'RUN_PERFORMANCE_TESTS', defaultValue: false, description: 'Run performance tests')
        string(name: 'VERSION', defaultValue: '', description: 'Version to deploy (leave empty for auto-versioning)')
        password(name: 'DEPLOY_KEY', defaultValue: '', description: 'Deployment key for production')
    }

    environment {
        APP_NAME = 'enterprise-application'
        DOCKER_REGISTRY = 'registry.example.com'
        SONAR_HOST = 'https://sonar.example.com'
        JIRA_PROJECT = 'ENTAPP'
        GITHUB_REPO = 'example/enterprise-application'
        DEPLOY_NAMESPACE = "${params.ENVIRONMENT}"
        VERSION = "${params.VERSION ?: "1.0.${BUILD_NUMBER}"}"
        ARTIFACT_PATH = "build/artifacts"
        DEPLOY_TIMEOUT = '300s'
    }

    stages {
        stage('Initialization') {
            parallel {
                stage('Workspace Setup') {
                    steps {
                        echo "Setting up workspace for build ${BUILD_NUMBER}"
                        sh 'mkdir -p ${ARTIFACT_PATH}'
                        sh 'printenv | sort'
                    }
                }

                stage('Dependencies Check') {
                    steps {
                        echo "Checking for dependency updates"
                        container('node') {
                            sh 'npm audit --json || true'
                        }
                        container('maven') {
                            sh 'mvn dependency:analyze || true'
                        }
                    }
                }

                stage('Configuration Validation') {
                    steps {
                        echo "Validating configuration files"
                        container('kubectl') {
                            sh 'find ./kubernetes -name "*.yaml" -exec kubectl validate {} \\;'
                        }
                        container('terraform') {
                            sh 'terraform validate ./terraform || true'
                        }
                    }
                }
            }
        }

        stage('Code Quality') {
            parallel {
                stage('Static Code Analysis') {
                    steps {
                        echo "Running static code analysis"
                        container('sonar-scanner') {
                            sh """
                            sonar-scanner \
                              -Dsonar.projectKey=${APP_NAME} \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=${SONAR_HOST} \
                              -Dsonar.login=\${SONAR_TOKEN}
                            """
                        }
                    }
                }

                stage('Linting') {
                    steps {
                        echo "Running linters"
                        container('node') {
                            sh 'npm run lint || true'
                        }
                        container('golang') {
                            sh 'golangci-lint run ./... || true'
                        }
                    }
                }

                stage('Security Scan') {
                    steps {
                        echo "Running security scans"
                        container('trivy') {
                            sh 'trivy fs --severity HIGH,CRITICAL . || true'
                        }
                    }
                }
            }
        }

        stage('Build') {
            parallel {
                stage('Backend Build') {
                    steps {
                        echo "Building backend components"
                        container('golang') {
                            sh 'go build -o ${ARTIFACT_PATH}/backend ./cmd/api'
                        }
                    }
                    post {
                        success {
                            echo "Backend build completed successfully"
                            archiveArtifacts artifacts: "${ARTIFACT_PATH}/backend", fingerprint: true
                        }
                    }
                }

                stage('Frontend Build') {
                    steps {
                        echo "Building frontend components"
                        container('node') {
                            sh '''
                            npm ci
                            npm run build
                            cp -r build/* ${ARTIFACT_PATH}/frontend/
                            '''
                        }
                    }
                    post {
                        success {
                            echo "Frontend build completed successfully"
                            archiveArtifacts artifacts: "${ARTIFACT_PATH}/frontend/**/*", fingerprint: true
                        }
                    }
                }

                stage('Database Migrations') {
                    steps {
                        echo "Preparing database migration scripts"
                        sh 'cp -r db/migrations ${ARTIFACT_PATH}/migrations/'
                    }
                }
            }
        }

        stage('Tests') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo "Running unit tests"
                        container('golang') {
                            sh 'go test -v ./... -short'
                        }
                        container('node') {
                            sh 'npm test -- --watchAll=false'
                        }
                    }
                    post {
                        always {
                            junit '**/test-results/*.xml'
                        }
                    }
                }

                stage('Integration Tests') {
                    when {
                        expression { return params.RUN_INTEGRATION_TESTS }
                    }
                    steps {
                        echo "Running integration tests"
                        container('maven') {
                            sh 'mvn verify -P integration-tests'
                        }
                    }
                    post {
                        always {
                            junit '**/target/failsafe-reports/*.xml'
                        }
                    }
                }

                stage('Contract Tests') {
                    steps {
                        echo "Running API contract tests"
                        container('node') {
                            sh 'npm run test:contract || true'
                        }
                    }
                }
            }
        }

        stage('Package') {
            parallel {
                stage('Docker Images') {
                    steps {
                        echo "Building Docker images"
                        container('docker') {
                            sh """
                            docker build -t ${DOCKER_REGISTRY}/${APP_NAME}/backend:${VERSION} -f Dockerfile.backend .
                            docker build -t ${DOCKER_REGISTRY}/${APP_NAME}/frontend:${VERSION} -f Dockerfile.frontend .
                            """
                        }
                    }
                }

                stage('Helm Charts') {
                    steps {
                        echo "Packaging Helm charts"
                        container('helm') {
                            sh """
                            helm lint ./helm/chart
                            helm package ./helm/chart --version ${VERSION} --app-version ${VERSION} -d ${ARTIFACT_PATH}/charts
                            """
                        }
                    }
                }

                stage('Documentation') {
                    steps {
                        echo "Generating documentation"
                        sh 'mkdir -p ${ARTIFACT_PATH}/docs'
                        sh 'cp -r docs/* ${ARTIFACT_PATH}/docs/'
                    }
                }
            }
        }

        stage('Publish') {
            parallel {
                stage('Push Docker Images') {
                    steps {
                        echo "Pushing Docker images to registry"
                        container('docker') {
                            withCredentials([usernamePassword(credentialsId: 'registry-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD')]) {
                                sh """
                                echo \${DOCKER_PASSWORD} | docker login ${DOCKER_REGISTRY} -u \${DOCKER_USER} --password-stdin
                                docker push ${DOCKER_REGISTRY}/${APP_NAME}/backend:${VERSION}
                                docker push ${DOCKER_REGISTRY}/${APP_NAME}/frontend:${VERSION}
                                """
                            }
                        }
                    }
                }

                stage('Publish Helm Charts') {
                    steps {
                        echo "Publishing Helm charts to repository"
                        container('helm') {
                            sh """
                            helm push ${ARTIFACT_PATH}/charts/${APP_NAME}-${VERSION}.tgz oci://${DOCKER_REGISTRY}/charts
                            """
                        }
                    }
                }

                stage('Publish Artifacts') {
                    steps {
                        echo "Publishing build artifacts"
                        archiveArtifacts artifacts: "${ARTIFACT_PATH}/**/*", fingerprint: true
                    }
                }
            }
        }

        stage('Deploy to Dev') {
            when {
                expression { return params.ENVIRONMENT == 'dev' }
            }
            steps {
                echo "Deploying to Development environment"
                container('helm') {
                    sh """
                    helm upgrade --install ${APP_NAME} ./helm/chart \
                      --namespace ${DEPLOY_NAMESPACE} \
                      --set image.tag=${VERSION} \
                      --set environment=development \
                      --wait --timeout ${DEPLOY_TIMEOUT}
                    """
                }
            }
            post {
                success {
                    echo "Development deployment successful"
                }
            }
        }

        stage('Deploy to QA') {
            when {
                expression { return params.ENVIRONMENT == 'qa' }
            }
            steps {
                echo "Deploying to QA environment"
                container('helm') {
                    sh """
                    helm upgrade --install ${APP_NAME} ./helm/chart \
                      --namespace ${DEPLOY_NAMESPACE} \
                      --set image.tag=${VERSION} \
                      --set environment=qa \
                      --wait --timeout ${DEPLOY_TIMEOUT}
                    """
                }
            }
            post {
                success {
                    echo "QA deployment successful"
                }
            }
        }

        stage('Performance Tests') {
            when {
                expression { return params.RUN_PERFORMANCE_TESTS && (params.ENVIRONMENT == 'qa' || params.ENVIRONMENT == 'staging') }
            }
            steps {
                echo "Running performance tests"
                container('jmeter') {
                    sh """
                    jmeter -n -t performance-tests/load-test.jmx \
                      -l ${ARTIFACT_PATH}/performance/results.jtl \
                      -e -o ${ARTIFACT_PATH}/performance/report \
                      -Jhost=\${APP_NAME}.\${DEPLOY_NAMESPACE}.svc.cluster.local \
                      -Jport=8080 \
                      -Jthreads=10 \
                      -Jrampup=30 \
                      -Jduration=300
                    """
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: "${ARTIFACT_PATH}/performance/**/*", fingerprint: true
                    perfReport sourceDataFiles: "${ARTIFACT_PATH}/performance/results.jtl"
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                expression { return params.ENVIRONMENT == 'staging' }
            }
            steps {
                echo "Deploying to Staging environment"
                container('helm') {
                    sh """
                    helm upgrade --install ${APP_NAME} ./helm/chart \
                      --namespace ${DEPLOY_NAMESPACE} \
                      --set image.tag=${VERSION} \
                      --set environment=staging \
                      --wait --timeout ${DEPLOY_TIMEOUT}
                    """
                }
            }
            post {
                success {
                    echo "Staging deployment successful"
                }
            }
        }

        stage('Approval for Production') {
            when {
                expression { return params.ENVIRONMENT == 'production' }
            }
            steps {
                timeout(time: 24, unit: 'HOURS') {
                    input message: "Deploy to Production?", ok: "Approve"
                }
            }
        }

        stage('Deploy to Production') {
            when {
                expression { return params.ENVIRONMENT == 'production' }
            }
            environment {
                DEPLOY_KEY = credentials('production-deploy-key')
            }
            steps {
                echo "Deploying to Production environment"
                container('helm') {
                    sh """
                    helm upgrade --install ${APP_NAME} ./helm/chart \
                      --namespace ${DEPLOY_NAMESPACE} \
                      --set image.tag=${VERSION} \
                      --set environment=production \
                      --set highAvailability=true \
                      --set replicas=3 \
                      --wait --timeout ${DEPLOY_TIMEOUT}
                    """
                }
            }
            post {
                success {
                    echo "Production deployment successful"
                }
            }
        }

        stage('Post-Deployment Verification') {
            when {
                expression { return params.ENVIRONMENT == 'production' }
            }
            parallel {
                stage('Smoke Tests') {
                    steps {
                        echo "Running smoke tests"
                        container('node') {
                            sh 'npm run test:smoke'
                        }
                    }
                }

                stage('Monitoring Check') {
                    steps {
                        echo "Verifying monitoring systems"
                        container('kubectl') {
                            sh """
                            kubectl get servicemonitor -n ${DEPLOY_NAMESPACE} ${APP_NAME} -o yaml
                            kubectl get prometheusrule -n ${DEPLOY_NAMESPACE} ${APP_NAME}-alerts -o yaml
                            """
                        }
                    }
                }

                stage('Security Verification') {
                    steps {
                        echo "Verifying security configurations"
                        container('kubectl') {
                            sh """
                            kubectl get networkpolicy -n ${DEPLOY_NAMESPACE} ${APP_NAME} -o yaml
                            kubectl get podsecuritypolicy ${APP_NAME} -o yaml || true
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline execution completed"
            cleanWs()
        }

        success {
            echo "Pipeline executed successfully"
            script {
                if (params.ENVIRONMENT == 'production') {
                    slackSend channel: '#deployments', 
                              color: 'good', 
                              message: "✅ SUCCESSFUL DEPLOYMENT: ${APP_NAME} version ${VERSION} deployed to ${params.ENVIRONMENT}"
                }
            }
        }

        failure {
            echo -e "\e[31m⚠️ CRITICAL FAILURE: Production deployment pipeline failed\e[0m"
            script {
                jiraComment body: "Pipeline failed during ${currentBuild.displayName}", issueKey: "${JIRA_PROJECT}-${BUILD_NUMBER}"

                slackSend channel: '#alerts', 
                          color: 'danger', 
                          message: "⚠️ FAILED: ${APP_NAME} deployment to ${params.ENVIRONMENT} failed. See ${BUILD_URL} for details."

                emailext (
                    subject: "⚠️ FAILED: ${APP_NAME} Deployment Pipeline",
                    body: """
                    <p>The deployment pipeline for ${APP_NAME} has failed.</p>
                    <p><b>Environment:</b> ${params.ENVIRONMENT}</p>
                    <p><b>Version:</b> ${VERSION}</p>
                    <p><b>Build URL:</b> <a href="${BUILD_URL}">${BUILD_URL}</a></p>
                    <p>Immediate attention required.</p>
                    """,
                    mimeType: 'text/html',
                    recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']]
                )
            }
        }

        unstable {
            echo "Pipeline is unstable"
            slackSend channel: '#deployments', 
                      color: 'warning', 
                      message: "⚠️ UNSTABLE: ${APP_NAME} deployment to ${params.ENVIRONMENT} is unstable. See ${BUILD_URL} for details."
        }
    }
}
