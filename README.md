# Загрузка пакетов из разных версий архитектур
```
sudo aptitude -o APT::Architecture="i386" update
aptitude -o APT::Architecture="i386" download package-name

sudo aptitude -o APT::Architecture="amd64" update
aptitude -o APT::Architecture="amd64" download package-name
```
