

/* groovylint-disable CompileStatic, DuplicateStringLiteral, NestedBlockDepth, TrailingWhitespace */
pipeline {
    agent {
        node {
            label 'ust_build'
            customWorkspace "C:\\jenkins\\workspace\\user_sync_installer\\${BUILD_NUMBER}"
        }
    }

    environment {
        SIGNED_RELEASE = 'true'
        UST_SIGN_INSTALLER_RULEID = credentials('ust_installer_sign_ruleid')
        UST_SIGN_PASSWORD = credentials('ust_sign_password')
        UST_SIGN_USERID = credentials('ust_sign_userid')
    }
    stages {
        stage('Configure') {
            steps {
                script {
                    powershell 'ls'
                    env.VERSION = powershell returnStdout: true, script: "type version.txt"
                    env.VERSION = env.VERSION.trim()
                    echo "Version: ${env:VERSION}"
                    echo "Signed build: ${env:SIGNED_RELEASE}"
                }
            }
        }
        stage('Build') {
            steps {
                script {
                    powershell 'make build'
                }
            }
        }
        stage('Sign') {
            when { expression { env.SIGNED_RELEASE == 'true' } }
            steps {
                script {
                    powershell 'make sign'
                }
            }
        }
        stage('Package') {
            steps {
                script {
                    dir('signed') {
                        archiveArtifacts artifacts: '**', fingerprint: true
                    }
                }
            }
        }
        // stage('Release') {
        //     when {expression { env.DO_RELEASE == 'true' }}
        //     steps {
        //     }
        // }
    }
    post {
        always {
            deleteDir()
        }
    }
}
