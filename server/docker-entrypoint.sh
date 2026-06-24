set -e

if [ ! -f "/app/data/lms.db" ]; then
    echo "No database found. Creating fresh database..."
    ./server reset-db
fi

exec ./server
