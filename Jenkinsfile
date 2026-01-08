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
                    def apps = readJSON file: 'apps.json'
                    env.APPS_JSON = groovy.json.JsonOutput.toJson(apps)
                }
            }
        }

        stage('Build, Push, Deploy Apps in Parallel') {
            steps {
                script {
                    def apps = new groovy.json.JsonSlurper().parseText(env.APPS_JSON)
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
                                        -t ${app.docker_image}:latest \
                                        -f Dockerfile ./${app.name}
                                """
                            }

                            stage("Tag Docker ${app.name}") {
                                sh "docker tag ${app.docker_image}:latest ${app.docker_image}:${BUILD_NUMBER}"
                            }

                            stage("Push Docker ${app.name}") {
                                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin && docker push ${app.docker_image}:${BUILD_NUMBER}"
                                }
                            }

                            stage("Deploy ${app.name}") {
                                script {
                                    // Apply deployment with placeholders replaced on the fly
                                    sh """
                                        sed \
                                            -e 's|\\\${APP_NAME}|${app.name}|g' \
                                            -e 's|\\\${APP_IMAGE}|${app.docker_image}:${BUILD_NUMBER}|g' \
                                            -e 's|\\\${NODE_PORT}|${app.node_port}|g' \
                                            ${app.k3s_deployment} | kubectl --kubeconfig=${KUBECONFIG} apply -f -
                                    """

                                    sh """
                                        sed \
                                            -e 's|\\\${APP_NAME}|${app.name}|g' \
                                            -e 's|\\\${APP_IMAGE}|${app.docker_image}:${BUILD_NUMBER}|g' \
                                            -e 's|\\\${NODE_PORT}|${app.node_port}|g' \
                                            ${app.k3s_service} | kubectl --kubeconfig=${KUBECONFIG} apply -f -
                                    """

                                    sh "kubectl --kubeconfig=${KUBECONFIG} rollout restart deployment ${app.name}-deployment"
                                }
                            }
                        }
                    }

                    parallel branches
                }
            }
        }
    }
}
