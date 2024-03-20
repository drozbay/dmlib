$config = Get-Content -Path .\config.txt | ConvertFrom-StringData
$environmentName = $config.ANACONDA_ENV_NAME

if (-not $environmentName) {
	Write-Host "Anaconda environment name is not set. Please check the config.txt file."
	exit
}

Create-Anaconda-Environment -environmentName $environmentName
if (-not $?) {
	exit
}

Activate-Anaconda -environmentName $environmentName
if (-not $?) {
	exit
}

pip uninstall -y devwraps
if (-not $?) {
	exit
}

pip uninstall -y zernike
if (-not $?) {
	exit
}

pip install -r .\requirements.txt

git config core.autocrlf true
git config core.fileMode false

cd devwraps
Remove-Item dist\*.whl -ErrorAction SilentlyContinue
python setup.py bdist_wheel

if (-not $?) {
	exit
}

pip install (get-item .\dist\*.whl)
cd ..

cd zernike
Remove-Item dist\*.whl -ErrorAction SilentlyContinue
python setup.py bdist_wheel

if (-not $?) {
	exit
}

pip install (get-item .\dist\*.whl)
cd ..

Remove-Item dist\*.whl -ErrorAction SilentlyContinue
python setup.py bdist_wheel

if (-not $?) {
	exit
}

pip install (get-item .\dist\*.whl)

git config --unset core.autocrlf
git config --unset core.fileMode
