---
title: "LeetCode Hot100 : 46 Permutations (全排列)"
date: "2026-11-24T14:22:39+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot100-46-Permutations-(全排列)/"
categories: ["leetcode"]
tags: ["hot100", "回溯", "全排列"]
summary: ""
cover:
  image: "cover.png"
  alt: ""
---

# LeetCode Hot100 : 46 Permutations (全排列)

题目链接 : [LeetCode Hot100 : 46 Permutations ](https://leetcode.cn/problems/permutations/description/?envType=problem-list-v2&envId=2cktkvj)

## 题目理解

全排列, 简单地说, 就是现在选择了几个, 然后从后面可以选择的集合中再次选取, 直到组成一个排列, 采用令茶山艾府的代码:

```python
class Solution:
    def permute(self, nums: list[int]) -> list[list[int]]:
        n = len(nums)
        ans = []
        path = [0] * n # 也可以用[], 然后用append来添加
        def dfs(i, s):
            if i == n:
                ans.append(path.copy())
                return
            for x in s:
                path[i] = x
                dfs(i+1, s-{x})
        dfs(0, set(nums))
        return ans
```

太优雅了! :+1:
