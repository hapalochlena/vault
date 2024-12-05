
# create venv
cd my_project # project containing the venv
python3.10 -m venv venv_name

# activate venv
cd my_project # project containing the venv
source venv_name/bin/activate

pip freeze > requirements.txt
pip install -r requirements.txt

# specify PyPI
pip install package --index-url https://pypi.org/simple