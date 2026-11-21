---
title: "LeetCode 3331: Find Subtree Sizes After Changes"
date: "2026-11-21T09:24:09+08:00"
draft: false
url: "/posts/leetcode/LeetCode-3331:-Find-Subtree-Sizes-After-Changes/"
categories: ["leetcode"]
tags: ["dfs"]
summary: "leetcode 3331 题题解"
cover:
  image: "leetcode.webp"
  alt: "力扣封面"
---

​		

题目理解：将节点指向它最近的同样形式的节点，s[a] == s[b], 那么将节点指向它最近b, 而不是原来的父节点（这一修改同时发生）。



​		核心思路： 两次DFS,  首先写一个自顶向下的DFS, 同时维护路径上的每个字母对应的最深节点ancestor, 初始化成一个全为 -1 的数组，递归到节点x 时， 更新 ancestor[s[x]] = x

​		遇到x和子节点y的时候, 如果ancestor[s[y]] ≠ -1 , 那么就把y 加到ancestor[s[y]] 的子节点列表中, 同时把x 和儿子y 改成 -1, 在第二次DFS 中, 不去递归等于-1 的儿子.

​		题解思路: 

1. 首先, 需要建立一个graph, 保存现在的节点和它们的子节点, 方便我们进行遍历

2. 有一个数组ancestor, 保存每个单词第一次出现的位置

3. 进行第一次dfs, dfs(x: int) 表示进入x进行dfs,  

   1. old 保存之前的s[x] 的ancestor, 然后把ancestor[s[x]] = x, 更新自己为当前ancestor[s[x]]  的最新出现的位置, 在这个"小区域"内进行修改

   2. 遍历 x 的子节点 y :

      ```python
      for i in range(len(g[x])):
          y = g[x][i]
      ```

      

      如果 y 对应的单词的ancestor 不是 -1, 那么就修改其对应的ancestor, 并把 x 对应 y 原本的位置定义为 -1, 代码如下

      ``` python
      	if(ans := ancestor[s[y]]) != -1:
              g[ans].append(y)
              g[x][i] = -1  # 标记原本的g[x][i] 节点为 -1
      ```

      

      完成之后, 进入子节点 y 的区域进行进一步 "search":

      ```python
      	rebuild(y)
      ```

      

      最后, 恢复现场, 避免 对 x 的兄弟节点产生影响:

      ```python
      ancestor[s[x]] = old
      ```

4. 进行第二次dfs, 将size 进行累加, 得到size的数组, dfs代码如下:

   ```python
   size = [1] * n  # 初始化为1
   def dfs(x: int):
       for y in g[x]:
           if y != -1:
           	dfs(y)  # 搜索y的区域
               size[x] += size[y] # 对y进行累加
   ```

看懂之后, 整个题目就没有 那么难.完整的python 代码入下:

```python
n = len(parent)
g = [[] for _ in range(n)]
for i in range(1, n):   # 0 默认 -1
    g[parent[i]].append(i)
   
ancestor = defaultdict(lambda: -1)

def rebuild(x: int) -> None
	old = ancestor[s[x]]
    ancestor[s[x]] = x
    for i in range(len(g[x])):
        y = g[x][i]
        if(anc := ancestor[s[y]]) != -1:
            g[anc].append(y)
            g[x][i] = -1
        rebuild(y)
    ancestor[s[x]] = old

rebuild(0)  # 执行一次    

size = [1] * n
def dfs(x: int):
    for y in g[x]:
        if y != -1:
            dfs(y)
            size[x] += size[y]

dfs(0)  # 执行一次
return size
```

