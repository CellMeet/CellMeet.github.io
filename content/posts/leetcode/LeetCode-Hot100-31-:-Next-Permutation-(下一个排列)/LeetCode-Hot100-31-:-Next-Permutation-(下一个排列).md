---
title: "LeetCode Hot100 31 : Next Permutation (下一个排列)"
date: "2026-11-23T12:04:09+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot100-31-:-Next-Permutation-(下一个排列)/"
categories: ["leetcode"]
tags: ["双指针"]
summary: ""
cover:
  image: "cover.png"
  alt: ""
---

# LeetCode 31 : Next Permutaiton (下一个排列)

 题目链接 : [LeetCode 31 : Next Permutaiton](https://leetcode.cn/problems/next-permutation/description/?envType=problem-list-v2&envId=2cktkvj)

## 题目理解

​		下一个排列的精髓是找到一个"山峰", 以 [2, 3, 1]为例, 我们需要找到在 2 的右边第一个大于 2 的数字(此处是3),然后交换它们的位置 , 然后把原本2 右边的子数组按照升序排列, 这就是这个题目的下一个排列

思路为:

- 从右向左, 找到第一个"下降点", 标记为i

  ```python
  n = len(nums)
  i = n-2
  while i >= 0 and nums[i] >= nums[i+1]: 
  ```

  

- 从右向左, 找到第一个大于"下降点"的数字, 标记为j

  ```python
  for j in range(n, i, -1):
      if nums[j] > nums[i]:
          break
  ```

  

- 交换 arr[i], arr[j]

  ```python
  nums[i], nums[j] = nums[j], nums[i]
  ```

  

- 把原本i右边的数组完全倒序, (此处可以采用双指针交换位置的方式), 

  ```python
  left, right = i+1, n-1
  while left < right:
      nums[left], nums[right] = nums[right], nums[left]
      left += 1
      right -= 1
  ```



总的代码如下:

```python
class Solution:
    def nextPermutation(self, nums: list[int]) -> None:
        n = len(nums)
        i = n-2
        while i >= 0 and nums[i] >= nums[i+1]: 
            i -= 1
        if i >= 0:
            j = n-1
            while nums[j] <= nums[i]:
                j -= 1
            nums[i], nums[j] = nums[j], nums[i]
        
        left, right = i+1, n-1
        while left < right:
            nums[left], nums[right] = nums[right], nums[left]
            left += 1
            right -= 1
```

