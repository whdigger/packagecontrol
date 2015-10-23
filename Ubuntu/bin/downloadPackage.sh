#!/bin/bash

print_usage() {
  ERROR_MSG="$1"

  if [ "$ERROR_MSG" != "" ]; then
    echo -e "\nERROR: $ERROR_MSG\n" 1>&2
  fi

  echo "Usage: downloadPackage.sh i386 OPTION"
  echo "  The first argument architecture"
  echo ""
  echo "  Supported OPTIONS include:"
  echo "    -dir     Repo path directory"
  echo ""
}

confirm () {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure?}[y/N] " response
    case $response in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

if [ -z "$1" ]; then
  print_usage "First parametr must specify architecture: i368 or amd64"
  exit 1
fi

REPO_ARCH=$1

if [ $# -gt 1 ]; then
  shift
  while true; do
    case $1 in
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

OLD_REPO="${FULL_REPO_DIR}_old"
if [ ! -d "$OLD_REPO" ]; then
  mv $FULL_REPO_DIR "${FULL_REPO_DIR}_old"
fi

if [ ! -d "$FULL_REPO_DIR" ]; then
  mkdir $FULL_REPO_DIR
fi

cd $FULL_REPO_DIR

# Проверка наличия файла 
PACKAGE_LIST=../package.list
if [ ! -s "$PACKAGE_LIST" ]; then
  print_usage "Check exist file $PACKAGE_LIST"
  exit 1
fi

DEPREPO_LIST=../deprepository
if [ -s "$DEPREPO_LIST" ]; then
  sudo cp $DEPREPO_LIST /etc/apt/sources.list.d/developer.list
fi


# Загрузка пакетов для архитектур
if [ "$REPO_ARCH" == "i386" ]; then
  sudo aptitude -o APT::Architecture="i386" update
  aptitude -o APT::Architecture="i386" download `cat $PACKAGE_LIST`
else
  sudo aptitude -o APT::Architecture="amd64" update
  aptitude -o APT::Architecture="amd64" download `cat $PACKAGE_LIST`
fi

# Запрос на удаление старой папки
if [ -d "$OLD_REPO" ]; then
  confirm "Delete old repo?" && rm -rf "$OLD_REPO"
fi

ls | awk -F "_" '{print "{ name: " $1 ", version: " $2 " }" }'
