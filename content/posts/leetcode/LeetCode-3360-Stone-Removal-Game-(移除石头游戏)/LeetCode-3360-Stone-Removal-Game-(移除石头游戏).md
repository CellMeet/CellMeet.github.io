---
title: "LeetCode 3360 : Stone Removal Game (移除石头游戏)"
date: "2026-11-26T10:55:52+08:00"
draft: false
url: "/posts/leetcode/LeetCode-3360-Stone-Removal-Game-(移除石头游戏)/"
categories: ["leetcode"]
tags: ["leetcode"]
summary: ""
cover:
  image: "lc.jpg"
  alt: ""
---

# LeetCode 3360 : Stone Removal Game (移除石头游戏)

题目链接 : [LeetCode 3360 : Stone Removal Game](https://leetcode.cn/problems/stone-removal-game/description/?envType=daily-question&envId=2026-11-26)

## 解题思路

计算`nums = [0, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]` 数组的前缀和, 得到数组

`[0, 10, 19, 27 ...]` 我们认为在[0, 10)区间内, Alice是输了, [10, 19)是赢了, 以此类推,

所以找第一个 `> n` 的数字, 这就是 n所在的右范围, 假如 n 是12, 那么19 就是右边界, 此时 19 是第三个数字, 但是下标是2, 是偶数, 此时alice 获胜, 所以代码如下:

```python
class Solution:
    def canAliceWin(self, n: int) -> bool:
        nums = [0, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
        pre_sum = []
        
        tot = 0
        for x in nums:
            tot += x
            pre_sum.append(tot)

        for j, num in enumerate(pre_sum):
            if n < num:
                break

        if  j % 2 == 0:
            return True
        
        return False
        
        
```

​		但是代码的丑陋程度真是一言难尽... 看一下大佬的题解

## 模拟

```python
class Solution:
    def canAliceWin(self, n: int) -> bool:
        pick = 10
        while n >= pick:
            n -= pick
            pick -= 1
        return pick % 2 == 1
```

每次pick, 当 n >= pick 时, 可以pick, 此时n 减小, pick 减小, 有那种"轮流向自己开枪"的感觉有没    有,  最后如果pick 是偶数, 那么就是轮到Alice的环节了, 但是她不满足条件, 所以就输了, 反之, 最后的pick是奇数就赢了, 代码好简单.
