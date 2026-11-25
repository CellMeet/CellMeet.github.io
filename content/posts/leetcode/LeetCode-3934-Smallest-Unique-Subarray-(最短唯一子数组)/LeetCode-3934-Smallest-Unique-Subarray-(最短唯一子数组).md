---
title: "LeetCode 3934 : Smallest Unique Subarray (最短唯一子数组)"
date: "2026-11-25T09:26:49+08:00"
draft: false
url: "/posts/leetcode/LeetCode-3934-Smallest-Unique-Subarray-(最短唯一子数组)/"
categories: ["leetcode"]
tags: ["滑动窗口"]
summary: ""
cover:
  image: "leetcode.jpg"
  alt: ""
---

# LeetCode 3934 : Smallest Unique Subarray (最短唯一子数组)

题目链接 : [LeetCode 3934 : Smallest Unique Subarray](https://leetcode.cn/problems/smallest-unique-subarray/description/?envType=daily-question&envId=2026-11-25)

## 解法一 : 滑动窗口

1. 连续子数组, 想到滑动窗口, 首先确定滑动窗口的大小:

```python
n = len(nums)
for k in range(1, n+1):
```

2. 然后确定窗口右边界的范围:

```python
r = 0
while r+k <= n: # 这里r是窗口起始下标, 加上k最多能到n的下标
```

3. 统计窗口内的数量

```python
cnt = defaultdict(int)
subs = tuple(nums[r: r+k])
cnt[subs] += 1
```

4. 返回条件, 因为数组本身就是一个 nuique subarray, 所以最小值一定是1, 我们只需要判断第一个cnt[subs] == 1出现的k, 就是想要的结果 

```python
if min(cnt.values) == 1:
    return k
```

​		完整代码如下:

```python
class Solution:
    def smallestUniqueSubarray(self, nums: List[int]) -> int:
        n = len(nums)
        for k in range(1, n+1): # 滑动窗口大小
            r = 0
            cnt = defaultdict(int)
            while r+k <= n:
                subs = tuple(nums[r: r+k])
                cnt[subs] += 1
                r += 1
            if min(cnt.values()) == 1:
                return k
```

惟一的不足:

![image-20261125101149369](image-20261125101149369-1795572714059-1.png)



原因, 这是O(n^3) 的暴力解法,  外层的k, 内层的r, 还有内部的切片, 时间复杂度太高

## 解法二 : 

思路 :

​		如果子数组 A 是唯一的, 那么更长的包含A的子数组也是唯一的. 所以问题变成:

- 给定子数组 的长度length, 判断nums 是否存在长为 length的唯一子数组.
- 首先, nums 肯定是唯一的, 这样就是一个二分问题, 如果length / 2 是唯一的, 接着找, 不然就是length // 2 + 1 到length的长度范围内寻找.
- 核心思路: 计算每个长为length 的子数组的哈希值, 用一个哈希表统计出现次数, 判断是否出现次数为1 的哈希值

滚动哈希 (Rolling Hash)

给个题解的链接, 这个对我来说还是有点困难, 后面再补:

​		[灵茶山艾府 LeetCode 3934 题解](https://leetcode.cn/problems/smallest-unique-subarray/solutions/3969717/on-hou-zhui-shu-zu-by-endlesscheng-la59/?envType=daily-question&envId=2026-11-25)



