---
title: "LeetCode 1352 : Product of the Last K Numbers (最后K个数的乘积)"
date: "2026-11-23T08:48:41+08:00"
draft: false
url: "/posts/leetcode/LeetCode-1352-:-Product-of-the-Last-K-Numbers-(最后K个数的乘积/"
categories: ["leetcode"]
tags: ["前缀积"]
summary: ""
cover:
  image: "cover.jpg"
  alt: ""
---

# LeetCode 1352 : Product of the Last K Numbers (最后K个数的乘积)

题目链接 : [LeetCode 1352 : Product of the Last K Numbers](https://leetcode.cn/problems/product-of-the-last-k-numbers/description/?envType=daily-question&envId=2026-11-23)



## 解题思路

​		首先是用一个 list 储存元素, 然后用一个单独的函数计算最后k个数字的乘积, add 是在list 中添加num, 初始化list 为空, ans = 1,代码如下:

```python
def getLastKProduct(nums: list[int], k: int) -> int:
    n = len(nums)
    prod = 1
    for i in range(n-1, n-k-1, -1):
        prod *= nums[i]
    return prod

class ProductOfNumbers:

    def __init__(self):
        self.list = []

    def add(self, num: int) -> None:
        self.list.append(num)

    def getProduct(self, k: int) -> int:
        return getLastKProduct(self.list, k)
```

经测试, 超过时间限制, 有一个例子没有通过:

![image-20261123085238180](image-20261123085238180.png)



我们考虑优化的一个方案, 用另一个数据存储好所有的乘积, 但是这样空间不足, 尝试一下, 这样调用就会直接返回结果, 不会出现超出时间限制的问题.



## 方法二: 前缀积

```python
class ProductOfNumbers:

    def __init__(self):
        self.p = [1]

    def add(self, num: int) -> None:
        if num != 0:
            self.p.append(self.p[-1] * num)
        else:
            self.p = [1]
            
    def getProduct(self, k: int) -> int:
        if len(self.p) <= k:
            return 0
        return self.p[-1] // self.p[-1-k]
```

​		初始化定义前缀积 为`self.p = [1]` , 遇到数字, 加入前缀积, 如果遇到数字 0, 重置 `self.p = [1]` , 表示遇到了 0, 这样最后求结果的时候, 可以根据前缀积的结果, 判断是否处理到0, 最后的长度判断是`if len(self.p) <= k` 等于k说明也遇到了 0, 此时直接返回0, 否则按照正常的前缀积计算即可.
