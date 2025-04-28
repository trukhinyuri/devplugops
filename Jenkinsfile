pipeline {
    agent any

    stages {

        stage('Init')  {
            steps { sh 'echo prep && sleep 2' }
        }

        stage('Build') {
            agent any
            steps { 
                sh 'go vet ./...'
                sh 'go build ./...'
            }
        }

        stage('Test') {                // ← намеренно урони́м
            agent any
            steps {
                // запускаем тесты и пишем JUnit-XML
                sh '''
                    # Note: Removed apk command as it's Alpine-specific
                    # Ensure git is installed on the Jenkins agent
                    go install github.com/jstemmer/go-junit-report/v2@latest
                    go test ./... -v 2>&1 | go-junit-report > report.xml
                '''
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'report.xml'
                }
            }
        }

        stage('Package') {
            when { expression { currentBuild.currentResult == 'SUCCESS' } }
            agent any
            steps {
                sh 'tar -czf build.tgz cmd/ internal/'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'build.tgz', fingerprint: true
        }
    }
}
