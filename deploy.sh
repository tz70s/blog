#!/bin/bash

rm -rf public/*
hugo
git add .
git commit -m "New blog post"
git push

cd public
git add .
git commit -m "New blog post, generate statics."
git push

