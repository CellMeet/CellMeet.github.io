---
title: "LeetCode Hot 100 238 : Product of Array Except Self (除了自身以外数组的乘积)"
date: "2026-11-24T20:00:54+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot-100-238-Product-of-Array-Except-Self-(除了自身以外数组的乘积)/"
categories: ["leetcode"]
tags: []
summary: ""
cover:
  image: ""
  alt: ""
---

# LeetCode Hot 100 238 : Product of Array Except Self (除了自身以外数组的乘积)

题目链接 : [LeetCode Hot 100 238 : Product of Array Except Self](https://leetcode.cn/problems/product-of-array-except-self/description/?envType=problem-list-v2&envId=2cktkvj)

## 题目思路

左边和右边两个前缀积, 先从左到右计算, 每个数字左边的前缀积

先计算一个数字左边的乘积:

```python 
class Solution:
    def productExceptSelf(self, nums: List[int]) -> List[int]:
        n = len(nums)
        ans = [0] * n
        prod = 1
        # 完成左边的乘积
        for i in range(n):
            ans[i] = prod
            prod *= nums[i]
        # 开始右乘
        prod = 1
        for j in range(n-1, -1, -1):
            ans[j] *= prod
            prod *= nums[j]

        return ans
```

​		做的好丑陋,  开始查看灵神的答案:sunglasses:

## 灵茶山艾府

- 首先, 计算ans[i], 可以计算pre[i] 和suf[i], (pre[i] 和suf[i] 分别是前缀和后缀)

  可以推导得到:

  ​		pre[i] = pre[i-1] * nums[i-1]

  ​		suf[i] = suf[i+1] * nums[i+1]

- 初始值: 

  pre[0] = suf[n-1] = 1, 计算出pre 数组和 suf数组后, 有

  ​		ans[i] = pre[i] * suf[i]

​		代码如下:

```python
class Solution:
    def productExceptSelf(self, nums: List[int]) -> List[int]:
        n = len(nums)
        pre = [1] * n
        for i in range(1, n)
        	pre[i] = pre[i-1] * nums[i-1]
        
        suf = [1] * n
        for j in range(n-2, -1, -1):
            suf[j] = suf[j+1] * nums[j+1]
        
        return [p * s for p, s in zip(pre, suf)]
```

