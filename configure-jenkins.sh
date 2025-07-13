#!/bin/bash

# Configure Jenkins Pipeline Job
# This script creates a Jenkins pipeline job for the Django app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get Jenkins URL and credentials
get_jenkins_info() {
    JENKINS_URL="http://$(kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):80"
    JENKINS_USER="admin"
    JENKINS_PASS="admin123"
    
    print_status "Jenkins URL: $JENKINS_URL"
}

# Wait for Jenkins to be available
wait_for_jenkins() {
    print_status "Waiting for Jenkins to be available..."
    
    for i in {1..30}; do
        if curl -s -f "$JENKINS_URL/login" > /dev/null 2>&1; then
            print_status "Jenkins is available."
            return 0
        fi
        echo "Waiting for Jenkins... ($i/30)"
        sleep 10
    done
    
    print_error "Jenkins is not available after 5 minutes."
    exit 1
}

# Create Jenkins job configuration
create_job_config() {
    cat > job-config.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@1.8.5"/>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@1.8.5">
      <jobProperties/>
      <triggers/>
      <parameters/>
      <options/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
  </actions>
  <description>Django App CI/CD Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.34.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.90">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/kazamov/goit-microservice-project.git</url>
          <credentialsId>github-token</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>django_app/Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
}

# Create the Jenkins job
create_jenkins_job() {
    print_status "Creating Jenkins pipeline job..."
    
    # Create job
    curl -X POST \
         -H "Content-Type: application/xml" \
         -u "$JENKINS_USER:$JENKINS_PASS" \
         -d @job-config.xml \
         "$JENKINS_URL/createItem?name=django-app-pipeline"
    
    if [ $? -eq 0 ]; then
        print_status "Jenkins job 'django-app-pipeline' created successfully."
    else
        print_error "Failed to create Jenkins job."
        exit 1
    fi
}

# Trigger initial build
trigger_build() {
    print_status "Triggering initial build..."
    
    curl -X POST \
         -u "$JENKINS_USER:$JENKINS_PASS" \
         "$JENKINS_URL/job/django-app-pipeline/build"
    
    if [ $? -eq 0 ]; then
        print_status "Initial build triggered successfully."
        print_status "Check Jenkins UI for build progress: $JENKINS_URL/job/django-app-pipeline/"
    else
        print_error "Failed to trigger initial build."
    fi
}

# Main execution
main() {
    print_status "Configuring Jenkins pipeline job..."
    
    get_jenkins_info
    wait_for_jenkins
    create_job_config
    create_jenkins_job
    trigger_build
    
    # Cleanup
    rm -f job-config.xml
    
    print_status "Jenkins pipeline configuration completed!"
    echo ""
    print_status "You can now:"
    echo "1. Visit Jenkins: $JENKINS_URL"
    echo "2. Monitor the pipeline: $JENKINS_URL/job/django-app-pipeline/"
    echo "3. Check ArgoCD for automatic application deployment"
}

# Run main function
main "$@"
