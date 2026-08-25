.PHONY: install dev-backend dev-frontend db-reset clean help

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install:  ## Install dependencies
	pip install -r requirements.txt

dev-backend:  ## Start backend (port 8000, auto-reload)
	uvicorn backend.app.main:app --reload --port 8000

dev-frontend:  ## Start Streamlit frontend (port 8501)
	streamlit run frontend/app.py

db-reset:  ## Regenerate the SQLite database
	python -m backend.app.database

clean:  ## Remove caches and build artifacts
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache htmlcov .coverage dist build
