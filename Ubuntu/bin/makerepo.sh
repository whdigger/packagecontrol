#!/bin/bash

print_usage() {
  ERROR_MSG="$1"

  if [ "$ERROR_MSG" != "" ]; then
    echo -e "\nERROR: $ERROR_MSG\n" 1>&2
  fi

  echo "Usage: makerepo.sh marked_key_38E8X32S OPTIONS"
  echo "  The first argument to the script must be a marked key"
  echo ""
  echo "  Supported OPTIONS include:"
  echo "    -arch    Architecture for package. Example i386"
  echo "    -dir     Repo path directory"
  echo ""
}


if [ -z "$1" ]; then
  print_usage "Must specify marked_key use command: gpg --list-keys 'Имя ключа', or create new gpg --gen-key"
  exit 1
fi

REPO_MARKED_KEY=$1

# Проверка существования ключа
REPO_CHECK_MARKED_KEY=$(gpg --list-keys "$REPO_MARKED_KEY")
echo "$REPO_CHECK_MARKED_KEY" | grep -q "$REPO_MARKED_KEY"
if [ $? -ne 0 ];then
  print_usage "Not found marked key!"
  exit 1
fi

if [ $# -gt 1 ]; then
  shift
  while true; do
    case $1 in
        -arch)
            if [[ -z "$2" || "${2:0:1}" == "-" ]]; then
              print_usage "Directory path is required when using the $1 option!"
              exit 1
            fi
            REPO_ARCH=$2
            shift 2
        ;;
        -dir)
            if [[ -z "$2" || "${2:0:1}" == "-" ]]; then
              print_usage "Directory path is required when using the $1 option!"
              exit 1
            fi
            REPO_DIR=$2
            shift 2
        ;;
        -help|-usage)
            print_usage ""
            exit 0
        ;;
        --)
            shift
            break
        ;;
        *)
            if [ "$1" != "" ]; then
              print_usage "Unrecognized or misplaced argument: $1!"
              exit 1
            else
              break # out-of-args, stop looping
            fi
        ;;
    esac
  done
fi

if [ -z "$REPO_ARCH" ]; then
  REPO_ARCH=i386
fi

if [ "$REPO_ARCH" != "i386" ]; then
  REPO_ARCH=amd64
fi

FULL_REPO_DIR="$REPO_DIR/$REPO_ARCH"

# Поиск директории репозитория
if [ ! -d "$FULL_REPO_DIR" ]; then
  FULL_REPO_DIR=../$REPO_ARCH
fi

if [ ! -d "$FULL_REPO_DIR" ]; then
  print_usage "Repo directory not found $FULL_REPO_DIR"
  exit 1
fi

cd $FULL_REPO_DIR

# Удаление старых файлов Packages, Packages.gz, Release, public.key
rm -rf Packages Packages.gz Release public.key

if [ -z "$(which dpkg-scanpackages)" ]; then
   sudo apt-get install dpkg-dev
fi

# Экспортирование ключа в репозиторий
gpg --output public.key --armor --export $REPO_MARKED_KEY

# Create the Packages file
dpkg-scanpackages . /dev/null > Packages
gzip -9c Packages > Packages.gz

# Create the Release file
cat > Release <<EOF
Archive: internalRepo
Origin: Ubuntu
Label: Local Ubuntu Internal Repository
Architecture: $REPO_ARCH
MD5Sum:
EOF
printf ' '$(md5sum Packages | cut --delimiter=' ' --fields=1)' %16d Packages\n' \
   $(wc --bytes Packages | cut --delimiter=' ' --fields=1) >> Release
printf ' '$(md5sum Packages.gz | cut --delimiter=' ' --fields=1)' %16d Packages.gz' \
   $(wc --bytes Packages.gz | cut --delimiter=' ' --fields=1) >> Release

# Create the Release.gpg file
gpg --armor --detach-sign --output Release.gpg Release


# Отключение проверки ключа при установки пакета apt-get install --allow-unauthenticated
