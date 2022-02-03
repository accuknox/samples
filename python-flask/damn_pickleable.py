from app import app


def main():
    # Normally debug wouldn't be true but this is a vulnerable app soo
    app.run(host='0.0.0.0', port=8008, debug=True)

if __name__ == "__main__":
    main()
