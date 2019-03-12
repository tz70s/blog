#!/bin/bash

rm -rf tz70s.github.io/*
hugo
cd tz70s.github.io
git add .
git commit -m "New blog post, generate statics."
git push
cd ..

git add .
git commit -m "New blog post"
git push
