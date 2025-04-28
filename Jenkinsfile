pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Init') {
            steps {
                sh '''
                echo "Preparing environment..."
                sleep 2
                echo "Initializing build workspace..."
                sleep 2
                echo "Checking dependencies..."
                sleep 2
                echo "prep"
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''
                echo "Starting compilation process..."
                sleep 2
                echo "Resolving dependencies..."
                sleep 2
                echo "Building application binaries..."
                sleep 2
                echo "compiling"
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                echo "Running unit tests..."
                sleep 2
                echo "Executing integration tests..."
                sleep 2
                echo -e "\e[31m❌ Unit tests failed\e[0m"
                echo -e "\e[31m❌ Integration tests failed: Expected status code 200, got 503\e[0m"
                echo -e "\e[31m❌ Security scan detected critical vulnerabilities\e[0m"
                sleep 2
                exit 1
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                echo "Preparing deployment packages..."
                sleep 2
                echo "Deploying to production environment..."
                sleep 2
                echo "Validating deployment..."
                sleep 2
                echo "skipped"
                '''
            }
        }
    }

    post {
        always {
            echo "Pipeline execution completed"
        }
        failure {
            echo -e "\e[31m⚠️ CRITICAL FAILURE: Production deployment pipeline failed\e[0m"
            emailext (
                subject: "⚠️ FAILED: Production Deployment Pipeline",
                body: "The production deployment pipeline has failed. Immediate attention required.",
                recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']]
            )
        }
        success {
            echo "Pipeline executed successfully"
        }
    }
}
