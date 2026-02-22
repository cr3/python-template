VENV := .venv

RUN := uv run
PYTHON := $(RUN) python
TOUCH := $(PYTHON) -c 'import sys; from pathlib import Path; Path(sys.argv[1]).touch()'

uv.lock: pyproject.toml
	uv lock

# Build venv and install python deps.
$(VENV):
	@echo Installing environment
	@uv sync --frozen --all-extras
	@$(TOUCH) $@

# Convenience target to build venv
.PHONY: setup
setup: $(VENV)

.PHONY: check
check: $(VENV)
	@echo Checking uv.lock: Running uv lock --check
	@uv lock --check
	@echo Linting code: Running pre-commit
	@$(RUN) pre-commit run -a

.PHONY: test
test: $(VENV)
	@echo Testing code: Running pytest
	@$(RUN) coverage run -p -m pytest

.PHONY: coverage
coverage: $(VENV)
	@echo Testing covarage: Running coverage
	@$(RUN) coverage combine
	@$(RUN) coverage html --skip-covered --skip-empty
	@$(RUN) coverage report

.PHONY: docs
docs: $(VENV)
	@echo Building docs: Running sphinx-build
	@$(RUN) sphinx-build -W -d build/doctrees docs build/html

.PHONY: build
build:
	@echo Creating wheel file
	@$(PYTHON) -m build

.PHONY: publish
publish:
	@echo Publishing: Dry run
	@TWINE_USERNAME=__token__ TWINE_PASSWORD=$(PYPI_TOKEN) \
	  python -m twine upload --repository-url https://test.pypi.org/legacy/ --dry-run dist/*
	@echo Publishing
	@TWINE_USERNAME=__token__ TWINE_PASSWORD=$(PYPI_TOKEN) \
	  python -m twine upload --repository-url https://test.pypi.org/legacy/ dist/*

.PHONY: clean
clean:
	@echo Cleaning ignored files
	@git clean -Xfd

.DEFAULT_GOAL := test
