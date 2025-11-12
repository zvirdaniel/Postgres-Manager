# Postgres Manager

Postgres Manager is a simple macOS desktop application that lets you control your PostgreSQL 14 database instance installed via Homebrew. It provides an easy-to-use interface for starting, stopping, and checking the status of your database without opening the terminal.

## Features

- Start PostgreSQL 14 with one click
- Stop PostgreSQL 14 with one click
- Refresh and display the current status (Running / Stopped)
- Lightweight and runs in macOS without additional dependencies
- Works with Homebrew-managed PostgreSQL installations

## Notes

- This app uses the Homebrew path `/opt/homebrew/bin/brew`. Ensure Homebrew is installed and accessible.
- The app runs commands via a login zsh shell to properly load the Homebrew environment.
- Designed for local, personal use. No notarization.
