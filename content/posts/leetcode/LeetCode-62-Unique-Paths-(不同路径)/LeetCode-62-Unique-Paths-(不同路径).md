---
title: "LeetCode Hot100 62 : Unique Paths (不同路径)"
date: "2026-11-24T09:58:55+08:00"
draft: false
url: "/posts/leetcode/LeetCode-62-Unique-Paths-(不同路径)/"
categories: ["leetcode"]
tags: ["hot100", "dp"]
summary: ""
cover:
  image: "cover.png"
  alt: ""
---

# LeetCode 62 : Unique Paths (不同路径)

题目链接 :  [LeetCode 62 : Unique Paths](https://leetcode.cn/problems/unique-paths/?envType=problem-list-v2&envId=2cktkvj)



​		简单动态规划, 代码如下:

```python
class Solution:
    def uniquePaths(self, m: int, n: int) -> int:
        dp = [1] * n
        for i in range(1, m):
            for j in range(1, n):
                if j == 0:
                    dp[j] == 1
                else:
                    dp[j] += dp[j-1]
        return dp[n-1]
```

注意一下第一列的j 为1, 剩下的就是 `dp[j] += dp[j-1]` 即可.

