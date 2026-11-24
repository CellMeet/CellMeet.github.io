---
title: "LeetCode Hot100 23 : Merge k Sorted Lists (合并k个升序链表)"
date: "2026-11-24T10:06:59+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot100-23-Merge-k-Sorted-Lists-(合并k个升序链表)/"
categories: ["leetcode"]
tags: ["hot100", "最小堆"]
summary: ""
cover:
  image: "cover.png"
  alt: ""
---

# LeetCode Hot100 23 : Merge k Sorted Lists (合并k个升序链表)

题目链接 : [LeetCode Hot100 23 : Merge k Sorted Lists ](https://leetcode.cn/problems/merge-k-sorted-lists/?envType=problem-list-v2&envId=2cktkvj)

## 方法一 : 最小堆

将所有头节点入堆, 最小的将会排在上面, 取出来, 然后将该节点的第二个节点入堆, 接着, 取出一个, 就将新的入堆, 

1. 遍历各个节点, 放进最小堆里面

   ```python
   heap = []
   for i, node in enumerate(lists):
       if node:
           heapq.heappush(heap, (node.val, i, node))
   ```

2. 用一个dummy 节点, 开始保存每个堆的数值

   ```python
   dummy = ListNode(0)
   tail = dummy
   ```

3. 开始遍历, 取出heap 中的头节点, 然后把头节点对应的next节点放进堆里面

   ```python
   while heap:
       val, i, node = heapq.heappop(heap)
       tail.next = node
       tail = tail.next
       if node.next:
           heapq.heappush(heap, (node.next.val, i, node.next)) # 把node.next 放进堆里
   
   return dummy.next
   ```

总的代码如下:

```python
class Solution:
    def mergeKLists(self, Lists: List[ListNode | None]) -> ListNode | None:
        heap = []
        for i, node in enumerate(Lists):
            if node:
            	heapq.heappush(heap, (node.val, i, node))
        
        dummy = ListNode(0)
        tail = dummy
        while heap:
            val, i, node = heapq.heappop(heap)
            tail.next = node
            tail = tail.next
            if node.next:
                heapq.heappush(heap, (node.next.val, i, node.next))
        
        return dummy.next
```



## 方法二 : 分治

​		分治的思想和合并有序链表的思路一致, 先合并两个链表, 然后合并三个链表, 四个链表, 以此类推.

​		
