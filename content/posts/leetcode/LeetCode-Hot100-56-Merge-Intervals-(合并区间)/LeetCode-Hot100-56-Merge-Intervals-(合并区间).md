---
title: "LeetCode Hot100 56 : Merge Intervals (合并区间)"
date: "2026-11-24T16:56:43+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot100-56-Merge-Intervals-(合并区间)/"
categories: ["leetcode"]
tags: []
summary: ""
cover:
  image: "cover.png"
  alt: ""
---

# LeetCode Hot100 56 : Merge Intervals (合并区间)

题目链接 : [LeetCode Hot100 56 : Merge Intervals](https://leetcode.cn/problems/merge-intervals/?envType=problem-list-v2&envId=2cktkvj)

## 题目理解

- 首先, 肯定可以对interval 中按照区间的第一个元素进行升序排序

  ```python
  intervals.sort(key = lambda x: x[0]) # 注意写排序的key
  ```

  这样, 可以完成根据intervals 对第一个字母进行排序

- 接着, 可以进行合并, 主要比较下一个的first 和里面的end 的数值大小

  ```python
  stack = [] # 用栈来存放结果
  for start, end in intervals:
      if stack and start <= stack[-1][1]:
          stack[-1][1] = max(stack[-1][1], end)
      else:
          stack.append([start, end])
  return stack
  ```

总的代码就是两者的合并, 就不写了.
