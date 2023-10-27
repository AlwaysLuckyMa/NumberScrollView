#!/bin/bash

echo "请输入提交消息: "
read commit_msg

git add .
git commit -m "$commit_msg"
git push origin main

echo "Done."
