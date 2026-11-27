---
title: "LeetCode 3946: Maximum Number of Items From Sale I (购买最多物品数目)"
date: "2026-11-27T08:18:55+08:00"
draft: false
url: "/posts/leetcode/LeetCode-3946-Maximum-Number-of-Items-From-Sale-I-(购买最多物品数目)/"
categories: ["leetcode"]
tags: ["leetcode", "贪心", "0-1背包"]
summary: ""
cover:
  image: "cover.jpg"
  alt: ""
---

# LeetCode 3946: Maximum Number of Items From Sale I (购买最多物品数目)



## 题目理解

input:

```py
items = [[6, 2], [2, 6], [3, 4]]
budget = 9
```

输入有items: 

`items[i] = [factor[i], price[i]]`

item 数组的前者是factor, 后者是price, budge是你的预算, 

在购买一个item 之后, 你可以获得一个free 的copy, 规则如下:

- 任何一个物品`i`, 如果你买了至少一个, 会赠送你一个item`j`, 同时`j !=i` and `factor[i]` divides(除以) `factor[j]`
- 只给一个, 购买多个`i` 不会赠送从`i` 得到的free的`j`
- 如果是不同的item 得到的`j`, 那么`j` 可以有多个.(比如, 2 可以被4 和 6的整除, 那么你可以得到两份`j`)(分别是4 和 6 的, 2 drivides 4/6)

output:

输出你能获得的最多的物品的数量.

### Example 1

用上面的数组举例, 你有预算 9, 可以购买 2 个item[0] 和一个item[2], 花费`2*2 + 4 = 8` , 小于budget, 但是购买 item[2] 可以得到一个copied item[0] (因为 3 divides 6), 所以一共得到 `2 + 1 + free(1) = 4` 份.



## 解题思路

我们可以认为每个物品有一个除了自身价格外的 "额外购买力":

用Example 举例:
```python
items = [[2, 4], [3, 2], [4, 1], [6, 4], [12, 4]]
budget = 8
```

在第一轮购买中, item[0] 的price 是 4, 看起来比较贵, 但是它可以赠送:

`item[2], item[3], item[4]` , 所以它的第一轮"单价"其实是 `1`

同理得到item[1], item[2] ... 的单价依次为:

`0.67`, `0.5`, `2`, `4`, 

所以我们可以根据**"第一轮单价"** 和 **"单价"** 进行排序:

`0.5(*), 0.67(*), 1, 2, 4, 1, 2, 4, `

作为购买的标准(其中带(*) 的是第一轮单价)

然后进行buget进行购买, 得到:

`1 (2) + 2(3) + budget(left) - 1= 2 + 3 + (8-1-2) = 10`

  其中前者是 单价, 后者是 购买得到的item 数目.



## 结合背包问题:

我们可以这样思考, 本质使用一个 大小为`budget` 的背包, 装`weigh: pirce, value: cnt` 的物品, 而且是`0-1背包`  问题, 我们先考虑, 这种背包问题的实现

```python
f = [0] * (budget + 1)
for _, price in items:
    for j in range(budget, price-1, -1):
        f[j] = max(f[j], f[j-price] +cnt)
```

得到 `f[j]` , 即 第一轮花费 `i` 得到的tiem 数量`f[j]` 后, 再次遍历, 取最大值(之前存储了`min_price`, 此时把`min_price` 考虑进来)

```python
return max(fi + (budget - i) // min_pirce for i, fi in enumerate(f))
```

因此思路为:

- 拆分为**背包问题**
- 考虑**最小的价格**, 进行进一步优化.



## 代码

```python
class Solution:
    def maximumSaleItems(self, items: List[List[int]], budget: int) -> int:
        f = [0] * (budget + 1)
        min_price = inf

        for factor, price in items:
            min_price = min(min_price, price) # 记录最小的price
            # 计算item 的cnt
            cnt = 0
            for factor_j, _ in items:
                if factor_j % factor == 0:
                    cnt += 1
            
            # 用w = price, v = cnt转换为背包问题
            for j in range(budget, price-1, -1):
                f[j] = max(f[j], f[j-price] + cnt)
        # 考虑 min_price, 其中fi 是当前的数量 fi + (budget - i) // min_price
        return max(fi + (budget - i) // min_price for i, fi in enumerate(f))
```

一道结合贪心 + 背包的问题, 终于解决了. 
