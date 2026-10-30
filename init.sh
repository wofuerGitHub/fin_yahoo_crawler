touch README.md
touch .gitignore

mkdir ./src
mkdir ./src/python
mkdir ./docs

python3 -m venv .venv
source .venv/bin/activate

cat > .gitignore <<'EOF'
# Python virtual environment
.venv/

# Python cache / compiled files
__pycache__/
*.py[cod]
*$py.class

# Python test / tooling caches
.pytest_cache/
.mypy_cache/
.ruff_cache/
.coverage
htmlcov/

# VS Code
.vscode/

# macOS
.DS_Store

# Runtime-generated state
runtime/*
!runtime/.gitkeep

# Logs
*.log

# Environment / secrets
.env
.env.*

# Local config overrides
config/config.local.json
config/config.secret.json

# Docker / local temporary files
*.pid
*.tmp

# Runtime generated files

EOF