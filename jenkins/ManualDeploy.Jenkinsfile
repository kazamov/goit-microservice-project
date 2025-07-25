pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: jenkins-deploy
spec:
  serviceAccountName: jenkins-sa
  containers:
    - name: kubectl
      image: bitnami/kubectl:latest
      command:
        - sleep
      args:
        - 99d
    - name: git
      image: alpine/git
      command:
        - sleep
      args:
        - 99d
    - name: helm
      image: alpine/helm:latest
      command:
        - sleep
      args:
        - 99d
"""
    }
  }

  environment {
    ECR_REGISTRY = "127214174194.dkr.ecr.eu-central-1.amazonaws.com"
    IMAGE_NAME = "django_app"
    GIT_REPO_URL = "https://github.com/kazamov/goit-microservice-project.git"
    CHART_PATH = "charts/django-app"
    
    COMMIT_EMAIL = "jenkins@localhost"
    COMMIT_NAME = "jenkins"
  }

  stages {
    stage('Validate Parameters') {
      steps {
        script {
          echo "Deployment Type: ${params.DEPLOYMENT_TYPE}"
          echo "Image Tag: ${params.IMAGE_TAG}"
          echo "Target Namespace: ${params.TARGET_NAMESPACE}"
          
          if (!params.IMAGE_TAG || params.IMAGE_TAG.trim() == "") {
            error("IMAGE_TAG parameter is required")
          }
        }
      }
    }

    stage('Direct Deployment') {
      when {
        expression { params.DEPLOYMENT_TYPE == 'Direct' }
      }
      steps {
        container('helm') {
          script {
            echo "🚀 Deploying Django app directly to Kubernetes..."
            sh """
              helm upgrade --install django-app ./charts/django-app \\
                --namespace ${params.TARGET_NAMESPACE} \\
                --create-namespace \\
                --set image.repository=${env.ECR_REGISTRY}/${env.IMAGE_NAME} \\
                --set image.tag=${params.IMAGE_TAG} \\
                --wait --timeout=300s
            """
            echo "✅ Direct deployment completed successfully!"
          }
        }
      }
    }

    stage('GitOps Deployment') {
      when {
        expression { params.DEPLOYMENT_TYPE == 'GitOps' }
      }
      steps {
        container('git') {
          withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PAT')]) {
            script {
              echo "🔄 Updating GitOps repository for Argo CD deployment..."
              sh """
                # Clone the repository
                git clone https://${GIT_USERNAME}:${GIT_PAT}@github.com/kazamov/goit-microservice-project.git repo
                cd repo/${env.CHART_PATH}
                
                # Show current values
                echo "Current values.yaml:"
                cat values.yaml
                
                # Update the image tag
                sed -i 's|tag: .*|tag: ${params.IMAGE_TAG}|' values.yaml
                
                # Show updated values
                echo "Updated values.yaml:"
                cat values.yaml
                
                # Configure git
                git config user.email "${env.COMMIT_EMAIL}"
                git config user.name "${env.COMMIT_NAME}"
                
                # Commit and push changes
                git add values.yaml
                git commit -m "🚀 Deploy Django app with tag ${params.IMAGE_TAG} [skip ci]" || echo "No changes to commit"
                git push origin main
                
                echo "✅ GitOps repository updated. Argo CD will sync automatically."
              """
            }
          }
        }
      }
    }

    stage('Verify Deployment') {
      steps {
        container('kubectl') {
          script {
            echo "🔍 Verifying deployment status..."
            sh """
              # Wait for deployment to be ready
              kubectl wait --for=condition=available --timeout=300s deployment/django-app-django -n ${params.TARGET_NAMESPACE} || true
              
              # Show deployment status
              kubectl get deployments -n ${params.TARGET_NAMESPACE}
              kubectl get pods -n ${params.TARGET_NAMESPACE}
              kubectl get services -n ${params.TARGET_NAMESPACE}
              
              # Show service endpoint
              echo "Service endpoint:"
              kubectl get service django-app-django -n ${params.TARGET_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || echo "LoadBalancer not ready yet"
            """
          }
        }
      }
    }
  }

  post {
    success {
      echo "🎉 Deployment completed successfully!"
      echo "Deployment Type: ${params.DEPLOYMENT_TYPE}"
      echo "Image Tag: ${params.IMAGE_TAG}"
      echo "Namespace: ${params.TARGET_NAMESPACE}"
    }
    failure {
      echo "❌ Deployment failed. Check logs for details."
    }
    cleanup {
      echo "🧹 Cleaning up..."
    }
  }
}
