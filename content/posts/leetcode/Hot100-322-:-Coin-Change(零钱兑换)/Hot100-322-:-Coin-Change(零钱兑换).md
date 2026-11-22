---
title: "LeetCode Hot100 322 : Coin Change(零钱兑换)"
date: "2026-11-22T09:14:46+08:00"
draft: false
url: "/posts/leetcode/Hot100-322-:-Coin-Change(零钱兑换)/"
categories: ["leetcode"]
tags: ["bfs", "完全背包"]
summary: ""
cover:
  image: "cover.png"
  alt: "hot100 封面"
---

# Hot 100 : 322. Coin Change

典型的背包问题， 用Example 1来解释：

Input：

```python
coins = [1, 2, 5]
amount = 11
```

Output：3

Explanation：11  =  5  + 5 + 1



## 方法一 ： 完全背包



完全背包问题的思路是：

​		我们从小到大扩充背包，定义`dp[i]`  来表示 达到数目 `i`  需要的最小货币

遍历不同的 coin 这样 dp 的转移规则就是：

`dp = min(dp[i], dp[i - coin] + 1)`

​		比如说，我现在 amout = 11 ，需要定义一个数组，表示 0～11 需要多少个硬币

````python
dp = [amount+1] * (amount+1) # 这里定义初始值为 amount+1 ，是为了初始化一个“不可能”的情况避免后面min比较出错
# 定义 amount+1 个，是从 0 - amount 个数值
dp[0] = 0 
````

​		 然后判断， if coin < i:

​		这样的话：

```python
for i in range(coin, amount+1):
    dp[i] = min(dp[i], dp[i-coin] + 1)
```

从 coin[0] 开始，这样， dp[1] = dp[0] + 1 =  1, dp[2] = dp[1] + 1 = 2 ... 这样直到 11, 完成第一轮初始化， dp[11]  = dp[10] + 1 = 11



coin[0] 结束后，开始coin[1], 即 2, 再次寻找最小的数值：

dp[2] = dp[0] + 1 = 1, 小于之前的 2, 更新

同理， coin[1] 结束后， coin[2] 继续更新，最后的代码就是：

```python
class Solution:
    def coinChange(self, coins: list[int], amount: int) -> int:
        dp = [amount+1] * (amount+1)
        dp[0] = 0
        for coin in coins:
            for i in range(coin, amount+1):
                dp[i] = min(dp[i], dp[i-coin] + 1)
        
        return dp[amount] if dp[amount] < amount+1 else -1
```



## 方法二 ：bfs



​		使用广度优先搜索，假设当前金额是 _s_ ,  添加一枚硬币后，金额变成 s + coin[i] .  用Example 1 举例:

​		起初金额为 0, 第一轮 bfs , 得到 1 , 2, 5 三个节点, 然后对 一层的三个节点再次进行 bfs , 得到 2, 3, 6 | 3, 4, 7 | 6, 7, 10  这是第三层的 9 个节点, 此时 1, 2, 5 结束,还是没有找到 11, 此时都还小于 11, 继续, 直到 第三层 出现 10 + 1 = 11, 得到结果, 直到所有的数值 都 大于11 还没找到, 返回 -1.



​		我们需要一个队列来保存每一层中的节点:

```python
q = queue([0]) # 第一层, 金额为 0
```

​		同时, 要判断 0 - amount 的数字是否已经访问, 避免重复访问, 比如 1 + 2  得到 3 了, 那么 1 + 1 + 1 得到的 3就可以直接跳过

```python
visited = [False] * (amount+1)
```

​		用step 记录当前的层数(也就是最小硬币数)

```python
step = 0
```



​		添加条件 和 终止条件: 

- if cur + coin  得到的 nxt < amount , 可以添加到 q 
- if nxt == amount, 直接 return step
- 当所有的 nxt  都 大于 amount, 此时 没有添加 的 q ,  与此同时, q "用光了", 此时还没有答案, 说明无解, 最后 return -1

​		bfs 代码如下:

```python
class Solution(Object):
    def coinChange(self, coins, amount):
        if amount == 0:
            return 0
       	
        q = deque([0])
        visited = [False] * (amount + 1)
        step = 0
        
        while q:
            step += 1
            for _ in range(len(q)):
                cur = q.popleft()
                for coin in coins:
                    nxt = cur + coin
                    if nxt == amount:
                        return step
                	
                    if nxt < amount and not visited[nxt]:
                        a.append(nxt)
                        visited[nxt] = True
                        
       return -1
                
```

