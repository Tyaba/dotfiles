.PHONY: download-stubs
download-stubs:
	poetry run mypy --install-types --non-interactive

.PHONY: lint
lint:
	poetry run python -m flake8 src
	poetry run python -m mypy src

.PHONY: format
format:
	poetry run python -m black src
	poetry run python -m isort src

.PHONY: vet
vet:
	make format
	make lint
