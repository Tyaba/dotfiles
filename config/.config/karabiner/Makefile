.PHONY: generate
generate:
	poetry run python -m keymap_generator.app.generate_keymap

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

.PHONY: download-stubs
download-stubs:
	poetry run mypy --install-types --non-interactive