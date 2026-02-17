VENV := .venv

# Choose uv or poetry
UV      := $(shell command -v uv 2>/dev/null)
POETRY  := $(shell command -v poetry 2>/dev/null)

ifeq ($(UV),)
  ifeq ($(POETRY),)
    $(error Neither uv nor poetry is installed. Please install one of them.)
  else
    TOOL := poetry
  endif
else
  TOOL := uv
endif

ifeq ($(TOOL),uv)
  INSTALL = uv sync --frozen
  CHECK   = uv lock --check
  RUN     = uv run
else
  INSTALL = poetry install --sync
  CHECK   = poetry check --lock
  RUN     = poetry run
endif

PYTHON := $(RUN) python
TOUCH := $(PYTHON) -c 'import sys; from pathlib import Path; Path(sys.argv[1]).touch()'

poetry.lock: pyproject.toml
	poetry lock

uv.lock: pyproject.toml
	uv lock

# Build venv and install python deps.
$(VENV):
	@echo Installing environment
	@$(INSTALL)
	@$(TOUCH) $@

# Convenience target to build venv
.PHONY: setup
setup: $(VENV)

.PHONY: check
check: $(VENV)
	@echo Checking $(TOOL) lock: Running $(CHECK)
	@$(CHECK)
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
