#!/bin/bash

rm -rf public/*
hugo
cd public
git add .
git commit -m "New blog post, generate statics."
git push
cd ..

git add .
git commit -m "New blog post"
git push
