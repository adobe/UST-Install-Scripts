pipeline {
	agent any
	stages {
		stage('Configure') {
			steps {
				script{
					env.MESSAGE = sh(returnStdout: true, script: 'git log -1 --pretty=format:%s')
					env.DO_RELEASE = env.MESSAGE.matches("release:" + "(.*)")
				}
			}
		}	
		stage('Build') {
			steps {
				script{     
					dir("windows/Installer") {
						sh 'powershell -File build.ps1'
					}
					dir("windows"){
						archiveArtifacts artifacts: "Installer/bin/Signing/Finished/**.*", fingerprint: true
						archiveArtifacts artifacts: "CertGui/bin/Signing/Finished/**.*", fingerprint: true						 
					}
				}
			}
		}
		stage('Release') {
			when {expression { env.DO_RELEASE == 'true' }}
			steps {
				script{     
					dir("windows/Installer") {						
						sh 'powershell -File push_release.ps1 -filepath $msi_file -message "$MESSAGE"'
					}
				}
			}
		}
	}

	post { always { deleteDir()}}
}

