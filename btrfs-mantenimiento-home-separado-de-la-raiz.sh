#!/bin/bash
: ' Este script realiza tres operaciones clave en el sistema de archivos Btrfs para mejorar su rendimiento y fiabilidad:
1. Scrub: Verifica la integridad de los datos y corrige errores detectados. Esto ayuda a mantener la salud del sistema
 de archivos y prevenir la corrupción de datos.
2. Balance: Redistribuye los datos y metadatos en el sistema de archivos para optimizar el uso del espacio.
 Esto es útil para evitar la fragmentación y mejorar el rendimiento general.
3. Desfragmentación: Reorganiza los archivos fragmentados para mejorar la velocidad de acceso y la eficiencia 
del almacenamiento. Esto es especialmente importante en sistemas con muchos archivos pequeños o con cambios frecuentes.
Nota: Implementar estas operaciones regularmente puede ayudar a mantener el sistema de archivos Btrfs en óptimas condiciones, 
asegurando un rendimiento y una fiabilidad consistentes asi como una mejor gestion del espacio y la escritura de nuestros dispositivos.'

# Verificar si el script se está ejecutando con privilegios de superusuario
if [ "$EUID" -ne 0 ]; then
       exec sudo "$0" "$@"
fi
echo 'ESTE SCRIPT, AL NO SER QUE SEA UN SERVIDOR, DEBE EJECUTARSE UNA VEZ AL MES. EN EL CASO DE UN SERVIDOR, SERÍA ENTRE 10 Y 15 DÍAS SEGÚN LA INTENSIDAD DE ESCRITURA QUE TENGA EL MISMO.'

# Rutas de los sistemas de archivos Btrfs
BTRFS_PATHS=("/" "/home")

# Preguntar al usuario si desea interacción
read -p "¿Desea interacción durante la ejecución del script? (s/n): " INTERACT

# Función para realizar scrub
function realizar_scrub {
    for path in "${BTRFS_PATHS[@]}"; do
        echo "Iniciando scrub en $path..."
        btrfs scrub start $path
        btrfs scrub status $path
    done
}

# Función para realizar balance
function realizar_balance {
    for path in "${BTRFS_PATHS[@]}"; do
        echo "Iniciando balance en $path..."
        btrfs balance start -dusage=75 $path
        btrfs balance status $path
    done
}

# Función para realizar defragmentación
function realizar_defragmentacion {
    for path in "${BTRFS_PATHS[@]}"; do
        echo "Iniciando defragmentación en $path..."
        btrfs filesystem defragment -r $path
    done
}

# Ejecutar acciones con o sin interacción
if [ "$INTERACT" == "s" ]; then
    read -p "¿Desea realizar scrub? (s/n): " RESPUESTA
    if [ "$RESPUESTA" == "s" ]; then
        realizar_scrub
    fi

    read -p "¿Desea realizar balance? (s/n): " RESPUESTA
    if [ "$RESPUESTA" == "s" ]; then
        realizar_balance
    fi

    read -p "¿Desea realizar defragmentación? (s/n): " RESPUESTA
    if [ "$RESPUESTA" == "s" ]; then
        realizar_defragmentacion
    fi
else
    realizar_scrub
    realizar_balance
    realizar_defragmentacion
fi

echo "Mantenimiento completado."
