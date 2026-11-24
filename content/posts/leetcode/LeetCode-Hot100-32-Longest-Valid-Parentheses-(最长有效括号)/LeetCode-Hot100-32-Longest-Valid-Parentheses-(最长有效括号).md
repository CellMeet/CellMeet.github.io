---
title: "LeetCode Hot100 : 32 Longest Valid Parentheses (最长有效括号)"
date: "2026-11-24T20:29:35+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot100-32-Longest-Valid-Parentheses-(最长有效括号)/"
categories: ["leetcode"]
tags: []
summary: ""
cover:
  image: ""
  alt: ""
---

# LeetCode Hot100 : 32 Longest Valid Parentheses (最长有效括号)

题目链接 : [LeetCode Hot100 : 32 Longest Valid Parentheses](https://leetcode.cn/problems/longest-valid-parentheses/?envType=problem-list-v2&envId=2cktkvj)

## 解题思路

- 首先想到堆, 里面存放最后使用的右括号, 计算最长的长度, 写一下代码

  ```python
  class Solution(object):
      def longestValidParentheses(self, s):
          stack = [-1]
          ans = 0
          for i, ch in enumerate(s):
              if ch == ')':
                  if stack[-1] != -1 and s[stack[-1]] == '(':
                      stack.pop()
                      ans = max(ans, i-stack[-1])
                  else:
                      stack.pop()
                      stack.append(i)
              else:
                  stack.append(i)
          return ans
  ```

  

  ​		优化一下思路:

  ```python
  class Solution(object):
      def longestValidParentheses(self, s):
          stack = [-1]
          ans = 0
          for i, ch in enumerate(s):
              if ch == '(':
              	if stack:
              		ans = max(ans, i-stack[-1])
              	else:
              		stack.append(i)
  		return ans
  ```

  
