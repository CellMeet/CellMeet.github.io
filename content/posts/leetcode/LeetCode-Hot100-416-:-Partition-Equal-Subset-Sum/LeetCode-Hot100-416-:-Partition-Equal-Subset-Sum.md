---
title: "LeetCode Hot100 416 : Partition Equal Subset Sum (分割等和子集)"
date: "2026-11-22T14:14:43+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot100-416-:-Partition-Equal-Subset-Sum/"
categories: ["leetcode"]
tags: ["0-1背包"]
summary: ""
cover:
  image: "cover.png"
  alt: ""
---

# LeetCode 416 : Partition Equal Subset Sum (分割等和子集)

题目链接 : [LeetCode : Partition Equal Subset Sum](https://leetcode.cn/problems/partition-equal-subset-sum/description/?envType=problem-list-v2&envId=2cktkvj)

​		经典 0-1 背包问题:

​		在 0 -1 背包问题中, 我们不能"复用" 之前得到的结果, 还是以Example 1 为例:

Input:

```python
nums = [1, 5, 11, 5]
```

Output: true

原因是 数组可以分为 [1, 5, 5] 和 [11] 两个子数组



​		在完全背包问题下:

​		我们遍历一个物品, 物品是"无限选取"的, 所以计算出dp[1] 之后, dp[2] 是可以直接用 dp[1] 的结果的, 但是在 0-1 背包问题下, 如果 一个物品 1 已经更新了 dp[1] 上, dp[2] 是不能再用 1 的,因为这个时候是没有两个 1 的, 也就是说, 如果这个背包里面没有 2 个1, 那么就没有dp[2], 这就是 "0-1 背包".

​		按照这样的思路, 我们解决这个问题, 问题实际转换成, 能否从背包(数组)中取出数字, 得到 total 的一半?

因为不能复用之前的数字, 所以我们可以这么做:

```python
class Solution:
    def canPartition(self, nums: list[int]) -> bool:
        alsum = sum(nums)
        if alsum % 2 != 0:
            return False
        
        tot = alsum // 2 # 需要填充的 tot
        dp = [False] * (tot + 1)  # 需要填满的背包 的数量, 命名为 tot
        dp[0] = True  # 一个不选,是可以填满的
        
        for num in nums: # 遍历nums
            for i in range(tot, num - 1, -1): # 采用倒序更新的方式, 避免复用之前的结果
                dp[i] = dp[i] or dp[i - num]
        return dp[tot]
            
```



总结 :

​		和完全背包不同, 0-1 背包需要从大到小进行倒序.  这样可以避免复用之前的结果, 保证一次 num 循环 每个位置只使用一次. 		 
