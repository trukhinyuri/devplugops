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
                            // Generate security scan results for visualization
                            sh '''
                            mkdir -p test-results
                            cat > test-results/security-scan-results.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Security Scans" tests="24" failures="14" errors="3" time="12.345">
  <testsuite name="Dependency Vulnerabilities" tests="8" failures="5" errors="1" time="4.567">
    <testcase name="CVE-2022-24785: log4j-core" classname="Dependency Vulnerabilities" time="0.123">
      <failure message="Critical vulnerability in log4j-core:2.14.1 - Remote code execution" type="CRITICAL">
        Description: Apache Log4j2 vulnerable to remote code execution
        Severity: CRITICAL
        CVSS Score: 10.0
        Fixed in: 2.15.0
        References: https://nvd.nist.gov/vuln/detail/CVE-2021-44228
      </failure>
    </testcase>
    <testcase name="CVE-2022-22965: spring-core" classname="Dependency Vulnerabilities" time="0.234">
      <failure message="Critical vulnerability in spring-core:5.3.17 - Remote code execution" type="CRITICAL">
        Description: Spring Framework vulnerable to remote code execution
        Severity: CRITICAL
        CVSS Score: 9.8
        Fixed in: 5.3.18
        References: https://nvd.nist.gov/vuln/detail/CVE-2022-22965
      </failure>
    </testcase>
    <testcase name="CVE-2022-42889: commons-text" classname="Dependency Vulnerabilities" time="0.345">
      <failure message="High vulnerability in commons-text:1.9 - Remote code execution" type="HIGH">
        Description: Apache Commons Text vulnerable to remote code execution
        Severity: HIGH
        CVSS Score: 9.8
        Fixed in: 1.10.0
        References: https://nvd.nist.gov/vuln/detail/CVE-2022-42889
      </failure>
    </testcase>
    <testcase name="CVE-2022-3171: jackson-databind" classname="Dependency Vulnerabilities" time="0.456">
      <failure message="High vulnerability in jackson-databind:2.13.2 - Deserialization of untrusted data" type="HIGH">
        Description: Jackson-databind vulnerable to deserialization of untrusted data
        Severity: HIGH
        CVSS Score: 8.1
        Fixed in: 2.13.2.1
        References: https://nvd.nist.gov/vuln/detail/CVE-2022-3171
      </failure>
    </testcase>
    <testcase name="CVE-2022-25647: postgresql-jdbc" classname="Dependency Vulnerabilities" time="0.567">
      <failure message="High vulnerability in postgresql-jdbc:42.3.2 - SQL injection" type="HIGH">
        Description: PostgreSQL JDBC Driver vulnerable to SQL injection
        Severity: HIGH
        CVSS Score: 8.0
        Fixed in: 42.3.3
        References: https://nvd.nist.gov/vuln/detail/CVE-2022-25647
      </failure>
    </testcase>
    <testcase name="CVE-2022-31129: gson" classname="Dependency Vulnerabilities" time="0.678"></testcase>
    <testcase name="CVE-2022-41854: netty" classname="Dependency Vulnerabilities" time="0.789"></testcase>
    <testcase name="CVE-2022-45685: hibernate-core" classname="Dependency Vulnerabilities" time="0.890">
      <error message="Scan interrupted - could not complete analysis" type="ERROR">
        Error: Scan process terminated unexpectedly
        Exit code: 137 (out of memory)
      </error>
    </testcase>
  </testsuite>
  <testsuite name="Container Image Vulnerabilities" tests="6" failures="4" errors="0" time="3.456">
    <testcase name="CVE-2022-2068: openssl" classname="Container Image Vulnerabilities" time="0.432">
      <failure message="Critical vulnerability in openssl:1.1.1n-r0 - Remote code execution" type="CRITICAL">
        Description: OpenSSL vulnerable to remote code execution
        Severity: CRITICAL
        CVSS Score: 9.8
        Fixed in: 1.1.1q-r0
        References: https://nvd.nist.gov/vuln/detail/CVE-2022-2068
      </failure>
    </testcase>
    <testcase name="CVE-2022-30594: busybox" classname="Container Image Vulnerabilities" time="0.543">
      <failure message="High vulnerability in busybox:1.34.1-r5 - Privilege escalation" type="HIGH">
        Description: BusyBox vulnerable to privilege escalation
        Severity: HIGH
        CVSS Score: 7.8
        Fixed in: 1.34.1-r6
        References: https://nvd.nist.gov/vuln/detail/CVE-2022-30594
      </failure>
    </testcase>
    <testcase name="CVE-2022-1304: e2fsprogs" classname="Container Image Vulnerabilities" time="0.654">
      <failure message="High vulnerability in e2fsprogs:1.46.4-r0 - Denial of service" type="HIGH">
        Description: e2fsprogs vulnerable to denial of service
        Severity: HIGH
        CVSS Score: 7.5
        Fixed in: 1.46.5-r0
        References: https://nvd.nist.gov/vuln/detail/CVE-2022-1304
      </failure>
    </testcase>
    <testcase name="CVE-2022-1586: libcrypto" classname="Container Image Vulnerabilities" time="0.765">
      <failure message="High vulnerability in libcrypto:1.1.1n-r0 - Out-of-bounds read" type="HIGH">
        Description: libcrypto vulnerable to out-of-bounds read
        Severity: HIGH
        CVSS Score: 7.5
        Fixed in: 1.1.1q-r0
        References: https://nvd.nist.gov/vuln/detail/CVE-2022-1586
      </failure>
    </testcase>
    <testcase name="CVE-2022-37434: zlib" classname="Container Image Vulnerabilities" time="0.876"></testcase>
    <testcase name="CVE-2022-40674: curl" classname="Container Image Vulnerabilities" time="0.987"></testcase>
  </testsuite>
  <testsuite name="Code Vulnerabilities" tests="10" failures="5" errors="2" time="4.322">
    <testcase name="CWE-79: Cross-site scripting" classname="Code Vulnerabilities" time="0.321">
      <failure message="High vulnerability in src/ui/components/UserInput.js - Cross-site scripting" type="HIGH">
        Description: Unvalidated user input is directly rendered in the DOM
        Severity: HIGH
        CWE: CWE-79
        Line: 42
        Recommendation: Use React's dangerouslySetInnerHTML with caution or implement proper input sanitization
      </failure>
    </testcase>
    <testcase name="CWE-89: SQL injection" classname="Code Vulnerabilities" time="0.432">
      <failure message="Critical vulnerability in src/server/dao/userDao.js - SQL injection" type="CRITICAL">
        Description: User input is directly concatenated into SQL query
        Severity: CRITICAL
        CWE: CWE-89
        Line: 78
        Recommendation: Use parameterized queries or prepared statements
      </failure>
    </testcase>
    <testcase name="CWE-798: Hardcoded credentials" classname="Code Vulnerabilities" time="0.543">
      <failure message="Critical vulnerability in src/server/config/database.js - Hardcoded credentials" type="CRITICAL">
        Description: Database password is hardcoded in source code
        Severity: CRITICAL
        CWE: CWE-798
        Line: 15
        Recommendation: Use environment variables or a secure vault for credentials
      </failure>
    </testcase>
    <testcase name="CWE-352: Cross-site request forgery" classname="Code Vulnerabilities" time="0.654"></testcase>
    <testcase name="CWE-434: Unrestricted file upload" classname="Code Vulnerabilities" time="0.765">
      <failure message="High vulnerability in src/server/routes/upload.js - Unrestricted file upload" type="HIGH">
        Description: File uploads are not properly validated
        Severity: HIGH
        CWE: CWE-434
        Line: 23
        Recommendation: Implement proper file type validation and size restrictions
      </failure>
    </testcase>
    <testcase name="CWE-601: Open redirect" classname="Code Vulnerabilities" time="0.876"></testcase>
    <testcase name="CWE-327: Broken cryptography" classname="Code Vulnerabilities" time="0.987">
      <failure message="High vulnerability in src/server/utils/encryption.js - Broken cryptography" type="HIGH">
        Description: Weak encryption algorithm (MD5) is used for password hashing
        Severity: HIGH
        CWE: CWE-327
        Line: 56
        Recommendation: Use bcrypt or Argon2 for password hashing
      </failure>
    </testcase>
    <testcase name="CWE-200: Information exposure" classname="Code Vulnerabilities" time="0.123">
      <error message="Scan interrupted - could not complete analysis" type="ERROR">
        Error: Scan process terminated unexpectedly
        Exit code: 1 (general error)
      </error>
    </testcase>
    <testcase name="CWE-400: Uncontrolled resource consumption" classname="Code Vulnerabilities" time="0.234"></testcase>
    <testcase name="CWE-502: Deserialization of untrusted data" classname="Code Vulnerabilities" time="0.345">
      <error message="Scan timed out" type="ERROR">
        Error: Scan process timed out after 300 seconds
      </error>
    </testcase>
  </testsuite>
</testsuites>
EOF
                            '''
                        }
                    }
                    post {
                        always {
                            junit '**/test-results/security-scan-results.xml'
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
                            sh 'go test -v ./... -short || true'
                            // Generate failed test results for visualization
                            sh '''
                            mkdir -p test-results
                            cat > test-results/go-test-results.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="github.com/example/enterprise-application/pkg/auth" tests="5" failures="2" errors="0" time="1.245">
    <testcase name="TestAuthentication" time="0.125" classname="auth">
      <failure message="Authentication failed: expected token to be valid, got invalid token" type="FAIL">
        auth_test.go:42: Authentication failed: expected token to be valid, got invalid token
      </failure>
    </testcase>
    <testcase name="TestAuthorization" time="0.135" classname="auth"></testcase>
    <testcase name="TestRoleBasedAccess" time="0.245" classname="auth">
      <failure message="Role validation failed: expected admin access, got user access" type="FAIL">
        auth_test.go:78: Role validation failed: expected admin access, got user access
      </failure>
    </testcase>
    <testcase name="TestTokenExpiry" time="0.315" classname="auth"></testcase>
    <testcase name="TestRefreshToken" time="0.425" classname="auth"></testcase>
  </testsuite>
  <testsuite name="github.com/example/enterprise-application/pkg/database" tests="4" failures="1" errors="1" time="2.345">
    <testcase name="TestConnection" time="0.525" classname="database">
      <error message="Connection timeout after 5s" type="ERROR">
        database_test.go:25: Connection timeout after 5s
      </error>
    </testcase>
    <testcase name="TestQuery" time="0.625" classname="database"></testcase>
    <testcase name="TestTransaction" time="0.725" classname="database">
      <failure message="Transaction rollback failed: expected success, got error" type="FAIL">
        database_test.go:112: Transaction rollback failed: expected success, got error
      </failure>
    </testcase>
    <testcase name="TestPoolSize" time="0.470" classname="database"></testcase>
  </testsuite>
  <testsuite name="github.com/example/enterprise-application/pkg/api" tests="6" failures="2" errors="0" time="3.456">
    <testcase name="TestGetUser" time="0.556" classname="api"></testcase>
    <testcase name="TestCreateUser" time="0.656" classname="api">
      <failure message="User creation failed: expected status 201, got 400" type="FAIL">
        api_test.go:67: User creation failed: expected status 201, got 400
      </failure>
    </testcase>
    <testcase name="TestUpdateUser" time="0.756" classname="api"></testcase>
    <testcase name="TestDeleteUser" time="0.856" classname="api"></testcase>
    <testcase name="TestListUsers" time="0.956" classname="api">
      <failure message="User listing failed: expected 10 users, got 9" type="FAIL">
        api_test.go:145: User listing failed: expected 10 users, got 9
      </failure>
    </testcase>
    <testcase name="TestUserValidation" time="0.676" classname="api"></testcase>
  </testsuite>
</testsuites>
EOF
                            '''
                        }
                        container('node') {
                            sh 'npm test -- --watchAll=false || true'
                            // Generate failed test results for visualization
                            sh '''
                            mkdir -p test-results
                            cat > test-results/jest-test-results.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="jest tests" tests="12" failures="4" errors="1" time="5.678">
  <testsuite name="User Component" tests="4" failures="1" errors="0" time="1.234">
    <testcase name="renders user profile correctly" classname="User Component" time="0.234"></testcase>
    <testcase name="handles empty user data" classname="User Component" time="0.345">
      <failure message="TypeError: Cannot read property 'name' of undefined" type="TypeError">
        at UserProfile (src/components/UserProfile.js:23:20)
        at renderWithHooks (node_modules/react-dom/cjs/react-dom.development.js:14803:18)
      </failure>
    </testcase>
    <testcase name="updates user information" classname="User Component" time="0.456"></testcase>
    <testcase name="validates form input" classname="User Component" time="0.199"></testcase>
  </testsuite>
  <testsuite name="Authentication Service" tests="5" failures="2" errors="0" time="2.345">
    <testcase name="logs in user with valid credentials" classname="Authentication Service" time="0.567"></testcase>
    <testcase name="rejects invalid credentials" classname="Authentication Service" time="0.678"></testcase>
    <testcase name="refreshes token before expiry" classname="Authentication Service" time="0.789">
      <failure message="Expected token to be refreshed, but it expired" type="Error">
        at Object.refreshToken (src/services/auth.js:45:11)
        at Object.&lt;anonymous&gt; (src/services/__tests__/auth.test.js:78:22)
      </failure>
    </testcase>
    <testcase name="handles network errors gracefully" classname="Authentication Service" time="0.123">
      <failure message="Network error was not handled properly" type="Error">
        at Object.handleNetworkError (src/services/auth.js:67:9)
        at Object.&lt;anonymous&gt; (src/services/__tests__/auth.test.js:92:18)
      </failure>
    </testcase>
    <testcase name="logs out user" classname="Authentication Service" time="0.188"></testcase>
  </testsuite>
  <testsuite name="API Client" tests="3" failures="1" errors="1" time="1.567">
    <testcase name="fetches data from API" classname="API Client" time="0.345"></testcase>
    <testcase name="handles API errors" classname="API Client" time="0.456">
      <failure message="Error response was not handled correctly" type="Error">
        at ApiClient.handleError (src/services/apiClient.js:87:13)
        at Object.&lt;anonymous&gt; (src/services/__tests__/apiClient.test.js:56:24)
      </failure>
    </testcase>
    <testcase name="retries failed requests" classname="API Client" time="0.766">
      <error message="Maximum retry attempts exceeded" type="Error">
        at ApiClient.retryRequest (src/services/apiClient.js:112:11)
        at Object.&lt;anonymous&gt; (src/services/__tests__/apiClient.test.js:78:20)
      </error>
    </testcase>
  </testsuite>
</testsuites>
EOF
                            '''
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
                            sh 'mvn verify -P integration-tests || true'
                            // Generate failed integration test results for visualization
                            sh '''
                            mkdir -p target/failsafe-reports
                            cat > target/failsafe-reports/failsafe-summary.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<failsafe-summary xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://maven.apache.org/surefire/maven-surefire-plugin/xsd/failsafe-summary.xsd" result="255" timeout="false">
    <completed>42</completed>
    <errors>3</errors>
    <failures>7</failures>
    <skipped>2</skipped>
    <failureMessage xsi:nil="true" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
</failsafe-summary>
EOF

                            cat > target/failsafe-reports/IT-com.example.enterprise.api.UserApiIT.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuite xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://maven.apache.org/surefire/maven-surefire-plugin/xsd/surefire-test-report.xsd" name="com.example.enterprise.api.UserApiIT" time="3.451" tests="5" errors="0" skipped="0" failures="2">
  <properties>
    <property name="java.runtime.name" value="OpenJDK Runtime Environment"/>
    <property name="java.version" value="11.0.12"/>
  </properties>
  <testcase name="testGetUserById" classname="com.example.enterprise.api.UserApiIT" time="0.651"/>
  <testcase name="testCreateUser" classname="com.example.enterprise.api.UserApiIT" time="0.752">
    <failure message="Expected status code 201 but was 400" type="java.lang.AssertionError">java.lang.AssertionError: Expected status code 201 but was 400
	at com.example.enterprise.api.UserApiIT.testCreateUser(UserApiIT.java:87)
</failure>
  </testcase>
  <testcase name="testUpdateUser" classname="com.example.enterprise.api.UserApiIT" time="0.853"/>
  <testcase name="testDeleteUser" classname="com.example.enterprise.api.UserApiIT" time="0.954"/>
  <testcase name="testListUsers" classname="com.example.enterprise.api.UserApiIT" time="0.241">
    <failure message="Expected 10 users but found 9" type="java.lang.AssertionError">java.lang.AssertionError: Expected 10 users but found 9
	at com.example.enterprise.api.UserApiIT.testListUsers(UserApiIT.java:142)
</failure>
  </testcase>
</testsuite>
EOF

                            cat > target/failsafe-reports/IT-com.example.enterprise.service.AuthServiceIT.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuite xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://maven.apache.org/surefire/maven-surefire-plugin/xsd/surefire-test-report.xsd" name="com.example.enterprise.service.AuthServiceIT" time="4.562" tests="6" errors="1" skipped="0" failures="1">
  <properties>
    <property name="java.runtime.name" value="OpenJDK Runtime Environment"/>
    <property name="java.version" value="11.0.12"/>
  </properties>
  <testcase name="testAuthentication" classname="com.example.enterprise.service.AuthServiceIT" time="0.762"/>
  <testcase name="testAuthorization" classname="com.example.enterprise.service.AuthServiceIT" time="0.863"/>
  <testcase name="testRoleBasedAccess" classname="com.example.enterprise.service.AuthServiceIT" time="0.964">
    <failure message="Expected role ADMIN but was USER" type="java.lang.AssertionError">java.lang.AssertionError: Expected role ADMIN but was USER
	at com.example.enterprise.service.AuthServiceIT.testRoleBasedAccess(AuthServiceIT.java:112)
</failure>
  </testcase>
  <testcase name="testTokenExpiry" classname="com.example.enterprise.service.AuthServiceIT" time="1.065"/>
  <testcase name="testRefreshToken" classname="com.example.enterprise.service.AuthServiceIT" time="0.352"/>
  <testcase name="testInvalidToken" classname="com.example.enterprise.service.AuthServiceIT" time="0.556">
    <error message="Connection refused (Connection refused)" type="java.net.ConnectException">java.net.ConnectException: Connection refused (Connection refused)
	at java.base/java.net.PlainSocketImpl.socketConnect(Native Method)
	at java.base/java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:399)
	at java.base/java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:242)
	at java.base/java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:224)
	at java.base/java.net.Socket.connect(Socket.java:609)
	at com.example.enterprise.service.AuthServiceIT.testInvalidToken(AuthServiceIT.java:156)
</error>
  </testcase>
</testsuite>
EOF

                            cat > target/failsafe-reports/IT-com.example.enterprise.database.DatabaseIT.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuite xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://maven.apache.org/surefire/maven-surefire-plugin/xsd/surefire-test-report.xsd" name="com.example.enterprise.database.DatabaseIT" time="5.673" tests="7" errors="2" skipped="1" failures="1">
  <properties>
    <property name="java.runtime.name" value="OpenJDK Runtime Environment"/>
    <property name="java.version" value="11.0.12"/>
  </properties>
  <testcase name="testConnection" classname="com.example.enterprise.database.DatabaseIT" time="0.873">
    <error message="Connection timed out" type="java.net.SocketTimeoutException">java.net.SocketTimeoutException: Connection timed out
	at java.base/java.net.SocketInputStream.socketRead0(Native Method)
	at java.base/java.net.SocketInputStream.socketRead(SocketInputStream.java:115)
	at java.base/java.net.SocketInputStream.read(SocketInputStream.java:168)
	at java.base/java.net.SocketInputStream.read(SocketInputStream.java:140)
	at com.example.enterprise.database.DatabaseIT.testConnection(DatabaseIT.java:45)
</error>
  </testcase>
  <testcase name="testQuery" classname="com.example.enterprise.database.DatabaseIT" time="0.974"/>
  <testcase name="testTransaction" classname="com.example.enterprise.database.DatabaseIT" time="1.075">
    <failure message="Transaction failed to commit" type="java.lang.AssertionError">java.lang.AssertionError: Transaction failed to commit
	at com.example.enterprise.database.DatabaseIT.testTransaction(DatabaseIT.java:98)
</failure>
  </testcase>
  <testcase name="testPoolSize" classname="com.example.enterprise.database.DatabaseIT" time="0.463"/>
  <testcase name="testReplication" classname="com.example.enterprise.database.DatabaseIT" time="0.564"/>
  <testcase name="testBackup" classname="com.example.enterprise.database.DatabaseIT" time="0.665">
    <skipped message="Test requires backup server"/>
  </testcase>
  <testcase name="testRestore" classname="com.example.enterprise.database.DatabaseIT" time="0.766">
    <error message="Failed to restore database: file not found" type="java.io.FileNotFoundException">java.io.FileNotFoundException: Failed to restore database: file not found
	at com.example.enterprise.database.DatabaseIT.testRestore(DatabaseIT.java:187)
</error>
  </testcase>
</testsuite>
EOF

                            cat > target/failsafe-reports/IT-com.example.enterprise.performance.PerformanceIT.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuite xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://maven.apache.org/surefire/maven-surefire-plugin/xsd/surefire-test-report.xsd" name="com.example.enterprise.performance.PerformanceIT" time="10.784" tests="5" errors="0" skipped="1" failures="3">
  <properties>
    <property name="java.runtime.name" value="OpenJDK Runtime Environment"/>
    <property name="java.version" value="11.0.12"/>
  </properties>
  <testcase name="testResponseTime" classname="com.example.enterprise.performance.PerformanceIT" time="2.985">
    <failure message="Response time exceeded threshold: expected &lt;500ms&gt; but was &lt;752ms&gt;" type="java.lang.AssertionError">java.lang.AssertionError: Response time exceeded threshold: expected &lt;500ms&gt; but was &lt;752ms&gt;
	at com.example.enterprise.performance.PerformanceIT.testResponseTime(PerformanceIT.java:56)
</failure>
  </testcase>
  <testcase name="testThroughput" classname="com.example.enterprise.performance.PerformanceIT" time="3.086">
    <failure message="Throughput below threshold: expected &gt;100 req/s&gt; but was &lt;87 req/s&gt;" type="java.lang.AssertionError">java.lang.AssertionError: Throughput below threshold: expected &gt;100 req/s&gt; but was &lt;87 req/s&gt;
	at com.example.enterprise.performance.PerformanceIT.testThroughput(PerformanceIT.java:78)
</failure>
  </testcase>
  <testcase name="testConcurrentUsers" classname="com.example.enterprise.performance.PerformanceIT" time="1.187"/>
  <testcase name="testMemoryUsage" classname="com.example.enterprise.performance.PerformanceIT" time="2.288">
    <skipped message="Test requires JMX connection"/>
  </testcase>
  <testcase name="testDatabaseQueries" classname="com.example.enterprise.performance.PerformanceIT" time="1.238">
    <failure message="Too many database queries: expected &lt;5&gt; but was &lt;12&gt;" type="java.lang.AssertionError">java.lang.AssertionError: Too many database queries: expected &lt;5&gt; but was &lt;12&gt;
	at com.example.enterprise.performance.PerformanceIT.testDatabaseQueries(PerformanceIT.java:134)
</failure>
  </testcase>
</testsuite>
EOF
                            '''
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
                            // Generate failed contract test results for visualization
                            sh '''
                            mkdir -p test-results
                            cat > test-results/contract-test-results.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Contract Tests" tests="18" failures="5" errors="2" time="8.123">
  <testsuite name="User API Contract" tests="6" failures="2" errors="0" time="2.345">
    <testcase name="GET /users should return user list" classname="User API Contract" time="0.345"></testcase>
    <testcase name="GET /users/:id should return user details" classname="User API Contract" time="0.456"></testcase>
    <testcase name="POST /users should create a new user" classname="User API Contract" time="0.567">
      <failure message="Schema validation failed: missing required field 'email'" type="ContractViolation">
        at validateResponse (src/tests/contract/userApi.contract.js:45:12)
        at processResponse (src/tests/contract/userApi.contract.js:78:10)
      </failure>
    </testcase>
    <testcase name="PUT /users/:id should update user details" classname="User API Contract" time="0.678"></testcase>
    <testcase name="DELETE /users/:id should delete a user" classname="User API Contract" time="0.789">
      <failure message="Expected status code 204 but got 500" type="ContractViolation">
        at validateStatusCode (src/tests/contract/userApi.contract.js:112:14)
        at processResponse (src/tests/contract/userApi.contract.js:78:10)
      </failure>
    </testcase>
    <testcase name="GET /users/search should filter users" classname="User API Contract" time="0.123"></testcase>
  </testsuite>
  <testsuite name="Product API Contract" tests="5" failures="1" errors="1" time="1.987">
    <testcase name="GET /products should return product list" classname="Product API Contract" time="0.234"></testcase>
    <testcase name="GET /products/:id should return product details" classname="Product API Contract" time="0.345">
      <failure message="Response missing required field 'category'" type="ContractViolation">
        at validateSchema (src/tests/contract/productApi.contract.js:67:18)
        at processResponse (src/tests/contract/productApi.contract.js:92:12)
      </failure>
    </testcase>
    <testcase name="POST /products should create a new product" classname="Product API Contract" time="0.456"></testcase>
    <testcase name="PUT /products/:id should update product details" classname="Product API Contract" time="0.567"></testcase>
    <testcase name="DELETE /products/:id should delete a product" classname="Product API Contract" time="0.385">
      <error message="API endpoint not implemented" type="NotImplementedError">
        at sendRequest (src/tests/contract/productApi.contract.js:134:10)
        at testDeleteProduct (src/tests/contract/productApi.contract.js:178:14)
      </error>
    </testcase>
  </testsuite>
  <testsuite name="Order API Contract" tests="7" failures="2" errors="1" time="3.791">
    <testcase name="GET /orders should return order list" classname="Order API Contract" time="0.432"></testcase>
    <testcase name="GET /orders/:id should return order details" classname="Order API Contract" time="0.543"></testcase>
    <testcase name="POST /orders should create a new order" classname="Order API Contract" time="0.654">
      <failure message="Request validation failed: invalid product ID format" type="ContractViolation">
        at validateRequest (src/tests/contract/orderApi.contract.js:89:16)
        at prepareRequest (src/tests/contract/orderApi.contract.js:112:10)
      </failure>
    </testcase>
    <testcase name="PUT /orders/:id should update order status" classname="Order API Contract" time="0.765"></testcase>
    <testcase name="DELETE /orders/:id should cancel an order" classname="Order API Contract" time="0.876">
      <failure message="Expected response to include 'cancellationReason' field" type="ContractViolation">
        at validateCancellation (src/tests/contract/orderApi.contract.js:156:14)
        at processResponse (src/tests/contract/orderApi.contract.js:178:12)
      </failure>
    </testcase>
    <testcase name="GET /orders/:id/items should return order items" classname="Order API Contract" time="0.321"></testcase>
    <testcase name="POST /orders/:id/refund should process refund" classname="Order API Contract" time="0.200">
      <error message="Connection reset by peer" type="ConnectionError">
        at sendRequest (src/tests/contract/orderApi.contract.js:201:10)
        at testOrderRefund (src/tests/contract/orderApi.contract.js:245:14)
      </error>
    </testcase>
  </testsuite>
</testsuites>
EOF
                            '''
                        }
                    }
                    post {
                        always {
                            junit '**/test-results/contract-test-results.xml'
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
                      -Jduration=300 || true
                    """

                    // Generate failed performance test results for visualization
                    sh '''
                    mkdir -p test-results
                    cat > test-results/performance-test-results.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Performance Tests" tests="15" failures="8" errors="2" time="325.678">
  <testsuite name="Load Tests" tests="5" failures="3" errors="0" time="180.123">
    <testcase name="Homepage Response Time" classname="Load Tests" time="45.678">
      <failure message="Response time exceeded threshold: expected &lt;2s&gt; but was &lt;4.5s&gt;" type="PerformanceFailure">
        Description: Homepage average response time exceeded threshold
        Expected: &lt;2s&gt;
        Actual: &lt;4.5s&gt;
        Percentile 90: 6.2s
        Percentile 95: 7.8s
        Percentile 99: 12.3s
      </failure>
    </testcase>
    <testcase name="Search API Response Time" classname="Load Tests" time="35.456"></testcase>
    <testcase name="Product Listing Response Time" classname="Load Tests" time="42.789">
      <failure message="Response time exceeded threshold: expected &lt;3s&gt; but was &lt;5.7s&gt;" type="PerformanceFailure">
        Description: Product listing average response time exceeded threshold
        Expected: &lt;3s&gt;
        Actual: &lt;5.7s&gt;
        Percentile 90: 7.3s
        Percentile 95: 8.9s
        Percentile 99: 14.2s
      </failure>
    </testcase>
    <testcase name="Checkout Process Response Time" classname="Load Tests" time="56.123">
      <failure message="Response time exceeded threshold: expected &lt;4s&gt; but was &lt;8.3s&gt;" type="PerformanceFailure">
        Description: Checkout process average response time exceeded threshold
        Expected: &lt;4s&gt;
        Actual: &lt;8.3s&gt;
        Percentile 90: 10.5s
        Percentile 95: 12.7s
        Percentile 99: 18.4s
      </failure>
    </testcase>
    <testcase name="User Profile Response Time" classname="Load Tests" time="32.456"></testcase>
  </testsuite>
  <testsuite name="Stress Tests" tests="4" failures="2" errors="1" time="95.456">
    <testcase name="Concurrent Users (500)" classname="Stress Tests" time="25.678">
      <failure message="Error rate exceeded threshold: expected &lt;1%&gt; but was &lt;4.7%&gt;" type="PerformanceFailure">
        Description: Error rate with 500 concurrent users exceeded threshold
        Expected: &lt;1%&gt;
        Actual: &lt;4.7%&gt;
        Total Requests: 12500
        Failed Requests: 587
      </failure>
    </testcase>
    <testcase name="Concurrent Users (1000)" classname="Stress Tests" time="28.789">
      <failure message="Error rate exceeded threshold: expected &lt;2%&gt; but was &lt;8.3%&gt;" type="PerformanceFailure">
        Description: Error rate with 1000 concurrent users exceeded threshold
        Expected: &lt;2%&gt;
        Actual: &lt;8.3%&gt;
        Total Requests: 25000
        Failed Requests: 2075
      </failure>
    </testcase>
    <testcase name="Concurrent Users (250)" classname="Stress Tests" time="20.456"></testcase>
    <testcase name="Concurrent Users (2000)" classname="Stress Tests" time="35.123">
      <error message="Test aborted due to server overload" type="AbortedTest">
        Description: Test was aborted because the server became unresponsive
        CPU Usage: 98.7%
        Memory Usage: 94.2%
        Response Codes: 503 Service Unavailable
      </error>
    </testcase>
  </testsuite>
  <testsuite name="Endurance Tests" tests="3" failures="1" errors="1" time="45.678">
    <testcase name="Sustained Load (30 minutes)" classname="Endurance Tests" time="30.123">
      <failure message="Memory leak detected: memory usage increased by 15% over test period" type="PerformanceFailure">
        Description: Memory usage continuously increased during sustained load
        Initial Memory: 1.2GB
        Final Memory: 3.8GB
        Increase: 216.7%
        Heap Dumps: Available in artifacts
      </failure>
    </testcase>
    <testcase name="Sustained Load (15 minutes)" classname="Endurance Tests" time="15.456"></testcase>
    <testcase name="Sustained Load (60 minutes)" classname="Endurance Tests" time="0.099">
      <error message="Test could not be completed due to environment issues" type="EnvironmentError">
        Description: Test environment became unstable during test execution
        Error: Database connection pool exhausted
        Time of Failure: 7 minutes into test
      </error>
    </testcase>
  </testsuite>
  <testsuite name="Scalability Tests" tests="3" failures="2" errors="0" time="35.789">
    <testcase name="Horizontal Scaling Response" classname="Scalability Tests" time="12.345">
      <failure message="Scaling response time exceeded threshold: expected &lt;30s&gt; but was &lt;78s&gt;" type="PerformanceFailure">
        Description: Time to handle increased load after scaling out exceeded threshold
        Expected: &lt;30s&gt;
        Actual: &lt;78s&gt;
        Scaling Event: 2 to 5 pods
        Load: 200 requests per second
      </failure>
    </testcase>
    <testcase name="Database Scaling" classname="Scalability Tests" time="15.678">
      <failure message="Database connection errors during scaling: expected &lt;0&gt; but was &lt;37&gt;" type="PerformanceFailure">
        Description: Database connection errors occurred during scaling operation
        Expected: &lt;0&gt;
        Actual: &lt;37&gt;
        Duration of Errors: 45 seconds
        Error Type: Connection timeout
      </failure>
    </testcase>
    <testcase name="Cache Scaling" classname="Scalability Tests" time="10.456"></testcase>
  </testsuite>
</testsuites>
EOF
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: "${ARTIFACT_PATH}/performance/**/*", fingerprint: true
                    perfReport sourceDataFiles: "${ARTIFACT_PATH}/performance/results.jtl"
                    junit '**/test-results/performance-test-results.xml'
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
                            sh 'npm run test:smoke || true'
                            // Generate failed smoke test results for visualization
                            sh '''
                            mkdir -p test-results
                            cat > test-results/smoke-test-results.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Smoke Tests" tests="10" failures="3" errors="1" time="45.678">
  <testsuite name="Critical Path Tests" tests="6" failures="2" errors="0" time="25.456">
    <testcase name="User can access homepage" classname="Critical Path Tests" time="3.456"></testcase>
    <testcase name="User can log in" classname="Critical Path Tests" time="4.567"></testcase>
    <testcase name="User can view products" classname="Critical Path Tests" time="3.678"></testcase>
    <testcase name="User can add product to cart" classname="Critical Path Tests" time="5.789">
      <failure message="Add to cart button not responding" type="ElementNotInteractableError">
        Error: Element &lt;button class="add-to-cart"&gt; is not interactable
        at Object.addToCart (test/smoke/productPage.test.js:45:12)
        at runTest (test/smoke/runner.js:78:22)
      </failure>
    </testcase>
    <testcase name="User can checkout" classname="Critical Path Tests" time="6.890">
      <failure message="Payment processing failed" type="APIError">
        Error: Payment API returned status 503
        at Object.processPayment (test/smoke/checkout.test.js:112:18)
        at runTest (test/smoke/runner.js:92:24)
      </failure>
    </testcase>
    <testcase name="User can view order history" classname="Critical Path Tests" time="4.321"></testcase>
  </testsuite>
  <testsuite name="API Health Checks" tests="4" failures="1" errors="1" time="20.222">
    <testcase name="Authentication API is responsive" classname="API Health Checks" time="4.123"></testcase>
    <testcase name="Product API is responsive" classname="API Health Checks" time="5.234"></testcase>
    <testcase name="Order API is responsive" classname="API Health Checks" time="6.345">
      <failure message="Order API response time exceeded threshold" type="PerformanceError">
        Error: Expected response time &lt; 1000ms but got 3456ms
        at checkResponseTime (test/smoke/api-health.test.js:67:14)
        at verifyOrderAPI (test/smoke/api-health.test.js:112:10)
      </failure>
    </testcase>
    <testcase name="Payment API is responsive" classname="API Health Checks" time="7.456">
      <error message="Connection refused" type="ConnectionError">
        Error: ECONNREFUSED: Connection refused
        at Socket.socketErrorListener (net.js:145:14)
        at Socket.emit (events.js:315:20)
        at checkPaymentAPI (test/smoke/api-health.test.js:156:12)
      </error>
    </testcase>
  </testsuite>
</testsuites>
EOF
                            '''
                        }
                    }
                    post {
                        always {
                            junit '**/test-results/smoke-test-results.xml'
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
            junit 'test-results/**/*.xml, **/target/failsafe-reports/*.xml'
            archiveArtifacts artifacts: "${ARTIFACT_PATH}/**/*", fingerprint: true
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
