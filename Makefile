output_dir = dist
build:
	-rmdir /S /Q $(output_dir)
	pwsh build.ps1
	makensis.exe ust_setup.nsi
