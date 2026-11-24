---
title: "LeetCode Hot100 1 : Two Sum (两数之和)"
date: "2026-11-24T16:15:37+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot100-1-Two-Sum-(两数之和)/"
categories: ["leetcode"]
tags: ["hot100", "哈希表"]
summary: ""
cover:
  image: "cover.png"
  alt: ""
---

# LeetCode Hot100 1 : Two Sum (两数之和)

题目链接 : [LeetCode Hot100 1 : Two Sum](https://leetcode.cn/problems/two-sum/description/?envType=problem-list-v2&envId=2cktkvj)

## 方法一 : 暴力

```python
class Solution(object):
    def twoSum(self, nums, target):
        for i in range(len(nums)):
            for j in range(i+1, len(nums)):
                if nums[i] + nums[j] == target:
                    return [i, j]
```



## 方法二 : 哈希表

```python
class Solution(object):
    def twoSum(self, nums, target):
        idx = defaultdict(int)
        for i in range(len(nums)):
            tar = target - nums[i]
            if tar in idx:
                return [idx[tar], i]
            idx[nums[i]] = i
         
```

这个写法的代码逻辑上不太直观, 使用灵神的:

```python
class Solution(object):
    def twoSum(self, nums, target):
        idx = {}
        for j, x in enumerate(nums):
            if target - x in idx:
                return [idx[target - x], j]
            idx[x] = j
```

