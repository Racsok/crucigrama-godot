#!/bin/bash

# Verificar si se pasó un mensaje como argumento
if [ -z "$1" ]; then
  echo "❌ Error: Debes escribir un mensaje para el commit."
  echo "💡 Uso: ./gp.sh \"Tu mensaje de commit aquí\""
  exit 1
fi

echo "🚀 Iniciando proceso de guardado..."

# Añadir todos los cambios
git add .

# Hacer el commit con el mensaje proporcionado
git commit -m "$1"

# Subir los cambios al repositorio remoto
git push

echo "✅ ¡Commit y push realizados con éxito!"
