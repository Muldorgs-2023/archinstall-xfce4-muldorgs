#!/bin/bash

# Rutas a los sistemas de archivos Btrfs
ROOT_PATH="/"
HOME_PATH="/home"

# Función para realizar scrub, balance y desfragmentación
mantener_btrfs() {
    local BTRFS_PATH=$1

    # Realizar scrub
    echo "Iniciando scrub en $BTRFS_PATH..."
    sudo btrfs scrub start $BTRFS_PATH
    sudo btrfs scrub status $BTRFS_PATH

    # Esperar a que el scrub termine
    while sudo btrfs scrub status $BTRFS_PATH | grep -q "running"; do
        echo "Scrub en progreso en $BTRFS_PATH..."
        sleep 60
    done
    echo "Scrub completado en $BTRFS_PATH."

    # Realizar balance con filtro básico
    echo "Iniciando balance en $BTRFS_PATH..."
    sudo btrfs balance start -dusage=5 -musage=5 $BTRFS_PATH
    sudo btrfs balance status $BTRFS_PATH

    # Esperar a que el balance termine
    while sudo btrfs balance status $BTRFS_PATH | grep -q "running"; do
        echo "Balance en progreso en $BTRFS_PATH..."
        sleep 60
    done
    echo "Balance completado en $BTRFS_PATH."

    # Realizar desfragmentación
    echo "Iniciando desfragmentación en $BTRFS_PATH..."
    sudo btrfs filesystem defragment -r $BTRFS_PATH
    echo "Desfragmentación completada en $BTRFS_PATH."
}

# Mantener la partición raíz
mantener_btrfs $ROOT_PATH

# Mantener la partición /home
mantener_btrfs $HOME_PATH
