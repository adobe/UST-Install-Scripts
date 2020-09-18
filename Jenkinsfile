

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
                    dir('user_sync') {
                        env.VERSION = sh returnStdout: true, script: "type .\\version.txt"
                    }
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
        // stage('Package') {
        //     steps {
        //         script {
        //             powershell '.build\\.jenkins\\package.ps1'
        //             dir('release') {
        //                 archiveArtifacts artifacts: '**', fingerprint: true
        //             }
        //         }
        //     }
        // }
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













// import java.time.LocalDateTime
// pipeline {
// 	agent any
// 	environment {
// 		msi_name = 'AdobeUSTSetup.msi'
// 		cert_name = 'AdobeIOCertgen.zip'
// 		msi_file = "Installer/bin/Signing/Finished/${msi_name}"
// 		cert_file = "CertGui/bin/Signing/Finished/${cert_name}"
// 	}
// 	stages {
// 		stage('Configure') {
// 			steps {
// 				script{
// 					env.MESSAGE = sh(returnStdout: true, script: 'git log -1 --pretty=format:%s')
// 					env.DO_RELEASE = env.MESSAGE.matches("release:" + "(.*)") || params.release == "true"
// 					env.MESSAGE = java.net.URLEncoder.encode(env.MESSAGE + "\n\n" + params.message, "UTF-8")
// 					echo "Release: " + env.DO_RELEASE
// 				}
// 			}
// 		}
// 		stage('Build') {
// 			steps {
// 				script{     
// 					dir("windows/Installer") {
// 						sh 'powershell -File build.ps1 -sign'
// 					}
// 					dir("windows"){
// 						archiveArtifacts artifacts: "$msi_file", fingerprint: true
// 						archiveArtifacts artifacts: "$cert_file", fingerprint: true	
// 					}
// 				}
// 			}
// 		}
// 		stage('Release') {
// 			when {expression { env.DO_RELEASE == 'true' }}
// 			steps {
// 				script{
// 					String currentTime = LocalDateTime.now().toString()     
// 					dir("windows") {
// 						withAWS(credentials:'aws-upload', region:'us-east-2') {
// 							s3Upload(file:"$cert_file", bucket:"adobe-ust-installer", path:"${cert_name}-${currentTime}", acl:"PublicRead")
// 							s3Upload(file:"$msi_file", bucket:"adobe-ust-installer", path:"${msi_name}-${currentTime}", acl:"PublicRead")
// 						}	
// 						env.msg = MESSAGE
// 						sh 'powershell -File Installer/push_release.ps1 -filepaths "$msi_file","$cert_file" -message "$msg"'
// 					}
// 				}
// 			}
// 		}
// 	}

// 	post { always { deleteDir()}}
// }


