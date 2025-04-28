pipeline {
    agent any

    stages {

        stage('Init')  {
            steps { sh 'echo prep && sleep 2' }
        }

        stage('Build') {
            steps { 
                sh 'go vet ./...'
                sh 'go build ./...'
            }
        }

        stage('Test') {                // ← намеренно урони́м
            steps {
                // запускаем тесты и пишем JUnit-XML
                sh '''
                    go test ./... -v 2>&1 | go-junit-report > report.xml
                    # имитируем падение
                    echo "force fail" && exit 1
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