---
title: "LeetCode 3411 : Maximum Subarray With Equal Prodects (最长乘积等价子数组)"
date: "2026-11-24T08:22:19+08:00"
draft: false
url: "/posts/leetcode/LeetCode-3411-Maximum-Subarray-With-Equal-Prodects-(最长乘积等价子数组)/"
categories: ["leetcode"]
tags: []
summary: ""
cover:
  image: "cover.jpg"
  alt: ""
---

# LeetCode 3411 : Maximum Subarray With Equal Prodects 

题目链接 : [LeetCode 3411 : Maximum Subarray With Equal Prodects ](https://leetcode.cn/problems/maximum-subarray-with-equal-products/description/?envType=daily-question&envId=2026-11-24)



## 方法一 : 暴力

- 确定内外循环 i, j , 对乘积和lcm, gcd 进行初始化

  ```python
  m, l, g = 1, 1, 0
  ```

  

- 子数组乘积

  ```python
  x = nums[j]
  m *= x
  ```

- 子数组lcm, 此处lcm 的最大值是lcm(*nums)

  ```python
  l = lcm(l, x)
  ```

- 子数组gcd, 此处gcd 的最大值是max(numx)

  ```python
  g = gcd(g, x)
  ```

- 由于子数组m 的乘积可能溢出, 这里加上范围判断

  ```python
  max_m = lcm(*nums) * max(nums) # max(nums)就是gcd(*nums)
  if m > max_m:
      break
  ```

代码总的如下:

```pyton
class Solution:
    def maxLength(self, nums: List[int]) -> int:
        max_m = lcm(*nums) * max(nums)
        ans = 0
        for i in range(len(nums)):
            m, l, g = 1, 1, 0
            for j in range(i, len(nums)):
                x = nums[j]
                m *= x
                l = lcm(l, x)
                g = gcd(g, x)
                if m == l * g:
                    ans = max(ans, j-i+1)
                if m > max_m:
                    break
        return ans
```

注:

​		作者: 灵茶山艾府
