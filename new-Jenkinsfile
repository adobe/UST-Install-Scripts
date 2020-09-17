/* groovylint-disable CompileStatic, DuplicateStringLiteral, NestedBlockDepth, TrailingWhitespace */
pipeline {
//    agent any
    agent {
        node {
            label 'ust_build'
            customWorkspace "C:\\jenkins\\workspace\\user_sync\\${BUILD_NUMBER}"
        }
    }

    environment {
        BUILD_TARGET = 'standalone'
        SIGNED_RELEASE = 'true'
        UST_SIGN_PASSWORD = credentials('ust_sign_password')
        UST_SIGN_RULEID = credentials('ust_sign_ruleid')
        UST_SIGN_USERID = credentials('ust_sign_userid')
    }
    stages {
        stage('Configure') {
            steps {
                script {
                    dir('user_sync') {
                        env.VERSION = sh returnStdout: true, script:
                            "python -c 'import version; print(version.__version__)'"
                    }

                    env.VERSION = env.VERSION.trim()
                    project = (env.JOB_NAME.tokenize('/') as String[])[0]

                    switch (project) {
                        case 'UST Standard':
                            env.BUILD_EDITION = 'full'                            
                            env.UST_EXTENSION = '1'
                            break
                        case 'UST No Extension':
                            env.BUILD_EDITION = 'noext'
                            env.UST_EXTENSION = '0'
                            break
                        default:
                            error('Project name did not match and build edition')
                            break
                    }

                    echo "Version: ${env:VERSION}"
                    echo "Edition: ${env:BUILD_EDITION}"
                    echo "Extension: ${env:UST_EXTENSION}"
                    echo "Signed build: ${env:SIGNED_RELEASE}"
                    echo "Project Name: ${project}"
                }
            }
        }
        stage('Build') {
            steps {
                script {
                    powershell '.build\\.jenkins\\build.ps1'
                }
            }
        }
        stage('Test') {
            steps {
                script {
                    powershell '.build\\.jenkins\\test.ps1'
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
                    powershell '.build\\.jenkins\\package.ps1'
                    dir('release') {
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

