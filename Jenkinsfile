pipeline {
    agent {
        node {
            label 'multi-arch-docker-release'
            customWorkspace "${JOB_NAME}/${BUILD_NUMBER}"
        }
    }

    parameters {
        string(name: 'HAZELCAST_DOCKER_TAG', description: 'Hazelcast Docker Tag')
    }

    stages {
        stage('Log into Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'devopshazelcast-dockerhub', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh "docker login --username ${USERNAME} --password ${PASSWORD}"
                }
            }
        }
        stage('Build and push "hazelcast/hazelcast" image') {
            steps {
                dir("./hazelcast-oss") {
                    script {
                        sh "docker buildx build -t leszko/hazelcast:${HAZELCAST_DOCKER_TAG} --platform=linux/arm64,linux/amd64,linux/ppc64le,linux/s390x . --push"
                    }

                }
            }
        }
        stage('Build and push "hazelcast/hazelcast-enterprise"') {
            steps {
                dir("./hazelcast-enterprise") {
                    script {
                        sh "docker buildx build -t leszko/hazelcast-enterprise:${HAZELCAST_DOCKER_TAG} --platform=linux/arm64,linux/amd64,linux/ppc64le,linux/s390x . --push"
                    }

                }
            }
        }
    }
}
