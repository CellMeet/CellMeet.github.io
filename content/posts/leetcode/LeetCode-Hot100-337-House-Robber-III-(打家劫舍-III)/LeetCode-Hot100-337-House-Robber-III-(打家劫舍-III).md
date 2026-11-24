---
title: "LeetCode Hot100 337 : House Robber III (打家劫舍 III)"
date: "2026-11-24T11:52:09+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot100-337-House-Robber-III-(打家劫舍-III)/"
categories: ["leetcode"]
tags: ["hot100"]
summary: ""
cover:
  image: "cover.png"
  alt: ""
---

# LeetCode Hot100 337 : House Robber III (打家劫舍 III)

## 题目理解 :

很明显的二叉树递归, 采用二叉树进行思考, 考虑最简单的二叉树

- 先找递归边界(base case)

  ```python
  if node is None:
      return 0, 0 # 前后分别是一个节点rob or not_rob 
  ```

- 如果抢劫这个节点, 那么它的左右节点就不能抢劫

  ```python
  # 左右node的返回值
  left_rob, left_not = dfs(node.left)
  right_rob, right_not = dfs(node.right)
  rob = left_not + right_not + node.val
  not_rob = max(left_rob, left_not) + max(right_rob, right_not)
  ```

- 向上返回两个值, 让父节点判断使用rob 还是not_rob

  ```python
  return rob, not_rob
  ```

完整代码:

```python
class Solution:
    def rob(self, root: TreeNode | None) -> int:
        ans = 0
        def dfs(node):
            if not node:
                return 0, 0
            left_rob, left_not = dfs(node.left)
            right_rob, right_not = dfs(node.right)
            rob = left_not + right_not + node.val
            not_rob = max(left_rob, left_not) + max(right_rob, right_not)

            return rob, not_rob
        
        return max(dfs(root))
```



