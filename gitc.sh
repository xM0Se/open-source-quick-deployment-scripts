#!/bin/bash

git add .

echo "Enter commit message: "
read commit_message

git commit -m "$commit_message"

git push origin $(git rev-parse --abbrev-ref HEAD)
