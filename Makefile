
version = $(file < version.txt)
unsigned_dir = bin
dist_dir = dist

# Signing
userid = ustinst1
ruleid = 42992
keypath = sehkmet
password_var = INSTALLER_SIGN_PASS
bast_url = https://artifactory.corp.adobe.com/artifactory/maven-est-public-release/com/adobe/est/clients/bast-client/1.0.544/bast-client-1.0.544-standalone.jar
bast_path = BastClient.jar
artifactory_user = dmenpm
artifactory_key_var = ARTIFACTORY_KEY

build:
	make prepare
	makensis.exe ust_setup.nsi

sign:
	curl -u ${artifactory_user}:${${artifactory_key_var}} -X GET ${bast_url} -o ${bast_path}
	java -jar "${bast_path}" -s -b "${unsigned_dir}" -d "${dist_dir}" -ri "${ruleid}" -u "${userid}" -p "${${password_var}}" -k "${keypath}"
	mv ${dist_dir}\AdobeUSTSetup.exe ${dist_dir}\AdobeUSTSetup-${version}.exe

prepare:
	@rm ${unsigned_dir} -rf
	@rm ${dist_dir} -rf
	@mkdir ${unsigned_dir}
	@mkdir ${dist_dir}
	
release_un:
	make build
	cp "${unsigned_dir}\AdobeUSTSetup.exe" "${dist_dir}\AdobeUST_${version}.exe"

release:
	make build
	make sign
