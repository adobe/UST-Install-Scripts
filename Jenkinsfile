pipeline {
	agent any
	environment {
		msi_file = "Installer/bin/Signing/Finished/AdobeUSTSetup.msi"
		cert_file = "CertGui/bin/Signing/Finished/adobeio-certgen.zip"
	}
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
						sh 'powershell -File build.ps1 -sign'
					}
					dir("windows"){
						archiveArtifacts artifacts: $msi_file, fingerprint: true
						archiveArtifacts artifacts: $cert_file, fingerprint: true						 
					}
				}
			}
		}
		stage('Release') {
			when {expression { env.DO_RELEASE == 'true' }}
			steps {
				script{     
					dir("windows") {						
						sh 'powershell -File push_release.ps1 -filepaths $msi_file, $cert_file -message "$MESSAGE"'
					}
				}
			}
		}
	}

	post { always { deleteDir()}}
}

