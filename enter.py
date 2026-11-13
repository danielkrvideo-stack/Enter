
import sys
import json
import time
import platform
from pathlib import Path

# ENTER SYSTEM
ENTER_NAME = "Enter"
ENTER_VERSION = "1.0.0"

BASE_DIR = Path(__file__).resolve().parent
CONFIG_FILE = BASE_DIR / "config.json"
LANGUAGES_DIR = BASE_DIR / "languages"

platform_override = None
config = {}
translations = {}


def load_config():
    if not CONFIG_FILE.exists():
        print("ERROR: Configuration file not found.")
        sys.exit(1)

    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as file:
            return json.load(file)
    except (json.JSONDecodeError, OSError):
        print("ERROR: Configuration file is invalid.")
        sys.exit(1)


def save_config():
    with open(CONFIG_FILE, "w", encoding="utf-8") as file:
        json.dump(config, file, indent=4, ensure_ascii=False)


def load_language(language):
    global translations

    language_file = LANGUAGES_DIR / f"{language}.json"

    if not language_file.exists():
        print("Language file not found.")
        return False

    try:
        with open(language_file, "r", encoding="utf-8") as file:
            translations = json.load(file)
        return True
    except (json.JSONDecodeError, OSError):
        print("Language file is invalid.")
        return False


def t(key):
    return translations.get(key, key)


def get_platform():
    if platform_override is not None:
        return platform_override

    system = platform.system()

    if system == "Darwin":
        return "macOS"
    elif system == "Windows":
        return "Windows"
    elif system == "Linux":
        return "Linux"

    return system


def get_architecture():
    architecture = platform.machine()

    if architecture.lower() in ("amd64", "x86_64"):
        return "x86_64"
    elif architecture.lower() in ("arm64", "aarch64"):
        return "ARM64"

    return architecture


def clear_terminal():
    if platform.system() == "Windows":
        import os
        os.system("cls")
    else:
        sys.stdout.write("\033c")
        sys.stdout.flush()


def loading(text, duration=0.25):
    symbols = ["|", "/", "_", "\\"]

    for i in range(101):
        symbol = symbols[i % len(symbols)]
        sys.stdout.write(f"\r{text}: {i}% {symbol}   ")
        sys.stdout.flush()
        time.sleep(duration / 100)

    print()


def startup():
    clear_terminal()

    print("""
  _____ _   _ _____ _____ ____
 | ____| \\ | |_   _| ____|  _ \\
 |  _| |  \\| | | | |  _| | |_) |
 | |___| |\\  | | | | |___|  _ <
 |_____|_| \\_| |_| |_____|_| \\_\\
""")

    print(f"ENTER {ENTER_VERSION}")
    print()

    loading(t("initializing"))
    loading(t("loading_modules"))
    loading(t("checking_components"))
    loading(t("preparing_environment"))

    print()
    print(t("ready"))
    print()


def show_about():
    print()
    print(f"Name: {config['name']}")
    print(f"Version: {config['version']}")
    print(f"Engine: {config['engine']}")
    print(f"Platform: {get_platform()}")
    print(f"Architecture: {get_architecture()}")
    print()


def show_help():
    print(f"""
{t("help")}

help       - Show commands
about      - Information about Enter
version    - Show Enter version
lang       - Show installed languages
lang <ID>  - Change language
python     - Enter Python mode
clear      - Clear terminal
switch Platform <OS> - Temporarily switch platform
exit       - Exit Enter
""")


def show_languages():
    print()
    print(t("available_languages") + ":")

    for language in config["installed_languages"]:
        marker = " (active)" if language == config["default_language"] else ""
        print(f"- {language}{marker}")

    print()


def change_language(language):
    language = language.strip()

    if language not in config["installed_languages"]:
        print(t("language_not_installed"))
        return

    if load_language(language):
        config["default_language"] = language
        save_config()
        print(t("language_changed"))


def switch_platform(command):
    global platform_override

    parts = command.split(maxsplit=2)

    if len(parts) != 3:
        print("Usage: switch Platform <Windows/macOS/Linux>")
        return

    platforms = {
        "windows": "Windows",
        "macos": "macOS",
        "linux": "Linux"
    }

    selected = parts[2].lower()

    if selected not in platforms:
        print("Available: Windows, macOS, Linux")
        return

    platform_override = platforms[selected]

    print(f"Platform temporarily switched to {platform_override}.")
    print("This change will reset when Enter closes.")


def python_mode():
    print(t("python_mode"))
    print(t("python_exit"))
    print()

    namespace = {}

    while True:
        try:
            code = input("PY >>> ")

            if code.strip() == "exit()":
                break

            exec(code, namespace)

        except Exception as error:
            print(f"Execution error: {error}")


def main():
    global config

    config = load_config()

    current_language = config.get("default_language", "En")

    if not load_language(current_language):
        current_language = "En"

        if not load_language(current_language):
            print("ERROR: English language file is missing.")
            sys.exit(1)

    startup()

    while True:
        try:
            command = input("ENTER >>> ").strip()

            if command.lower() in ("exit", "quit"):
                print(t("goodbye"))
                break

            elif command.lower() == "help":
                show_help()

            elif command.lower() == "about":
                show_about()

            elif command.lower() == "version":
                print(f"Enter Version {config['version']}")

            elif command.lower() == "lang":
                show_languages()

            elif command.lower().startswith("lang "):
                language = command[5:].strip()
                change_language(language)

            elif command.lower() == "python":
                python_mode()

            elif command.lower() == "clear":
                clear_terminal()

            elif command.lower().startswith("switch platform"):
                switch_platform(command)

            elif command == "":
                continue

            else:
                print(f"{t('unknown_command')}: {command}")
                print("Type 'help' to see available commands.")

        except KeyboardInterrupt:
            print("\n" + t("use_exit"))

        except EOFError:
            print("\n" + t("goodbye"))
            break


if __name__ == "__main__":
    main()
