pipeline {
	agent any
	environment {
		msi_file = 'bin/sign/AdobeUSTSetup.msi'
		rel_key = 'release:'
	}
	stages {
		stage('Configure') {
			steps {
				script{
					env.MESSAGE = sh(returnStdout: true, script: 'git log -1 --pretty=format:%s')
					env.DO_RELEASE = env.MESSAGE.matches(rel_key + "(.*)")
				}
			}
		}	
		stage('Build') {
			steps {
				script{     
					dir("windows/Installer") {
						sh 'powershell -File build.ps1 -sign'
						archiveArtifacts artifacts: "$msi_file", fingerprint: true
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

