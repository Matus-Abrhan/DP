#! /bin/sh

echo "==========Flake8=========="
poetry run flake8 

echo "==========my[py]=========="
poetry run mypy .
