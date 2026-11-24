---
title: "LeetCode Hot100 75 : Sort Colors (颜色分类)"
date: "2026-11-24T17:28:38+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot100-75-Sort-Colors-(颜色分类)/"
categories: ["leetcode"]
tags: ["hot100", "三指针"]
summary: ""
cover:
  image: "cover.png"
  alt: ""
---

# LeetCode Hot100 75 : Sort Colors (颜色分类)

题目链接 : [LeetCode Hot100 75 : Sort Colors](https://leetcode.cn/problems/sort-colors/?envType=problem-list-v2&envId=2cktkvj)

## 解题思路

​		左右两个指针, 分别是left, 和 right. 一个指针从起点移动, 遇到0 就和left下方数字交换位置, 然后left 右移, 遇到2就和right交换数字, 然后right 左移.

​		这里的一个问题是, 交换过来的数字, 如果是和2交换过来0, 那么不能立刻右移 mid, 而是和left 交换之后, 再右移, 思路如下:

```python
class Solution(object):
    def sortColors(self, nums):
        left, mid = 0, 0
        right = len(nums) - 1
        while mid <= right:
            x = nums[mid]
            if x == 0:
                nums[left], nums[mid] = nums[mid], nums[left]
                left += 1
                mid += 1
            elif x == 2:
                nums[mid], nums[right] = nums[right], nums[mid]
                right -= 1
            else:
                mid += 1
```

​		解决, over! 
