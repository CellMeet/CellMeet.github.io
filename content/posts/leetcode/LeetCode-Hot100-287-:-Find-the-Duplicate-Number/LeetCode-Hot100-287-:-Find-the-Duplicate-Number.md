---
title: "LeetCode Hot100 287 : Find the Duplicate Number (寻找重复数)"
date: "2026-11-22T11:10:02+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot100-287-:-Find-the-Duplicate-Number/"
categories: ["leetcode"]
tags: ["binary search"]
summary: ""
cover:
  image: "cover.png"
  alt: ""
---

#  Hot 100  287 : Find the Duplicate Number (寻找重复数)

题目链接 : [LeetCode  287 : Find the Duplicate Number](https://leetcode.cn/problems/find-the-duplicate-number/description/?envType=problem-list-v2&envId=2cktkvj)

## 方法一: 暴力搜索

​		python 中使用 Counter 计数器 统一大于 1 的数字, 然后遍历, if counter[num] > 1, return num

```python
class Solution:
    def findDuplicate(self, nums: List[int]) -> int:
        count = Counter(nums)
        for num in nums:
            if count[num] >= 2:
                return num
```

​		简单粗暴,就是有点蠢



## 方法二:  二分查找

​		如果在[1, n] 中存在一个重复数字 x , (一共有 n+1 个数字), 那么从 1 -> x , 的数字会多出来1, 从 x+1 -> n 的数字数目不变, 还是 n - (x+1) +1 个, 所以可以 二分搜索, 查找区间中数字的数目, 如果多了 一, 那么 x 就在这个区间里, 继续搜索, 直到找出来 x .

​		核心思路是寻找 [1, n] 之间的重复的数字, 计算 nums 中 num <= x 的数目, 如果 x  在[1, mid] 范围内, 那么count 会大于 mid, 此时 收缩右边界. 这个时候用一个极端情况来说明.  这个题目只有一个重复数字, 如果 right = mid - 1, 排除掉重复数字, 接着 不断收缩剩下的区间, 最后 left 会不断右移, 直到 最后 left + 1 得到 我们排除掉的重复数字(即答案), 所以总是能找到答案的, 二分查找把条件给说清楚, 本质是一个 " 排除区间查找 ", 就是 左区间只要满足没有 x, 就向右移动, 最后移动完了, 就是x. 

代码如下:

​		首先是闭区间:

```python
class Solution:
    def findDuplicate(self, nums: List[int]) -> int:
        left, right = 1, len(nums) - 1
        while left <= right:
            mid = (left + right) // 2
            count = sum(1 for num in nums if num <= mid)
            if count > mid:
                right = mid - 1
            else:
                left = mid + 1
       	
        return left
```

​		然后是左闭右开区间:

```python
class Solution:
    def findDuplicate(self, nums: List[int]) -> int:
        left, right = 1, len(nums)
        while left < right:
            mid = (left + right) // 2
            count = sum(1 for num in nums if num <= mid)
            if count > mid:
                right = mid
            else:
                left = mid + 1
     
    	return left 
```

​		最后是左开右开区间:

```python
class Solution:
    def findDuplicate(self, nums: List[int]) -> int:
        left, right = 0, len(nums)
        while left + 1 < right:
            mid = left + (right - left) // 2
            count = sum(1 for num in nums if num <= mid)
            if count > mid:
                right = mid
            else:
                left = mid
        
        return right
```

​		

​		灵茶山艾府真好用啊!



相关题目:

# LeetCode 34 : Find First and Last Position of Element in Sorted Array

题目链接 : [LeetCode : 34. Find First and Last Position of Element in Sorted Array](https://leetcode.cn/problems/find-first-and-last-position-of-element-in-sorted-array/description/?envType=problem-list-v2&envId=2cktkvj)



Python:

```python
def lower_bound(nums: List[int], target: int):
    left, right = -1, len(nums)
    while left + 1 < right:
        mid = left + (right - left) // 2
        if nums[mid] < target:
            left = mid
        else:
            right = mid
    return right

class Solution:
    def searchRange(self, nums: list[int], target: int) -> list[int]:
        start = lower_bound(nums, target)
        if start == len(nums) or nums[start] != target:
            return [-1, -1]
       	end = lower_bound(nums, target + 1) -1
        return [start, end]
```



Golang 版本的:

```go
func lowerBound(nums []int, target int) int {
    left, right := -1, len(nums)
    for left + 1 < right{
        mid := left + (right - left) / 2
        if nums[mid] >= target{
            right = mid
        } else {
            left = mid
        }
    }
    return right
}

func searchRange(nums []int, target int) []int {
    start := lowerBound(nums, target)
    if start == len(nums) || nums[start] != target{
        return []int{-1, -1}
    }
    end := lowerBound(nums, target + 1) - 1
    return []int{start, end}
}
```



再来一道二分查找:

# LeetCode 240 : Search a 2D Matrix II

题目链接 : [LeetCode 240 : Search a 2D Matrix II

](https://leetcode.cn/problems/search-a-2d-matrix-ii/description/?envType=problem-list-v2&envId=2cktkvj)

每一行进行二分查找, 代码如下:

```python
def lower_bound(nums: List[int], target):
    left, right = -1, len(nums)
    while left + 1 < right:
        mid = (left + right) // 2
        if nums[mid] < target:
            left = mid
        else:
            right = mid
    return right


class Solution:
    def searchMatrix(self, matrix: List[List[int]], target: int) -> bool:
        for row in matrix:
            if row[0] > target:
                break
            tmp = lower_bound(row, target)
            if tmp == len(row) or row[tmp] != target: 
                continue
            return True

        return False
```

​		我爱二分查找, 好耶!

