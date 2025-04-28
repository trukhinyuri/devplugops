import jenkins.model.*
import hudson.security.*
import org.jenkinsci.plugins.workflow.libs.*
import jenkins.plugins.git.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import hudson.plugins.sshslaves.*
import hudson.model.*
import hudson.util.Secret
import javaposse.jobdsl.plugin.*
import java.util.logging.Logger

Logger logger = Logger.getLogger("init_jenkins.groovy")

logger.info("Starting Jenkins initialization script")

// Disable setup wizard
if (!Jenkins.instance.isQuiet()) {
    logger.info("Disabling Jenkins setup wizard")
    Jenkins.instance.quietDown()
}

// Configure global security
def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Create admin user
if (hudsonRealm.getAllUsers().isEmpty()) {
    logger.info("Creating admin user")
    def adminUsername = System.getenv("JENKINS_ADMIN_USERNAME") ?: "admin"
    def adminPassword = System.getenv("JENKINS_ADMIN_PASSWORD") ?: "admin"
    hudsonRealm.createAccount(adminUsername, adminPassword)
}

// Configure global settings
instance.setNumExecutors(5)
instance.setLabelString("master")
instance.setMode(Node.Mode.NORMAL)
instance.save()

// Configure credentials
logger.info("Setting up credentials")
def domain = Domain.global()
def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Add Docker registry credentials
def dockerCredentials = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "registry-credentials",
    "Docker Registry Credentials",
    "docker-user",
    "docker-password"
)
store.addCredentials(domain, dockerCredentials)

// Add GitHub credentials
def githubCredentials = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "github-credentials",
    "GitHub Credentials",
    "github-user",
    "github-token"
)
store.addCredentials(domain, githubCredentials)

// Add Kubernetes config credentials
def kubeConfigContent = """
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://kubernetes.default.svc
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
users:
- name: default
  user:
    token: service-account-token
"""

def kubeConfigCredentials = new StringCredentialsImpl(
    CredentialsScope.GLOBAL,
    "kubeconfig",
    "Kubernetes Config",
    Secret.fromString(kubeConfigContent)
)
store.addCredentials(domain, kubeConfigCredentials)

// Configure Kubernetes cloud
try {
    logger.info("Configuring Kubernetes cloud")
    def kubernetes = Jenkins.instance.getExtensionList("org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud")[0]
    if (kubernetes == null) {
        logger.info("Kubernetes plugin not installed or configured")
    } else {
        // Configure Kubernetes cloud settings
        // This is a simplified example - in a real environment, you would need more detailed configuration
        kubernetes.setServerUrl("https://kubernetes.default.svc")
        kubernetes.setNamespace("jenkins")
        kubernetes.setJenkinsUrl("http://jenkins.jenkins.svc.cluster.local:8080")
        kubernetes.setCredentialsId("kubeconfig")
        kubernetes.setWebSocket(true)
        kubernetes.setDirectConnection(false)
        kubernetes.setRetentionTimeout(15)
        Jenkins.instance.clouds.replace(kubernetes)
    }
} catch (Exception e) {
    logger.warning("Failed to configure Kubernetes cloud: ${e.message}")
}

// Install Blue Ocean plugin for enhanced pipeline visualization
logger.info("Installing Blue Ocean plugin for enhanced pipeline visualization")
try {
    def pm = Jenkins.instance.pluginManager
    def uc = Jenkins.instance.updateCenter

    // Check if Blue Ocean plugin is already installed
    if (!pm.getPlugin("blueocean")) {
        // Update the update center
        uc.updateAllSites()

        // Install Blue Ocean plugin
        def plugin = uc.getPlugin("blueocean")
        if (plugin) {
            def installFuture = plugin.deploy()
            installFuture.get()
            logger.info("Blue Ocean plugin installed successfully")
        } else {
            logger.warning("Blue Ocean plugin not found in update center")
        }
    } else {
        logger.info("Blue Ocean plugin is already installed")
    }
} catch (Exception e) {
    logger.warning("Failed to install Blue Ocean plugin: ${e.message}")
}

// Load job from XML
try {
    logger.info("Creating pipeline job")
    def jobName = "production-infrastructure-pipeline"
    def jobXml = new File("/var/jenkins_home/job-config.xml").text
    def xmlStream = new ByteArrayInputStream(jobXml.getBytes())

    def jobInstance = Jenkins.instance.createProjectFromXML(jobName, xmlStream)
    jobInstance.save()
    logger.info("Job '${jobName}' created successfully")
} catch (Exception e) {
    logger.warning("Failed to create job: ${e.message}")
}

logger.info("Jenkins initialization completed")
