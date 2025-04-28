# Jenkins Configuration

This directory contains configuration files for setting up Jenkins to build and deploy the application. The configuration is designed to demonstrate common critical issues that DevOps/SRE professionals face in production environments.

## Files

- `job-config.xml`: Jenkins job configuration file that can be imported into Jenkins
- `../Jenkinsfile`: Pipeline definition file that defines the build, test, and deployment stages

## Required Jenkins Plugins

To use this configuration, the following Jenkins plugins are required:

- Pipeline
- Kubernetes
- Docker
- Git
- Credentials
- GitHub Integration
- Blue Ocean (for enhanced visualization of pipeline stages)
- Email Extension Plugin (for email notifications)

## Custom Jenkins Image

This repository includes a custom Jenkins Docker image that extends the official Jenkins LTS image with additional tools:

- Docker CLI: Allows Jenkins to run Docker commands and use Docker pipeline agents

### Building the Custom Jenkins Image

To build the custom Jenkins image:

```bash
cd jenkins
docker build -t custom-jenkins:latest .
```

### Using the Custom Jenkins Image

The deployment configuration in `deployments/jenkins/deployment.yaml` is set to use this custom image. Make sure to build and push the image to your container registry before deploying Jenkins.

## Setup Instructions

### 1. Install Required Plugins

Go to "Manage Jenkins" > "Manage Plugins" > "Available" and install the required plugins.

### 2. Configure Kubernetes Cloud

If you're running Jenkins in Kubernetes:

1. Go to "Manage Jenkins" > "Manage Nodes and Clouds" > "Configure Clouds"
2. Add a new Kubernetes cloud
3. Configure the Kubernetes connection details
4. Save the configuration

### 3. Configure Credentials

The pipeline requires the following credentials:

1. `registry-credentials`: Docker registry credentials (Username with password)
2. `kubeconfig`: Kubernetes configuration file (Secret file)
3. `github-credentials`: GitHub credentials (Username with password)

To add these credentials:

1. Go to "Manage Jenkins" > "Manage Credentials"
2. Add the required credentials with the specified IDs

### 4. Import Job Configuration

To import the job configuration:

1. Create a new job in Jenkins
2. Select "New Item"
3. Enter a name for the job
4. Select "Pipeline" as the job type
5. Click "OK"
6. In the job configuration page, scroll down to "Pipeline"
7. Select "Pipeline script from SCM"
8. Select "Git" as the SCM
9. Enter your repository URL
10. Select the appropriate credentials
11. Specify the branch to build (e.g., */main)
12. Set the Script Path to "Jenkinsfile"
13. Save the configuration

Alternatively, you can use the Jenkins CLI to import the job configuration:

```bash
java -jar jenkins-cli.jar -s http://your-jenkins-url/ create-job your-job-name < job-config.xml
```

## Expected Failures

When running this pipeline, you will encounter various critical failures that simulate real-world issues in production environments:

1. **Build & Test Stage**:
   - Go module proxy connectivity issues
   - Dependency resolution failures
   - Test database connection problems
   - Security vulnerabilities in code

2. **Docker Build & Push Stage**:
   - Docker daemon connectivity issues
   - Registry authentication failures
   - Image layer cache corruption

3. **Deploy Stage**:
   - Kubernetes API server connectivity issues
   - Helm chart validation failures
   - Service account permission problems
   - Resource allocation failures

These failures are intentionally designed to demonstrate the types of issues that DevOps/SRE professionals commonly face and need to troubleshoot in production environments.

## Troubleshooting

The errors shown in this pipeline are simulated for demonstration purposes. In a real environment, you would need to:

1. Check network connectivity between Jenkins and external services
2. Verify credential validity and permissions
3. Ensure sufficient resources are available in the Kubernetes cluster
4. Validate configuration files for syntax errors
5. Check service health and availability

## Visualizing Pipeline Failures

### Enabling Blue Ocean

Blue Ocean provides an enhanced visualization of Jenkins pipelines:

1. Go to "Manage Jenkins" > "Manage Plugins" > "Available"
2. Search for "Blue Ocean"
3. Install the plugin and restart Jenkins if necessary
4. Access Blue Ocean by clicking "Open Blue Ocean" in the left sidebar

### Capturing Pipeline Failures

For the most dramatic visualization of pipeline failures, capture these three views:

1. **Blue Ocean Stage View**
   - Open the pipeline in Blue Ocean
   - The stage view will show all stages with the failed "Test" stage highlighted in red
   - The visual flow with arrows between stages makes the failure more prominent

2. **Build History View**
   - Go to the job's main page
   - The "Build History" section will show a series of red circles for failed builds
   - The weather icon will show a storm cloud indicating frequent failures

3. **Console Output View**
   - Open the failed build
   - Go to "Console Output"
   - Scroll to the failure point where you'll see the red error messages:
     ```
     ❌ Unit tests failed
     ❌ Integration tests failed: Expected status code 200, got 503
     ❌ Security scan detected critical vulnerabilities
     ```

These views together provide a comprehensive visualization of the pipeline failure that's ideal for demonstrations and screenshots.

## Note

This configuration is designed to fail intentionally to demonstrate critical issues. Do not use it in a production environment without removing the intentional failure points.
