#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Heroku"
MODULE_NAME="heroku"
RELEASES_REPO="https://api.github.com/repos/FinikDev631/heroku-releases/releases/latest"
REPO_URL="${HEROKU_REPO_URL:-https://github.com/FinikDev631/heroku.git}"
GIT_TOKEN="${HEROKU_GIT_TOKEN:-}"
SRC_KEY="${HEROKU_SRC_KEY:-heroku-src-2026}"
VENV_DIR="${HEROKU_VENV_DIR:-.venv}"
LOG_FILE="$PWD/heroku-install.log"

if [ -n "$GIT_TOKEN" ]; then
	AUTH_URL="${REPO_URL/https:\/\/github.com/https://x-access-token:${GIT_TOKEN}@github.com}"
else
	AUTH_URL="$REPO_URL"
fi

if [ "${SUDO_USER:-}" != "" ] && command -v sudo >/dev/null 2>&1; then
	RUN_AS_USER=(sudo -u "$SUDO_USER")
else
	RUN_AS_USER=()
fi

is_installed() {
	local dir="$1"

	[ -f "$dir/.setup_complete" ] && [ -d "$dir/$MODULE_NAME" ] && "$dir/$VENV_DIR/bin/python" -c "import sys" >/dev/null 2>&1
}

find_root() {
	local dir="$PWD"

	while [ "$dir" != "/" ]; do
		if [ -f "$dir/$MODULE_NAME/__main__.py" ] && [ -f "$dir/requirements.txt" ]; then
			printf "%s" "$dir"
			return 0
		fi
		dir="$(dirname "$dir")"
	done
	return 1
}

find_installed() {
	local dir

	for dir in "$PWD" "$PWD/$APP_NAME" "$HOME/$APP_NAME"; do
		if is_installed "$dir"; then
			printf "%s" "$dir"
			return 0
		fi
	done
	return 1
}

is_minimal() {
	case "${HEROKU_MINIMAL:-auto}" in
		1) return 0 ;;
		0) return 1 ;;
	esac

	[ -d /support ] || grep -qE "^TracerPid:[[:space:]]*[1-9]" /proc/self/status 2>/dev/null
}

info() {
	printf "\033[38;5;177m%s\033[0m\n" "$1"
}

warn() {
	printf "\033[1;33m%s\033[0m\n" "$1" >&2
}

ok() {
	printf "\033[0;32m%s\033[0m\n" "$1"
}

fail() {
	if [ -s "$LOG_FILE" ]; then
		printf "\n--- последние строки лога ---\n" >&2
		tail -n 25 "$LOG_FILE" >&2
		printf "\nПолный лог: %s\n\n" "$LOG_FILE" >&2
	fi
	printf "\033[1;31m%s\033[0m\n" "$1" >&2
	exit "${2:-1}"
}

run() {
	"$@" >>"$LOG_FILE" 2>&1 || fail "Не удалось выполнить: $*" 5
}

sudo_run() {
	if [ "$(id -u)" -eq 0 ]; then
		run "$@"
	elif command -v sudo >/dev/null 2>&1; then
		run sudo "$@"
	else
		fail "Нужны root-права или sudo, чтобы поставить системные пакеты." 2
	fi
}

python_cmd() {
	if command -v python3 >/dev/null 2>&1; then
		printf "python3"
	elif command -v python >/dev/null 2>&1; then
		printf "python"
	else
		fail "Python не установлен." 2
	fi
}

check_python() {
	local py="$1"

	"$py" - <<'PY'
import sys

if sys.version_info < (3, 10):
    raise SystemExit("Python 3.10+ is required")
PY
}

install_system_packages() {
	info "Ставлю системные пакеты..."

	if echo "${OSTYPE:-}" | grep -qE "^linux-android"; then
		fail "Termux не поддерживается (часть зависимостей не собирается под Android).
Ставь в UserLAnd:
1) Установи UserLAnd из Google Play и создай Ubuntu-сессию
2) В терминале Ubuntu повтори ту же команду установки

Подойдёт и любой другой Linux (VDS, WSL и т.д.)." 2
	elif command -v apt-get >/dev/null 2>&1 && is_minimal; then
		info "Минимальный режим: ставлю только нужные пакеты."
		sudo_run apt-get update
		sudo_run apt-get install -y git python3 python3-venv curl openssl ca-certificates
	elif command -v apt-get >/dev/null 2>&1; then
		sudo_run apt-get update
		sudo_run apt-get install -y \
			build-essential \
			curl \
			ffmpeg \
			git \
			imagemagick \
			libcairo2 \
			libffi-dev \
			libjpeg-dev \
			libmagic1 \
			libopenjp2-7 \
			libtiff-dev \
			libwebp-dev \
			libz-dev \
			openssl \
			ca-certificates \
			python3 \
			python3-dev \
			python3-pip \
			python3-venv
	elif command -v pacman >/dev/null 2>&1; then
		sudo_run pacman -Sy --needed --noconfirm \
			ca-certificates \
			base-devel \
			curl \
			ffmpeg \
			file \
			git \
			imagemagick \
			openssl \
			python \
			python-pip
	elif command -v dnf >/dev/null 2>&1; then
		sudo_run dnf install -y \
			ca-certificates \
			curl \
			ffmpeg \
			file-libs \
			gcc \
			gcc-c++ \
			git \
			ImageMagick \
			openssl \
			python3 \
			python3-devel \
			python3-pip
	elif command -v brew >/dev/null 2>&1; then
		run brew install git openssl ca-certificates jpeg webp
	else
		info "Неизвестный пакетный менеджер — пропускаю установку системных пакетов."
	fi
}

git_as_user() {
	${RUN_AS_USER[@]+"${RUN_AS_USER[@]}"} git "$@"
}

switch_branch() {
	local branch="${HEROKU_BRANCH:-}" current output

	if [ -z "$branch" ]; then
		return 0
	fi

	if ! git_as_user rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		warn "Не переключаюсь на ветку $branch: это не git-репозиторий."
		return 0
	fi

	current="$(git_as_user rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
	if [ "$current" = "$branch" ]; then
		return 0
	fi

	if [ -n "$(git_as_user status --porcelain 2>/dev/null)" ]; then
		warn "Не переключаюсь на ветку $branch, остаюсь на ${current:-текущей}: есть локальные изменения. Закоммить их и запусти снова."
		return 0
	fi

	if ! output="$(git_as_user fetch --quiet origin "$branch" 2>&1 && git_as_user checkout --quiet "$branch" 2>&1)"; then
		warn "Не переключаюсь на ветку $branch, остаюсь на ${current:-текущей}: $output"
		return 0
	fi

	info "Переключился на ветку $branch."
}

prepare_repo() {
	if [ -d "$MODULE_NAME" ] && [ -f "requirements.txt" ]; then
		switch_branch
		return
	fi

	if [ -d "$APP_NAME/$MODULE_NAME" ]; then
		cd "$APP_NAME"
		switch_branch
		return
	fi

	local branch=()
	if [ -n "${HEROKU_BRANCH:-}" ]; then
		branch=(--branch "$HEROKU_BRANCH")
	fi

	info "Клонирую репозиторий..."
	rm -rf "$APP_NAME"
	clone_url="$AUTH_URL"
	${RUN_AS_USER[@]+"${RUN_AS_USER[@]}"} git clone ${branch[@]+"${branch[@]}"} "$clone_url" "$APP_NAME" >>"$LOG_FILE" 2>&1 || fail "Не удалось склонировать репозиторий (см. heroku-install.log). Проверь токен." 3
	git -C "$APP_NAME" remote set-url origin "$AUTH_URL"
	cd "$APP_NAME"
}

# Без токена: расшифрованный архив исходников из публичного репозитория релизов
install_from_release() {
	local json url

	json="$(curl -fsSL "$RELEASES_REPO")" || fail "Не удалось получить информацию о релизах. Проверь интернет." 6

	url="$(printf '%s' "$json" | grep -oE '"browser_download_url": *"https://[^"]+/heroku-src\.enc"' | head -n 1 | grep -oE 'https[^"]+')"
	[ -n "$url" ] || fail "В последнем релизе нет архива исходников." 6

	info "Скачиваю Heroku..."
	if [ -d "$APP_NAME" ]; then
		rm -rf "$APP_NAME/heroku"
		rm -f "$APP_NAME/requirements.txt"
	else
		mkdir -p "$APP_NAME"
	fi
	run curl -fsSL -o "$APP_NAME/heroku-src.enc" "$url"

	run openssl enc -d -aes-256-cbc -pbkdf2 -in "$APP_NAME/heroku-src.enc" -out "$APP_NAME/heroku.tar.gz" -pass "pass:$SRC_KEY"
	rm -f "$APP_NAME/heroku-src.enc"
	run tar -xzf "$APP_NAME/heroku.tar.gz" -C "$APP_NAME"
	rm -f "$APP_NAME/heroku.tar.gz"
	cd "$APP_NAME"
}

current_version() {
	"$VENV_DIR/bin/python" -c "import sys; sys.path.insert(0, '.'); from heroku.version import __version__; print('.'.join(map(str, __version__)))" 2>/dev/null || true
}

# Обновление уже установленного бота из релизов (без git)
update_from_release() {
	local json latest current

	json="$(curl -fsSL "$RELEASES_REPO" 2>/dev/null)" || return 0
	latest="$(printf '%s' "$json" | grep -oE '"tag_name": *"v[0-9]+\.[0-9]+\.[0-9]+"' | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
	current="$(current_version)"

	if [ -z "$latest" ] || [ "$latest" = "$current" ]; then
		return 0
	fi

	info "Доступна версия $latest (установлена ${current:-неизвестно}), обновляю..."
	install_from_release
	install_python_packages
	rm -f "$LOG_FILE"
	ok "Обновился до $latest."
}

create_venv() {
	local py="$1"

	info "Создаю виртуальное окружение..."
	${RUN_AS_USER[@]+"${RUN_AS_USER[@]}"} "$py" -m venv "$VENV_DIR" >>"$LOG_FILE" 2>&1 || fail "Не удалось создать виртуальное окружение." 4
}

install_python_packages() {
	local venv_python="$VENV_DIR/bin/python"
	local newhash oldhash

	newhash="$(sha256sum requirements.txt | cut -d' ' -f1)"
	oldhash="$(cat .requirements_hash 2>/dev/null || true)"
	if [ -x "$venv_python" ] && [ "$newhash" = "$oldhash" ]; then
		return 0
	fi

	info "Ставлю Python-зависимости..."
	${RUN_AS_USER[@]+"${RUN_AS_USER[@]}"} "$venv_python" -m pip install --upgrade pip setuptools wheel >>"$LOG_FILE" 2>&1 || fail "Не удалось обновить pip." 4
	${RUN_AS_USER[@]+"${RUN_AS_USER[@]}"} "$venv_python" -m pip install --upgrade -r requirements.txt --disable-pip-version-check >>"$LOG_FILE" 2>&1 || fail "Не удалось установить зависимости." 4

	${RUN_AS_USER[@]+"${RUN_AS_USER[@]}"} "$venv_python" - >>"$LOG_FILE" 2>&1 <<'PY' || true
import hashlib

with open("requirements.txt", "rb") as f, open(".requirements_hash", "w") as h:
    h.write(hashlib.sha256(f.read()).hexdigest())
PY
}

start_app() {
	info "Запускаю..."
	if [ ! -t 0 ] && (: </dev/tty) 2>/dev/null; then
		exec </dev/tty
	fi

	exec ${RUN_AS_USER[@]+"${RUN_AS_USER[@]}"} "$VENV_DIR/bin/python" -m "$MODULE_NAME" "$@"
}

main() {
	# Без терминального stdin (например, bash <(curl ...)) бот не сможет
	# ничего спросить — перекачаем себя в файл и перезапустимся с tty.
	if [ ! -t 0 ] && ! (: </dev/tty) 2>/dev/null && command -v curl >/dev/null 2>&1 && [ "${HEROKU_INSTALLER_REEXEC:-}" != "1" ]; then
		info "Нет доступа к клавиатуре — перекачиваю установщик на диск..."
		dest="/tmp/heroku-installer.sh"
		curl -fsSL "${HEROKU_INSTALLER_URL:-https://raw.githubusercontent.com/FinikDev631/heroku-releases/master/install.sh}" -o "$dest" || fail "Не удалось скачать установщик." 7
		HEROKU_INSTALLER_REEXEC=1 exec bash "$dest"
	fi

	if root="$(find_root)"; then
		cd "$root"
	fi

	if [ "${HEROKU_FORCE_INSTALL:-0}" != "1" ] && existing="$(find_installed)"; then
		cd "$existing"

		if [ -n "$GIT_TOKEN" ] || [ -n "${HEROKU_REPO_URL:-}" ]; then
			info "Heroku уже установлен, запускаю..."
			switch_branch
		elif [ "${HEROKU_SKIP_UPDATE:-0}" != "1" ]; then
			update_from_release
		else
			info "Heroku уже установлен, запускаю..."
		fi

		start_app "$@"
		return
	fi

	clear || true
	printf "\033[3;38;5;177;40mInstalling %s...\033[0m\n\n" "$APP_NAME"

	: >"$LOG_FILE"

	if [ "${SUDO_USER:-}" != "" ]; then
		chown "$SUDO_USER:" "$LOG_FILE" >/dev/null 2>&1 || true
	fi

	install_system_packages
	PYTHON="$(python_cmd)"
	check_python "$PYTHON"

	if [ -n "$GIT_TOKEN" ] || [ -n "${HEROKU_REPO_URL:-}" ]; then
		prepare_repo
	else
		install_from_release
	fi

	[ -f assets/download.txt ] && cat assets/download.txt
	create_venv "$PYTHON"
	install_python_packages

	touch .setup_complete
	rm -f "$LOG_FILE"

	ok "Установка завершена."
	start_app "$@"
}

main "$@"; exit $?
