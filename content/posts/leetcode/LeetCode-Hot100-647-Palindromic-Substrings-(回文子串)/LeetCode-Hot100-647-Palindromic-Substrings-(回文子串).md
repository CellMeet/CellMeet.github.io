---
title: "LeetCode Hot100 647 : Palindromic Substrings (回文子串)"
date: "2026-11-24T20:58:00+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot100-647-Palindromic-Substrings-(回文子串)/"
categories: ["leetcode"]
tags: ["hot100", "中心拓展法"]
summary: ""
cover:
  image: "cover.png"
  alt: ""
---

# LeetCode Hot100 647 : Palindromic Substrings (回文子串)

题目链接 : [LeetCode Hot100 647 : Palindromic Substrings](https://leetcode.cn/problems/palindromic-substrings/description/?envType=problem-list-v2&envId=2cktkvj)

## 题目思路

 		回文子串分为奇对称和偶对称, 有两种情况需要统计, 分别讨论, 一种做出来, 另一种迎刃而解, 先尝试做一下奇数的情况

```python
class Solution:
    def countSubstrings(self, s: str) -> int:
        if len(s) == 1:
            return 1
        
        ans = 0
        # 奇数, 两根指针从同一个数字向两边拓展
        for i in range(len(s)):
            l, r = i, i
            while l >= 0 and r < len(s) and s[l] == s[r]:
                ans += 1
                l -= 1
                r += 1
       		# 偶数
            l, r = i, i+1
            while l >= 0 and r < len(s) and s[l] == s[r]:
                ans += 1
                l -= 1
                r += 1
        
        return ans
```

解决.
