pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        KUBECONFIG = "/etc/rancher/k3s/k3s.yaml"
    }

    stages {
        stage('Clean Old Apps') {
            steps {
                sh 'rm -rf server dashboard client'  // remove old cloned app repos
            }
        }

        stage('Load Apps Config') {
            steps {
                script { 
                    apps = readJSON file: 'apps.json' 
                }
            }
        }

        stage('Build, Push, Deploy Apps in Parallel') {
            steps {
                script {
                    def branches = [:]

                    apps.each { app ->
                        branches[app.name] = {
                            stage("Clone ${app.name}") {
                                sh "git clone --branch ${app.branch} --single-branch ${app.git_url} ${app.name}"

                            }

                            stage("Build Docker ${app.name}") {
                                sh """
                                    docker build \
                                        --no-cache \
                                        --build-arg APP_NAME=${app.name} \
                                        --build-arg APP_TYPE=${app.app_type} \
                                        -t ${app.docker_image}:latest ./${app.name}
                                """
                            }

                            stage("Tag Docker ${app.name}") {
                                sh "docker tag ${app.docker_image}:latest ${app.docker_image}:${BUILD_NUMBER}"
                            }

                            stage("Push Docker ${app.name}") {
                                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]){
                                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin && docker push ${app.docker_image}:${BUILD_NUMBER}"
                                }
                            }

                            stage("Deploy ${app.name}") {
                                sh "sed -i 's|image: .*|image: ${app.docker_image}:${BUILD_NUMBER}|g' ${app.k3s_deployment}"
                                sh "kubectl apply -f ${app.k3s_deployment}"
                                sh "kubectl rollout restart deployment ${app.k3s_deployment.replace('.yaml','')}"
                                sh "kubectl apply -f ${app.k3s_service}"
                            }
                        }
                    }

                    parallel branches
                }
            }
        }
    } // end stages
}
